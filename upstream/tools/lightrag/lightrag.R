library(httr2)
library(jsonlite)

#' 触发文档扫描并轮询监控状态
#'
#' @param base_url LightRAG API 服务基础地址
#' @param api_key 可选的 API Key / Token
#' @param poll_interval 轮询间隔时间（秒）
#' @param max_wait_time 最大等待总时间（秒）
run_and_monitor_scan <- function(base_url = "http://127.0.0.1:9621",
                                 api_key = NULL,
                                 poll_interval = 3,
                                 max_wait_time = 600) {
  
  clean_base_url <- sub("/+$", "", base_url)
  
  # 辅助函数：根据是否有 api_key 统一配置请求头
  apply_auth <- function(req) {
    if (!is.null(api_key) && nzchar(api_key)) {
      req <- req |> req_headers("Authorization" = paste("Bearer", api_key))
    }
    return(req)
  }
  
  # ==========================================
  # Step 1: 发起扫描请求 (POST /documents/scan)
  # ==========================================
  scan_endpoint <- paste0(clean_base_url, "/documents/scan")
  message(">>> [1/2] 正在触发文档扫描: ", scan_endpoint)
  
  scan_resp <- tryCatch({
    req <- request(scan_endpoint) |>
      req_method("POST") |>
      apply_auth() |>
      req_timeout(30)
    
    req_perform(req)
  }, error = function(e) {
    stop("触发扫描请求失败: ", e$message)
  })
  
  status_code <- resp_status(scan_resp)
  body <- resp_body_json(scan_resp)
  
  if (status_code != 200) {
    stop(sprintf("触发扫描失败 [HTTP %d]: %s", status_code, resp_body_string(scan_resp)))
  }
  
  track_id <- body$track_id
  scan_status <- body$status
  
  message(sprintf("    响应状态: %s", scan_status))
  message(sprintf("    返回消息: %s", body$message))
  
  # 检查是否因为管道繁忙被跳过
  if (identical(scan_status, "scanning_skipped_pipeline_busy")) {
    warning("LightRAG 管道正忙或已有任务正在运行，本次扫描未执行。")
    return(body)
  }
  
  if (is.null(track_id) || !nzchar(track_id)) {
    stop("响应中未获取到有效的 track_id，无法追踪状态。")
  }
  
  message(sprintf("    已获取任务 ID: %s", track_id))
  
  # ========================================================
  # Step 2: 轮询监控状态 (GET /documents/scan/status/{track_id})
  # ========================================================
  status_endpoint <- paste0(clean_base_url, "/documents/scan/status/", track_id)
  message("\n>>> [2/2] 开始监控任务状态...")
  
  start_time <- Sys.time()
  
  repeat {
    elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    if (elapsed_time > max_wait_time) {
      warning(sprintf("任务监控超时 (超过 %d 秒)，任务可能仍在后台运行。", max_wait_time))
      break
    }
    
    # 查询当前状态
    query_resp <- tryCatch({
      req <- request(status_endpoint) |>
        req_method("GET") |>
        apply_auth() |>
        req_timeout(20)
      
      req_perform(req)
    }, error = function(e) {
      warning("查询状态时出现网络抖动: ", e$message)
      NULL
    })
    
    if (!is.null(query_resp)) {
      q_status_code <- resp_status(query_resp)
      
      if (q_status_code == 200) {
        job_info <- resp_body_json(query_resp)
        current_job_status <- job_info$status %||% "unknown"
        
        message(sprintf("[%s] 耗时: %ds | 当前状态: %s", 
                        format(Sys.time(), "%H:%M:%S"), 
                        round(elapsed_time), 
                        current_job_status))
        
        # 判断是否到达终态 (如 completed, failed, success, abandoned 等)
        terminal_states <- c("completed", "success", "failed", "abandoned", "error", "finished")
        if (tolower(current_job_status) %in% terminal_states) {
          message("\n=== 任务处理结束 ===")
          print(job_info)
          return(job_info)
        }
      } else if (q_status_code == 404) {
        warning("任务记录不存在或已被系统清理 (404)。")
        break
      } else {
        message(sprintf("查询异常 [HTTP %d]", q_status_code))
      }
    }
    
    # 等待下一次轮询
    Sys.sleep(poll_interval)
  }
}

run_and_monitor_scan()

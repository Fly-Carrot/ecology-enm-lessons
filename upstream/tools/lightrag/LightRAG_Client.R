# ==============================================================================
# LightRAG API Client for R (Data.Table Native)
# 依赖库: httr, jsonlite, data.table, curl
# ==============================================================================

if (!requireNamespace("httr", quietly = TRUE)) install.packages("httr")
if (!requireNamespace("jsonlite", quietly = TRUE)) install.packages("jsonlite")
if (!requireNamespace("data.table", quietly = TRUE)) install.packages("data.table")

library(httr)
library(jsonlite)
library(data.table)

#' 1. 创建 LightRAG 客户端对象
#' 
#' @param base_url 服务器地址，默认 "http://localhost:9621"
#' @param api_key API 密钥 (X-API-Key / Header 验证)
#' @param token Bearer Token (JWT 认证)
#' @param show_status 全局默认是否打印服务器状态与响应详情
#' @return 返回 LightRAG 客户端环境对象
lr_client <- function(base_url = "http://localhost:9621",
                      api_key = NULL,
                      token = NULL,
                      show_status = TRUE) {
  env <- new.env(parent = emptyenv())
  env$base_url <- sub("/+$", "", base_url)
  env$api_key <- api_key
  env$token <- token
  env$show_status <- show_status
  class(env) <- c("LightRAGClient", "environment")
  return(env)
}

#' 核心底层 HTTP 请求派发函数
lr_request <- function(client,
                       method = c("GET", "POST", "DELETE"),
                       endpoint,
                       query = list(),
                       body = NULL,
                       encode = c("json", "form", "multipart", "raw"),
                       show_status = client$show_status) {
  method <- match.arg(method)
  encode <- match.arg(encode)
  
  url <- paste0(client$base_url, endpoint)
  
  # 构建请求头
  headers <- c("Accept" = "application/json")
  if (!is.null(client$api_key) && nzchar(client$api_key)) {
    headers["X-API-Key"] <- client$api_key
    query$api_key_header_value <- client$api_key
  }
  if (!is.null(client$token) && nzchar(client$token)) {
    headers["Authorization"] <- paste("Bearer", client$token)
  }
  
  # 清理空的查询参数
  query <- query[!vapply(query, is.null, logical(1))]
  
  # 计时与请求发送
  t_start <- Sys.time()
  res <- tryCatch({
    switch(
      method,
      GET = httr::GET(url, query = query, httr::add_headers(.headers = headers)),
      POST = {
        if (encode == "multipart") {
          httr::POST(url, query = query, body = body, encode = "multipart", httr::add_headers(.headers = headers))
        } else if (encode == "form") {
          httr::POST(url, query = query, body = body, encode = "form", httr::add_headers(.headers = headers))
        } else {
          httr::POST(url, query = query, body = body, encode = "json", httr::add_headers(.headers = headers))
        }
      },
      DELETE = {
        if (!is.null(body)) {
          httr::DELETE(url, query = query, body = body, encode = "json", httr::add_headers(.headers = headers))
        } else {
          httr::DELETE(url, query = query, httr::add_headers(.headers = headers))
        }
      }
    )
  }, error = function(e) {
    stop(sprintf("[LightRAG Error] 连接服务器失败 (%s): %s", url, e$message))
  })
  t_end <- Sys.time()
  latency_ms <- round(as.numeric(difftime(t_end, t_start, units = "secs")) * 1000, 2)
  
  status_code <- httr::status_code(res)
  
  # 状态回显控制
  if (isTRUE(show_status)) {
    cat(sprintf("\n┌── [LightRAG Server Status] %s\n", Sys.time()))
    cat(sprintf("│ URL Endpoint : [%s] %s\n", method, endpoint))
    cat(sprintf("│ HTTP Status  : %d %s (耗时: %1.1f ms)\n", 
                status_code, httr::http_status(res)$reason, latency_ms))
    if (!is.null(httr::headers(res)$`server`)) {
      cat(sprintf("│ Server       : %s\n", httr::headers(res)$`server`))
    }
    cat("└─────────────────────────────────────────────\n")
  }
  
  # 错误捕获处理
  content_text <- httr::content(res, as = "text", encoding = "UTF-8")
  parsed_data <- if (nzchar(content_text)) {
    tryCatch(jsonlite::fromJSON(content_text, simplifyVector = FALSE), error = function(e) content_text)
  } else {
    list()
  }
  
  if (status_code >= 400) {
    err_msg <- if (is.list(parsed_data) && !is.null(parsed_data$detail)) {
      jsonlite::toJSON(parsed_data$detail, auto_unbox = TRUE)
    } else {
      content_text
    }
    warning(sprintf("[HTTP %d] 请求执行异常: %s", status_code, err_msg))
  }
  
  return(parsed_data)
}

# ==============================================================================
# 2. 系统、认证与健康监测接口 (System, Auth & Health)
# ==============================================================================

#' 2.1 检查系统健康度与运行配置
lr_health <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/health", show_status = show_status)
  if (is.list(res)) {
    dt <- as.data.table(res[c("status", "webui_available", "api_docs_available", 
                              "working_directory", "input_directory", "auth_mode", 
                              "pipeline_busy", "core_version", "api_version")])
    return(dt)
  }
  return(res)
}

#' 2.2 验证客户端认证凭据
lr_auth_verify <- function(client, show_status = client$show_status) {
  lr_request(client, "GET", "/auth/verify", show_status = show_status)
}

#' 2.3 获取认证状态或访客 Token
lr_auth_status <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/auth-status", show_status = show_status)
  return(as.data.table(res))
}

#' 2.4 OAuth2 登录换取 Token
lr_login <- function(client, username, password, grant_type = "password", 
                     scope = "", client_id = NULL, client_secret = NULL, 
                     show_status = client$show_status) {
  body <- list(
    grant_type = grant_type,
    username = username,
    password = password,
    scope = scope,
    client_id = client_id,
    client_secret = client_secret
  )
  res <- lr_request(client, "POST", "/login", body = body, encode = "form", show_status = show_status)
  if (!is.null(res$access_token)) {
    client$token <- res$access_token
    message(">> 登录成功，Token 已自动绑定至客户端对象。")
  }
  return(as.data.table(res))
}

#' 2.5 根路径重定向 (UI)
lr_redirect_ui <- function(client, show_status = client$show_status) {
  lr_request(client, "GET", "/", show_status = show_status)
}

#' 2.6 获取 UI 自定义配置
lr_ui_customization <- function(client, locale = "", show_status = client$show_status) {
  res <- lr_request(client, "GET", "/ui/customization", query = list(locale = locale), show_status = show_status)
  return(res)
}

#' 2.7 获取 UI 自定义静态资源
lr_ui_asset <- function(client, asset_hash, asset_id, show_status = client$show_status) {
  endpoint <- sprintf("/ui/customization/assets/%s/%s", asset_hash, asset_id)
  lr_request(client, "GET", endpoint, show_status = show_status)
}

# ==============================================================================
# 3. 文档管理与解析写入接口 (Documents Management & Ingestion)
# ==============================================================================

#' 3.1 触发输入目录新文档扫描
lr_documents_scan <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "POST", "/documents/scan", show_status = show_status)
  return(as.data.table(res))
}

#' 3.2 获取扫描任务进度状态
lr_documents_scan_status <- function(client, track_id, show_status = client$show_status) {
  endpoint <- sprintf("/documents/scan/status/%s", track_id)
  res <- lr_request(client, "GET", endpoint, show_status = show_status)
  return(res)
}

#' 3.3 列出文档源冲突 (Source Conflicts)
lr_documents_source_conflicts <- function(client, limit = 50, cursor = NULL, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/documents/source_conflicts", 
                    query = list(limit = limit, cursor = cursor), show_status = show_status)
  dt_conflicts <- if (length(res$conflicts) > 0) rbindlist(lapply(res$conflicts, as.data.table), fill = TRUE) else data.table()
  return(list(conflicts = dt_conflicts, next_cursor = res$next_cursor))
}

#' 3.4 修复文档源冲突 (Repair Conflict)
lr_documents_repair_conflict <- function(client, canonical_source_key, primary_doc_id, 
                                         expected_candidate_count = NULL, 
                                         expected_candidate_fingerprint = NULL, 
                                         dry_run = TRUE, show_status = client$show_status) {
  body <- list(
    canonical_source_key = canonical_source_key,
    primary_doc_id = primary_doc_id,
    expected_candidate_count = expected_candidate_count,
    expected_candidate_fingerprint = expected_candidate_fingerprint,
    dry_run = dry_run
  )
  res <- lr_request(client, "POST", "/documents/source_conflicts/repair", body = body, show_status = show_status)
  return(as.data.table(res))
}

#' 3.5 上传单个本地文件至系统
lr_documents_upload <- function(client, file_path, show_status = client$show_status) {
  if (!file.exists(file_path)) stop("上传文件不存在: ", file_path)
  body <- list(file = httr::upload_file(file_path))
  res <- lr_request(client, "POST", "/documents/upload", body = body, encode = "multipart", show_status = show_status)
  return(as.data.table(res))
}

#' 3.6 插入单段文本
lr_documents_insert_text <- function(client, text, file_source = NULL, chunking = NULL, show_status = client$show_status) {
  body <- list(text = text, file_source = file_source, chunking = chunking)
  body <- body[!vapply(body, is.null, logical(1))]
  res <- lr_request(client, "POST", "/documents/text", body = body, show_status = show_status)
  return(as.data.table(res))
}

#' 3.7 批量插入多段文本
lr_documents_insert_texts <- function(client, texts, file_sources = NULL, chunking = NULL, show_status = client$show_status) {
  body <- list(texts = as.list(texts), file_sources = file_sources, chunking = chunking)
  body <- body[!vapply(body, is.null, logical(1))]
  res <- lr_request(client, "POST", "/documents/texts", body = body, show_status = show_status)
  return(as.data.table(res))
}

#' 3.8 清空系统中所有文档与图谱存储 (危险操作)
lr_documents_clear <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "DELETE", "/documents", show_status = show_status)
  return(as.data.table(res))
}

#' 3.9 获取所有文档状态 (已废弃，最多1000条)
lr_documents_get_all <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/documents", show_status = show_status)
  return(res)
}

#' 3.10 分页获取文档列表 (推荐)
lr_documents_paginated <- function(client, page = 1, page_size = 50, 
                                   sort_field = c("updated_at", "created_at", "id", "file_path"),
                                   sort_direction = c("desc", "asc"),
                                   status_filters = NULL,
                                   status_filter = NULL,
                                   show_status = client$show_status) {
  sort_field <- match.arg(sort_field)
  sort_direction <- match.arg(sort_direction)
  
  body <- list(
    page = page,
    page_size = page_size,
    sort_field = sort_field,
    sort_direction = sort_direction,
    status_filters = status_filters,
    status_filter = status_filter
  )
  body <- body[!vapply(body, is.null, logical(1))]
  
  res <- lr_request(client, "POST", "/documents/paginated", body = body, show_status = show_status)
  
  dt_docs <- if (length(res$documents) > 0) rbindlist(lapply(res$documents, as.data.table), fill = TRUE) else data.table()
  dt_pagination <- if (!is.null(res$pagination)) as.data.table(res$pagination) else data.table()
  dt_counts <- if (!is.null(res$status_counts)) as.data.table(res$status_counts) else data.table()
  
  return(list(documents = dt_docs, pagination = dt_pagination, status_counts = dt_counts))
}

#' 3.11 获取文档状态汇总统计
lr_documents_status_counts <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/documents/status_counts", show_status = show_status)
  if (!is.null(res$status_counts)) {
    dt <- data.table(
      status = names(res$status_counts),
      count = as.integer(unlist(res$status_counts))
    )
    return(dt)
  }
  return(as.data.table(res))
}

#' 3.12 查询支持的文件类型与解析引擎
lr_documents_supported_file_types <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/documents/supported_file_types", show_status = show_status)
  dt_exts <- data.table(supported_extensions = unlist(res$supported_extensions))
  return(list(supported_extensions = dt_exts, engines = res$engines))
}

#' 3.13 追踪任务 ID 状态
lr_documents_track_status <- function(client, track_id, show_status = client$show_status) {
  endpoint <- sprintf("/documents/track_status/%s", track_id)
  res <- lr_request(client, "GET", endpoint, show_status = show_status)
  dt_docs <- if (length(res$documents) > 0) rbindlist(lapply(res$documents, as.data.table), fill = TRUE) else data.table()
  return(list(track_id = res$track_id, total_count = res$total_count, documents = dt_docs, status_summary = res$status_summary))
}

#' 3.14 依文档 ID 删除文档
lr_documents_delete <- function(client, doc_ids, delete_file = FALSE, delete_llm_cache = FALSE, show_status = client$show_status) {
  body <- list(
    doc_ids = as.list(doc_ids),
    delete_file = delete_file,
    delete_llm_cache = delete_llm_cache
  )
  res <- lr_request(client, "DELETE", "/documents/delete_document", body = body, show_status = show_status)
  return(as.data.table(res))
}

#' 3.15 重新处理失败/中断的文档
lr_documents_reprocess_failed <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "POST", "/documents/reprocess_failed", show_status = show_status)
  return(as.data.table(res))
}

#' 3.16 强制重置崩溃恢复锁 (Force Reset Recovery Fence)
lr_documents_force_reset_recovery <- function(client, confirm = FALSE, show_status = client$show_status) {
  res <- lr_request(client, "POST", "/documents/recovery/force_reset", body = list(confirm = confirm), show_status = show_status)
  return(as.data.table(res))
}

# ==============================================================================
# 4. 管道监控与缓存接口 (Pipeline & Cache Control)
# ==============================================================================

#' 4.1 获取文档处理管道状态
lr_pipeline_status <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/documents/pipeline_status", show_status = show_status)
  dt_status <- data.table(
    busy = res$busy %||% FALSE,
    job_name = res$job_name %||% NA_character_,
    job_start = res$job_start %||% NA_character_,
    docs = res$docs %||% 0,
    batchs = res$batchs %||% 0,
    cur_batch = res$cur_batch %||% 0,
    latest_message = res$latest_message %||% NA_character_,
    recovery_required = res$recovery_required %||% FALSE
  )
  return(list(pipeline = dt_status, history_messages = unlist(res$history_messages)))
}

#' 4.2 取消当前运行的管道任务
lr_pipeline_cancel <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "POST", "/documents/cancel_pipeline", show_status = show_status)
  return(as.data.table(res))
}

#' 4.3 清除 LLM 提取/响应缓存
lr_clear_cache <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "POST", "/documents/clear_cache", body = list(), show_status = show_status)
  return(as.data.table(res))
}

# ==============================================================================
# 5. RAG 检索与问答接口 (Query & Retrieval)
# ==============================================================================

#' 构建 Query 请求载荷的标准辅助函数
.build_query_payload <- function(query, mode, only_need_context, only_need_prompt,
                                 response_type, top_k, chunk_top_k, max_entity_tokens,
                                 max_relation_tokens, max_total_tokens, hl_keywords,
                                 ll_keywords, conversation_history, user_prompt,
                                 disable_user_prompt_prefix, enable_rerank,
                                 include_references, include_chunk_content,
                                 include_progress, stream) {
  body <- list(
    query = query,
    mode = mode,
    only_need_context = only_need_context,
    only_need_prompt = only_need_prompt,
    response_type = response_type,
    top_k = top_k,
    chunk_top_k = chunk_top_k,
    max_entity_tokens = max_entity_tokens,
    max_relation_tokens = max_relation_tokens,
    max_total_tokens = max_total_tokens,
    hl_keywords = hl_keywords,
    ll_keywords = ll_keywords,
    conversation_history = conversation_history,
    user_prompt = user_prompt,
    disable_user_prompt_prefix = disable_user_prompt_prefix,
    enable_rerank = enable_rerank,
    include_references = include_references,
    include_chunk_content = include_chunk_content,
    include_progress = include_progress,
    stream = stream
  )
  return(body[!vapply(body, is.null, logical(1))])
}

#' 5.1 标准 RAG 文本查询 (Non-Streaming)
lr_query <- function(client, query,
                     mode = c("mix", "local", "global", "hybrid", "naive", "bypass"),
                     only_need_context = FALSE,
                     only_need_prompt = FALSE,
                     response_type = "Multiple Paragraphs",
                     top_k = NULL, chunk_top_k = NULL,
                     max_entity_tokens = NULL, max_relation_tokens = NULL, max_total_tokens = NULL,
                     hl_keywords = NULL, ll_keywords = NULL,
                     conversation_history = NULL, user_prompt = NULL,
                     disable_user_prompt_prefix = FALSE, enable_rerank = TRUE,
                     include_references = TRUE, include_chunk_content = FALSE,
                     show_status = client$show_status) {
  mode <- match.arg(mode)
  body <- .build_query_payload(
    query = query, mode = mode, only_need_context = only_need_context,
    only_need_prompt = only_need_prompt, response_type = response_type,
    top_k = top_k, chunk_top_k = chunk_top_k, max_entity_tokens = max_entity_tokens,
    max_relation_tokens = max_relation_tokens, max_total_tokens = max_total_tokens,
    hl_keywords = hl_keywords, ll_keywords = ll_keywords,
    conversation_history = conversation_history, user_prompt = user_prompt,
    disable_user_prompt_prefix = disable_user_prompt_prefix, enable_rerank = enable_rerank,
    include_references = include_references, include_chunk_content = include_chunk_content,
    include_progress = FALSE, stream = FALSE
  )
  res <- lr_request(client, "POST", "/query", body = body, show_status = show_status)
  
  # 结构化引用列表为 data.table
  dt_refs <- if (!is.null(res$references) && length(res$references) > 0) {
    rbindlist(lapply(res$references, as.data.table), fill = TRUE)
  } else {
    data.table()
  }
  
  return(list(response = res$response, references = dt_refs))
}

#' 5.2 流式/多段 RAG 文本查询 (Stream)
lr_query_stream <- function(client, query,
                            mode = c("mix", "local", "global", "hybrid", "naive", "bypass"),
                            include_progress = FALSE,
                            stream = TRUE,
                            show_status = client$show_status, ...) {
  mode <- match.arg(mode)
  body <- .build_query_payload(query = query, mode = mode, include_progress = include_progress, stream = stream, ...)
  res <- lr_request(client, "POST", "/query/stream", body = body, show_status = show_status)
  return(res)
}

#' 5.3 结构化 RAG 数据分析查询 (不经过 LLM 生成，直接返回检索图谱与块)
lr_query_data <- function(client, query,
                          mode = c("mix", "local", "global", "hybrid", "naive", "bypass"),
                          top_k = 10, chunk_top_k = 5,
                          max_entity_tokens = NULL, max_relation_tokens = NULL,
                          max_total_tokens = NULL, hl_keywords = NULL, ll_keywords = NULL,
                          show_status = client$show_status) {
  mode <- match.arg(mode)
  body <- .build_query_payload(
    query = query, mode = mode, only_need_context = TRUE, only_need_prompt = FALSE,
    response_type = NULL, top_k = top_k, chunk_top_k = chunk_top_k,
    max_entity_tokens = max_entity_tokens, max_relation_tokens = max_relation_tokens,
    max_total_tokens = max_total_tokens, hl_keywords = hl_keywords, ll_keywords = ll_keywords,
    conversation_history = NULL, user_prompt = NULL, disable_user_prompt_prefix = FALSE,
    enable_rerank = TRUE, include_references = TRUE, include_chunk_content = TRUE,
    include_progress = FALSE, stream = FALSE
  )
  res <- lr_request(client, "POST", "/query/data", body = body, show_status = show_status)
  
  # 数据表转换
  entities_dt <- if (length(res$data$entities) > 0) rbindlist(lapply(res$data$entities, as.data.table), fill = TRUE) else data.table()
  relations_dt <- if (length(res$data$relationships) > 0) rbindlist(lapply(res$data$relationships, as.data.table), fill = TRUE) else data.table()
  chunks_dt <- if (length(res$data$chunks) > 0) rbindlist(lapply(res$data$chunks, as.data.table), fill = TRUE) else data.table()
  refs_dt <- if (length(res$data$references) > 0) rbindlist(lapply(res$data$references, as.data.table), fill = TRUE) else data.table()
  
  return(list(
    status = res$status,
    message = res$message,
    entities = entities_dt,
    relationships = relations_dt,
    chunks = chunks_dt,
    references = refs_dt,
    metadata = res$metadata
  ))
}

# ==============================================================================
# 6. 知识图谱管理接口 (Knowledge Graph Operations)
# ==============================================================================

#' 6.1 获取所有图谱实体标签
lr_graph_labels <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/graph/label/list", show_status = show_status)
  return(data.table(label = unlist(res)))
}

#' 6.2 按节点连接度获取热门标签
lr_graph_popular_labels <- function(client, limit = 300, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/graph/label/popular", query = list(limit = limit), show_status = show_status)
  return(data.table(label = unlist(res)))
}

#' 6.3 模糊搜索图谱标签
lr_graph_search_labels <- function(client, q, limit = 50, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/graph/label/search", query = list(q = q, limit = limit), show_status = show_status)
  return(data.table(label = unlist(res)))
}

#' 6.4 获取指定标签的连通子图 (Knowledge Graph Subgraph)
lr_graph_get_subgraph <- function(client, label, max_depth = 3, max_nodes = 1000, show_status = client$show_status) {
  query <- list(label = label, max_depth = max_depth, max_nodes = max_nodes)
  res <- lr_request(client, "GET", "/graphs", query = query, show_status = show_status)
  
  # 结构化返回 nodes 与 edges
  nodes_dt <- if (length(res$nodes) > 0) rbindlist(lapply(res$nodes, as.data.table), fill = TRUE) else data.table()
  edges_dt <- if (length(res$edges) > 0) rbindlist(lapply(res$edges, as.data.table), fill = TRUE) else data.table()
  return(list(nodes = nodes_dt, edges = edges_dt, raw = res))
}

#' 6.5 检查实体是否存在
lr_graph_entity_exists <- function(client, name, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/graph/entity/exists", query = list(name = name), show_status = show_status)
  return(as.data.table(res))
}

#' 6.6 创建新图谱实体 (Entity)
lr_graph_entity_create <- function(client, entity_name, entity_data = list(description = "", entity_type = "UNKNOWN"), show_status = client$show_status) {
  body <- list(entity_name = entity_name, entity_data = entity_data)
  res <- lr_request(client, "POST", "/graph/entity/create", body = body, show_status = show_status)
  return(res)
}

#' 6.7 更新/重命名/合并图谱实体
lr_graph_entity_edit <- function(client, entity_name, updated_data, allow_rename = FALSE, allow_merge = FALSE, show_status = client$show_status) {
  body <- list(
    entity_name = entity_name,
    updated_data = updated_data,
    allow_rename = allow_rename,
    allow_merge = allow_merge
  )
  res <- lr_request(client, "POST", "/graph/entity/edit", body = body, show_status = show_status)
  return(res)
}

#' 6.8 合并多个同义/拼写错误实体
lr_graph_entities_merge <- function(client, entities_to_change, entity_to_change_into, show_status = client$show_status) {
  body <- list(
    entities_to_change = as.list(entities_to_change),
    entity_to_change_into = entity_to_change_into
  )
  res <- lr_request(client, "POST", "/graph/entities/merge", body = body, show_status = show_status)
  return(res)
}

#' 6.9 删除图谱实体
lr_graph_entity_delete <- function(client, entity_name, show_status = client$show_status) {
  body <- list(entity_name = entity_name)
  res <- lr_request(client, "DELETE", "/graph/entity/delete", body = body, show_status = show_status)
  return(as.data.table(res))
}

#' 6.10 创建实体间关系 (Relation)
lr_graph_relation_create <- function(client, source_entity, target_entity, relation_data = list(description = "", keywords = "", weight = 1.0), show_status = client$show_status) {
  body <- list(
    source_entity = source_entity,
    target_entity = target_entity,
    relation_data = relation_data
  )
  res <- lr_request(client, "POST", "/graph/relation/create", body = body, show_status = show_status)
  return(res)
}

#' 6.11 更新关系属性
lr_graph_relation_edit <- function(client, source_id, target_id, updated_data, show_status = client$show_status) {
  body <- list(
    source_id = source_id,
    target_id = target_id,
    updated_data = updated_data
  )
  res <- lr_request(client, "POST", "/graph/relation/edit", body = body, show_status = show_status)
  return(res)
}

#' 6.12 删除两个实体间的关系
lr_graph_relation_delete <- function(client, source_entity, target_entity, show_status = client$show_status) {
  body <- list(
    source_entity = source_entity,
    target_entity = target_entity
  )
  res <- lr_request(client, "DELETE", "/graph/relation/delete", body = body, show_status = show_status)
  return(as.data.table(res))
}

# ==============================================================================
# 7. Ollama 仿真接口 (Ollama Emulation)
# ==============================================================================

#' 7.1 获取 Ollama 服务版本
lr_ollama_version <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/api/version", show_status = show_status)
  return(as.data.table(res))
}

#' 7.2 获取可用模型标签
lr_ollama_tags <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/api/tags", show_status = show_status)
  if (length(res$models) > 0) {
    return(rbindlist(lapply(res$models, as.data.table), fill = TRUE))
  }
  return(as.data.table(res))
}

#' 7.3 列出当前运行中的模型
lr_ollama_ps <- function(client, show_status = client$show_status) {
  res <- lr_request(client, "GET", "/api/ps", show_status = show_status)
  if (length(res$models) > 0) {
    return(rbindlist(lapply(res$models, as.data.table), fill = TRUE))
  }
  return(as.data.table(res))
}

#' 7.4 Ollama 文本补全接口 (Generate)
lr_ollama_generate <- function(client, model, prompt, stream = FALSE, show_status = client$show_status) {
  body <- list(model = model, prompt = prompt, stream = stream)
  res <- lr_request(client, "POST", "/api/generate", body = body, show_status = show_status)
  return(res)
}

#' 7.5 Ollama 对话接口 (Chat)
lr_ollama_chat <- function(client, model, messages, stream = FALSE, show_status = client$show_status) {
  body <- list(model = model, messages = messages, stream = stream)
  res <- lr_request(client, "POST", "/api/chat", body = body, show_status = show_status)
  return(res)
}
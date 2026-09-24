# ==============================================================================
# LightRAG R 客户端调用配套案例 (完整实战工作流)
# ==============================================================================

# 1. 初始化客户端
client <- lr_client(
  base_url = "http://localhost:9621",
  api_key = "your_secure_api_key_here", # 若无需 API key 可设为 NULL
  show_status = TRUE                    # 默认开启服务器响应与状态打印
)

# ------------------------------------------------------------------------------
# 案例 1: 检查服务器健康状态与认证
# ------------------------------------------------------------------------------
cat("\n=== 1. 检查健康状态 ===\n")
health_dt <- lr_health(client, show_status = TRUE)
print(health_dt)

# ------------------------------------------------------------------------------
# 案例 2: 文本与多文本插入 (Document Ingestion)
# ------------------------------------------------------------------------------
cat("\n=== 2. 插入文本知识 ===\n")
# 插入单条文本
text1 <- "新版本的特斯拉 (Tesla) 是一家美国电动车及清洁能源公司，由埃隆·马斯克 (Elon Musk) 领导。"
insert_res <- lr_documents_insert_text(
  client,
  text = text1,
  file_source = "tesla_intro2.txt",
  show_status = TRUE
)
print(insert_res)

# 批量插入文本
texts <- c(
  "SpaceX 是一家由马斯克创办的太空探索技术公司，目标是实现火星殖民。",
  "Neuralink 正在研发脑机接口芯片，致力于帮助瘫痪患者恢复运动与交流能力。"
)
sources <- c("spacex.txt", "neuralink.txt")
batch_res <- lr_documents_insert_texts(client, texts = texts, file_sources = sources)
print(batch_res)

# ------------------------------------------------------------------------------
# 案例 3: 监控管道处理进度与文档状态
# ------------------------------------------------------------------------------
cat("\n=== 3. 监控管道状态 ===\n")
pipe_info <- lr_pipeline_status(client, show_status = FALSE)
print(pipe_info$pipeline)

# 分页查询已录入文档，并用 data.table 进行统计过滤
doc_page <- lr_documents_paginated(client, page = 1, page_size = 10, sort_field = "created_at")
print(doc_page$pagination)

# data.table 语法操作：过滤状态为 PROCESSED 的文档
dt_docs <- doc_page$documents
if (nrow(dt_docs) > 0) {
  processed_docs <- dt_docs[status == "PROCESSED", .(id, file_path, status, created_at)]
  print(processed_docs)
}

# ------------------------------------------------------------------------------
# 案例 4: 混合 RAG 查询与引用分析 (Mix Mode Query)
# ------------------------------------------------------------------------------
cat("\n=== 4. 混合模式 RAG 问答 ===\n")
query_res <- lr_query(
  client,
  query = "埃隆·马斯克旗下的公司都有哪些？它们的主要业务是什么？",
  mode = "mix",
  include_references = TRUE,
  show_status = TRUE
)

cat("\n【LLM 回答】:\n", query_res$response, "\n")
cat("\n【引用源表】:\n")
print(query_res$references)

# ------------------------------------------------------------------------------
# 案例 5: 检索纯图谱结构数据并用 data.table 分析 (Query Data)
# ------------------------------------------------------------------------------
cat("\n=== 5. 图谱与检索片段结构化分析 ===\n")
raw_rag_data <- lr_query_data(
  client,
  query = "Tesla SpaceX Neuralink",
  mode = "local",
  top_k = 10,
  chunk_top_k = 5,
  show_status = FALSE # 关闭服务器输出，仅打印分析结果
)

# 使用 data.table 快速分析提取出的实体与关联度
cat("\n[检索到的实体列表]:\n")
print(raw_rag_data$entities[, .(entity_name, entity_type, description)])

cat("\n[实体关系网络]:\n")
print(raw_rag_data$relationships[, .(src_id, tgt_id, weight, description)])

# ------------------------------------------------------------------------------
# 案例 6: 知识图谱实体治理与合并 (Graph CRUD & Merging)
# ------------------------------------------------------------------------------
cat("\n=== 6. 图谱实体与关系治理 ===\n")
# 检查实体是否存在
exists_res <- lr_graph_entity_exists(client, name = "Tesla")
print(exists_res)

# 手动创建新实体与关系
lr_graph_entity_create(
  client,
  entity_name = "The Boring Company",
  entity_data = list(description = "地下隧道基础设施建设公司", entity_type = "ORGANIZATION")
)

lr_graph_relation_create(
  client,
  source_entity = "Elon Musk",
  target_entity = "The Boring Company",
  relation_data = list(description = "Elon Musk 是 The Boring Company 的创始人", keywords = "founder, tunnel", weight = 1.5)
)

# 模拟合并重复/别名实体（例如将 "Elon Msk" 合并进 "Elon Musk"）
merge_res <- lr_graph_entities_merge(
  client,
  entities_to_change = c("Elon Msk", "Ellon Musk"),
  entity_to_change_into = "Elon Musk",
  show_status = TRUE
)
print(merge_res$message)

# ------------------------------------------------------------------------------
# 案例 7: 检索子图网络 (Subgraph Extraction)
# ------------------------------------------------------------------------------
cat("\n=== 7. 获取连通子图 ===\n")
subgraph <- lr_graph_get_subgraph(client, label = "Elon Musk", max_depth = 2)
cat("子图节点数:", nrow(subgraph$nodes), " 子图边数:", nrow(subgraph$edges), "\n")
if (nrow(subgraph$edges) > 0) {
  # data.table 快速提取边关系
  print(subgraph$edges[, .(source, target, weight)])
}
# ENM/SDM 课程仓库系统化建设 SPEC

版本：1.0
日期：2026-09-20
对应 KnowledgeOS：`SPEC-20260920-001`
公开仓库：`Fly-Carrot/ecology-enm-lessons`

## 1. 这份 SPEC 要交付什么

把现有课程代码、配套数据、本地复现结果、讲师课件和补充论文整理成一套可以持续学习的中文课程仓库。

新人进入仓库后，应当能够完成五件事：

1. 先说清自己想画什么地图，以及地图将用于什么任务。
2. 理解出现记录、背景点、环境变量、模型、验证和外推之间的关系。
3. 沿一条清楚的主线阅读课程，同时按需进入 MaxEnt、随机森林、boosting、ensemble、扩散模拟等专题。
4. 用明确的命令重跑课程例子，知道输入来自哪里、输出代表什么。
5. 从中文问题、中文术语、课程模块、论文、代码、数据或图表中的任一入口，找到原始证据。

课程仓库采用中文作为主语言。英文保留在术语、函数名、包名、论文题名和原始代码中。

## 2. 当前基线

### 2.1 公开课程仓库

- 仓库为公开仓库，默认分支是 `main`。
- 当前 fork 的 `HEAD` 为 `31e6180`。
- 本地记录的上游 `qiaohj/ENM_curriculum` 为 `02362d6`。
- 原课程代码使用 MIT License，原作者版权声明必须保留。
- 当前根目录同时放有 D1-D15、扩散案例、统计课程、LightRAG、尺度案例、中文导读和网站，学习入口已经存在，内容分类还不完整。

### 2.2 已完成的本地复现

完整复现结果位于项目内的 `outputs/enm-curriculum-reproduction/`。这套复现固定在以下来源：

- 课程代码提交：`4936e2e940968766340ed2788f983ae210930258`
- Figshare 数据：`10.6084/m9.figshare.33453802.v2`
- 数据许可：CC BY 4.0

现有复现已经完成：

- D1-D15 顺序运行 15/15。
- D1-D15 独立 R 会话运行 15/15。
- 73 项数值在预设容差内。
- 17/17 项总验收通过。
- 15 张标准化分析图通过图形检查。
- 已有 `module-cards.csv`、`claim-evidence.csv`、`adaptation-log.csv` 和运行状态表。

课程仓库当前代码与复现所用历史提交不相同。后续所有图、表和结论必须同时写明 `source_commit`，让读者知道结果来自哪一版代码。

### 2.3 2026-09-20 新增材料

本批共有 14 个顶层文件，已移出 Downloads，进入本地受控资料库。完整登记见：

`knowledge/library/sdm-workshop-2026/manifests/course-material-intake.csv`

初步规模：

- 6 份课件，共 168 张幻灯片。
- 7 份 PDF，共 62 页。其中 52 页属于本批新增的独立材料，10 页属于两个重复版本。
- 3 份 R 脚本。其中两份位于 `ensembleM.zip`。
- 2 份重复版本。Lobo 等 2008 为 SHA-256 完全一致的重复件。Zhu 等 2020 为同题名、同页数、同版式的不同文件版本。

课件只有少量讲者备注，且相当一部分页面以图片为主。逐页深读必须同时检查文字、图、表、公式、截图和备注。只抽取 PPTX 内的文字，不能记作深读完成。

## 3. 两层资料结构

课程采用“公开学习仓库 + 本地证据资料库”两层结构。

### 3.1 公开学习仓库

公开仓库存放：

- 原课程中 MIT 许可覆盖的代码和文档。
- 我们原创的中文课程、索引、运行说明和复现图。
- Figshare CC BY 4.0 数据的下载说明、清单和允许公开的小型示例。
- 许可明确允许再发布的第三方材料。
- 受限材料的题名、DOI、中文释义、证据定位和公开 evidence card。

### 3.2 本地证据资料库

本地资料库存放：

- 未获得再发布授权的讲师课件原件。当前已获授权的 13 份课件在 `course/courseware/` 公开发布。
- 授权不清或版权受限的论文 PDF。
- 原始 ZIP 和课程附件。
- 逐页文本、OCR、页面渲染、阅读笔记和内部证据卡。
- 不适合公开的完整日志、大型数据和中间模型对象。

公开页面不出现本机绝对路径。公开 evidence card 通过稳定 `source_id` 和页码或幻灯片号回链本地证据。

## 4. 课程的故事主线

课程按生态学问题推进。D1-D15 继续作为练习编号，但不再承担全部叙事。

| 模块 | 生态学家正在问什么 | 主要内容 | 现有课程与新增材料 |
| --- | --- | --- | --- |
| M00 地图要回答什么 | 我们究竟要估计适宜性、出现、占域、数量，还是未来可到达范围？ | target、estimand、潜在生态状态、观测过程、尺度、deployment task | 现有 target-first 综合；CMT-003；CMT-009 |
| M01 出现记录可信吗 | 一个点从哪里来，它没有出现又代表什么？ | presence-only、检测、坐标、偏差、空间过滤、公民科学 | D1；CMT-006 |
| M02 环境怎样进入模型 | 温度、降水、地形、土地覆盖应选哪一种尺度？ | 栅格、分辨率、投影、WorldClim、GEE、变量质量 | D8；CMT-001；CMT-002 |
| M03 模型在哪里学习 | 哪些环境可作为对照，M 和 background 怎样决定问题？ | accessible area、background、pseudoabsence、calibration area | D2、D6、D15 |
| M04 不同算法怎样学习 | GLM、GAM、MaxEnt、RF 和 boosting 各自偏爱什么形状？ | 归纳偏好、复杂度、正则化、bagging、boosting | D2、D5、D11、D14 |
| M05 变量与复杂度 | 变量越多越好吗？相关性和选择方法怎样影响结果？ | 变量生态意义、共线性、启发式选择、AICc | D3、D5；CMT-001；CMT-013 |
| M06 怎样评价一张图 | AUC、TSS、Boyce 和阈值各回答什么问题？ | confusion matrix、threshold、discrimination、calibration、error cost | D3；CMT-005；CMT-007；CMT-012 |
| M07 怎样模拟真实部署 | 随机交叉验证够不够，去新地点时应怎样留数据？ | spatial block、checkerboard、独立时期、结构化验证 | D6、D12、D14；CMT-006 |
| M08 新环境能否外推 | 模型遇到没见过的环境组合会怎样？ | transferability、clamping、AOA、环境相似性、不确定性 | D4、D7、D9、D11、D13 |
| M09 多模型与稀有物种 | 什么时候做 ensemble，少量记录还能做什么？ | ensemble、权重、模型分歧、ESM、leave-one-out | CMT-010；CMT-005；CMT-006 |
| M10 工具是否可信 | 图形界面和 R 包怎样帮助新人，怎样避免黑箱？ | Shiny、Wallace、ntbox、包选择、版本锁定、软件审计 | CMT-004；CMT-008；CMT-014 |
| M11 地图怎样支持行动 | 适宜性如何连接扩散、监测和管理？ | dispersal、入侵风险、监测分层、行动阈值 | dispersalENM；CMT-011 |

每个模块沿同一条讲解顺序展开：

1. 生态学需求。
2. 当前数据实际记录了什么。
3. 目标变量和估计量。
4. 为什么选这个方法。
5. 代码怎样把数据送入方法。
6. 输出中的数字和地图怎样读。
7. 新方法解决了什么问题。
8. 哪些问题仍然存在。
9. 下一模块为什么出现。

## 5. 目标目录

2026-09-21 已确认目录整理方案：上游原始文件按用途移入 `upstream/`，保留原文件名、内容和 Git 历史。旧路径与新路径、SHA-256 校验值记录在 `catalog/upstream-file-map.csv`。中文教学内容继续放在 `course/` 与 `docs/`；下面其余目录是分阶段建设的目标，不表示现阶段均已建成。

```text
/
├── README.md                     # 中文首页和唯一主入口
├── README.en.md                  # 英文简介与专业词汇入口
├── START-HERE.md                 # 新人十五分钟起步
├── LICENSE                       # 上游 MIT 许可
├── ATTRIBUTION.md                # 乔老师、课程数据、论文、图片致谢
├── THIRD_PARTY_NOTICES.md        # 第三方许可与公开边界
├── CITATION.cff                  # 仓库引用信息
│
├── ENM_curriculum.Rproj          # 原 RStudio 项目文件
├── upstream/                     # 原课程文件；源码内容保持不变
│   ├── README.md                  # 分类、路径与运行前准备
│   ├── day-scripts/D1.R ... D15.R
│   ├── topics/dispersal-enm/
│   ├── topics/fruitfly-brain/
│   ├── topics/scale-matters/
│   ├── topics/r-statistics/
│   ├── tools/lightrag/
│   ├── auxiliary/participants/
│   ├── auxiliary/examples/
│   └── reference/original-readme.html
│
├── catalog/
│   ├── upstream-file-map.csv     # 上游文件旧路径、新路径、分类与校验值
│   ├── material-index.csv        # 课程材料总表
│   ├── question-index.csv        # 中文问题入口
│   ├── term-index.csv            # 中英术语和别名
│   ├── code-index.csv            # 函数、脚本、输入与输出
│   ├── data-index.csv            # 数据来源、版本、许可与下载方式
│   ├── figure-index.csv          # 图、生成脚本、数据和解释边界
│   └── claim-evidence.csv        # 教学判断到证据的连接
│
├── course/
│   ├── curriculum.yml            # 课程顺序和模块依赖
│   ├── pathways/                 # 新人、实操、证据深读三条路径
│   └── modules/
│       ├── M00-target/
│       ├── M01-occurrence/
│       ├── M02-environment/
│       ├── M03-background/
│       ├── M04-algorithms/
│       ├── M05-variable-selection/
│       ├── M06-evaluation/
│       ├── M07-validation/
│       ├── M08-transfer/
│       ├── M09-ensemble/
│       ├── M10-software/
│       └── M11-dispersal-action/
│
├── evidence/
│   ├── source-registry.csv
│   ├── rights-register.csv
│   ├── cards-public/
│   ├── controversy-matrix.csv
│   └── search-index.json
│
├── repro/
│   ├── renv.lock
│   ├── doctor.R
│   ├── bootstrap.R
│   ├── run_module.R
│   ├── verify.R
│   ├── scripts/
│   ├── tests/
│   ├── manifests/
│   └── expected/
│
├── data/
│   ├── README.md
│   ├── sample/                    # 可公开的小型示例
│   ├── derived/                   # 可重建的汇总数据
│   └── manifests/                # 原始数据登记，不上传大型原件
│
├── figures/
│   ├── analysis/                  # 由真实结果生成
│   ├── concepts/                  # 概念解释图
│   └── provenance.csv
│
└── website/
    ├── src/
    ├── data/search-index.json
    ├── build.mjs
    ├── verify.mjs
    └── dist/
```

每个 `course/modules/Mxx/` 至少包含：

```text
lesson.zh-CN.md       # 中文主课文
module.yml            # 目标、先修知识、关键词和入口
evidence.yml          # 主要判断与证据
lab/                  # 可运行代码
data-manifest.yml     # 本模块数据来源
figure-manifest.yml   # 图和生成方法
exercise.md           # 练习
answer.md             # 参考答案
```

## 6. 每份材料怎样深读

### 6.1 统一身份登记

每份材料先登记：

- `source_id`
- 中文题名与英文题名
- 作者、年份、DOI 或 URL
- 文件类型、页数或幻灯片数
- SHA-256、取得日期、版本
- 来源类别：论文、课件、代码、数据、网站或讲师口述
- 许可证据和公开策略
- canonical 文件和重复关系

### 6.2 PPTX 深读

每张幻灯片都要完成以下检查：

- 抽取可选文字。
- 读取讲者备注。
- 渲染页面并视觉检查。
- 识别图、表、公式、地图、网页截图和代码。
- 记录图片来源是否清楚。
- 把讲师判断标为 `workshop-note`。
- 把需要论文支持的判断放进核验队列。
- 用 `CMT-xxx slide N` 作为定位。

图片型页面必须记录 `visual_reviewed=true`。文字抽取为空，仍要检查页面内容。

### 6.3 PDF 深读

每篇 PDF 都要：

- 核对题名、作者、年份、期刊和 DOI。
- 逐页提取正文，保留 PDF 页码。
- 渲染包含关键图、表、公式和限制说明的页面。
- 区分作者直接支持的判断和我们的跨论文综合。
- 记录研究对象、数据、M、尺度、评价方法和部署任务。
- 记录作者主动写出的限制。
- 用 `CMT-xxx PDF p.N` 或既有 `SDM-xxx PDF p.N` 作为定位。

摘要只能用于身份确认，不能替代全文证据。

### 6.4 R 脚本和 ZIP 深读

代码阅读分成四步：

1. 静态阅读。登记包、函数、输入、参数、路径、随机种子和输出。
2. 数据连接。指出每个对象从哪里来，文件或网络请求怎样产生它。
3. 独立运行。在新的 R 会话运行，不能依赖前一个脚本留在内存里的对象。
4. 结果核对。保存日志、运行状态、关键数值、图和容差。

ZIP 先保留原文件和校验和，再展开到工作区。原 ZIP 不覆盖、不改写。

### 6.5 深读完成的定义

只有同时满足以下条件，材料状态才能改为 `deep-read-complete`：

- 所有页面或幻灯片都有 coverage 状态。
- 图片型页面完成视觉检查。
- 关键判断有 locator。
- 代码片段已定位到文件和行号。
- 数据下载入口和版本已登记。
- 适用条件、最强替代解释和 non-claim 已填写。
- 权利状态已核对。

## 7. Evidence Card 的内容

每份独立材料建立一张内部 Evidence Card。公开仓库保存删去受限原文后的公开版。

内部卡片必须回答：

- 这份材料想解决什么生态学问题？
- target 与 estimand 是什么？
- 潜在生态状态是什么？
- 观测过程是什么？
- 空间与时间尺度是什么？
- M 或校准范围怎样定义？
- 输入变量怎样得到？
- 使用了什么算法，关键假设是什么？
- 验证是否模拟真实部署？
- 输出能解释到哪一步？
- 作者发现了什么？
- 最强替代解释是什么？
- 明确不能声称什么？
- 哪些判断仍需核验？

每条证据使用以下等级：

- `V-fulltext`：本地全文、课件页面、代码或数据直接支持。
- `S-synthesis`：跨材料综合后得到的判断。
- `workshop-note`：现场讲师口述或课件经验判断。
- `U-unknown`：当前语料无法回答。

公开卡片不放受限全文、长摘录、整页截图、OCR 全文或本机路径。

## 8. 中文检索系统

检索系统必须同时服务人和机器。Markdown 让人阅读，CSV/JSON 让网站和脚本读取。

### 8.1 七个入口

1. 问题：例如“背景点能不能当作缺失点”。
2. 术语：例如“校准区域、accessible area、M”。
3. 模块：例如“验证”“变量选择”“扩散”。
4. 文献或材料：例如“no silver bullet”“CMT-005”。
5. 代码：例如 `ENMevaluate()`、`thd()`、`blockCV`。
6. 数据：例如 GBIF、WorldClim、Figshare、GEE。
7. 图表：例如“随机验证与空间验证的差别”。

### 8.2 最小字段

```yaml
item_id:
title_zh:
title_en:
aliases_zh: []
aliases_en: []
acronyms: []
keywords_zh: []
keywords_en: []
content_type:
module_id:
difficulty:
prerequisites: []
question_intents: []
target:
estimand:
data_type:
spatial_scale:
temporal_scale:
algorithm: []
validation_design: []
deployment_task:
safe_claims: []
non_claims: []
source_ids: []
locators: []
evidence_grade:
reproduction_status:
code_entry:
data_entry:
rights_visibility:
version:
last_verified:
```

规范术语使用正确拼写。`Occurrance`、`Bimod2` 等原材料中的拼写只作为搜索别名，不作为课程正文用词。

### 8.3 网站搜索

网站构建时从 CSV 生成 `search-index.json`。中文检索采用字符片段、规范词和别名三种匹配。每条结果显示：

- 中文题名。
- 对应英文词。
- 它回答的问题。
- 证据等级。
- 课程模块。
- 代码和数据入口。
- 最近核验日期。

至少准备 20 个真实中文问题作为搜索验收集。正确模块或证据卡应进入前 5 条结果。

## 9. 代码复现标准

### 9.1 目标入口命令

最终仓库提供以下清楚入口：

```bash
Rscript repro/doctor.R
Rscript repro/bootstrap.R
Rscript repro/run_module.R M01 --profile sample
Rscript repro/verify.R
cd website
node build.mjs
node verify.mjs
```

这些命令是目标接口。实现时应保持名字稳定，并在 Windows、macOS 和 Linux 的说明中给出等价用法。

### 9.2 环境

- 使用 `renv.lock` 固定 R 包版本。
- 记录 R、Java、GDAL、GEOS、PROJ 和系统信息。
- MaxEnt 的实现方式要写清楚。`maxnet`、`dismo` 加 `maxent.jar` 和其他实现不能混写。
- 每个随机步骤记录 seed。
- 脚本不得包含某个人电脑的绝对 `setwd()`。
- 每个模块在新的 R 会话中独立运行。

### 9.3 数据

每个数据源登记：

- 数据名和提供者。
- DOI、API 或官方页面。
- 版本与访问日期。
- 下载参数和空间范围。
- 时间范围、单位、坐标系和分辨率。
- 许可。
- 原文件校验和。
- 清洗脚本和派生数据关系。

Figshare 课程数据固定记录版本 2。大文件不直接放进 Git 历史。下载脚本先核对文件 ID、大小和 MD5，再解压。

GBIF 请求要保存物种名、过滤条件、时间、下载键或缓存。WorldClim 和 GEE 要保存数据集版本、band、时间窗口、scale、CRS、region、mask 和导出设置。

AI 辅助生成的 GEE 代码先在小范围运行。数据集 ID、band 名、单位、掩膜和分辨率必须回到 Earth Engine 官方目录核对。

### 9.4 结果

每张结果表与每幅分析图记录：

- `source_commit`
- `data_version`
- `script_hash`
- `environment_hash`
- `seed`
- `result_status`
- 输入与输出路径
- 关键数值和容差

已有 `run-status.csv`、`adaptation-log.csv`、`module-cards.csv` 和 `claim-evidence.csv` 继续使用。新增字段通过迁移表扩展，避免建立互不相通的新表。

## 10. 本批材料的处理计划

| ID | 材料 | 进入哪个模块 | 深读重点 | 代码或数据动作 |
| --- | --- | --- | --- | --- |
| CMT-001 | Variable.pptx | M02、M05 | 环境数据来源、栅格统一、变量数量、相关性与尺度 | 提取所有 URL；复现 crop、resample、mask、reclassify；核对数据分辨率与单位 |
| CMT-002 | Variable_GEE.pptx | M02 | QGIS-GEE、AI 辅助 GEE、WorldClim 和 Daymet 示例 | 重写可审计 GEE 示例；核对数据集 ID、band、日期、scale 与导出范围 |
| CMT-003 | ENM2020.pdf | M00 | 免费课程覆盖了哪些知识，怎样与本仓库互补 | 建立外部学习资源表；不把课程介绍当作算法性能证据 |
| CMT-004 | Shiny.pptx | M10 | Wallace、ntbox、sdm、ShinyBiomod 的用途与界面边界 | 核对当前项目状态、安装方式、导出对象和能否得到可复现代码 |
| CMT-005 | Model Threshold and Evaluation.pptx | M06、M07 | MTP、P10、TSS、AUC、partial ROC、Boyce 与空间验证 | 把公式、输入、输出和错误代价分开；用同一示例比较指标 |
| CMT-006 | Occurrence data-Model strategy.pptx | M01、M07、M09 | 坐标、来源、清洗、偏差、空间自相关、记录量与策略 | 建立从原始记录到 clean occurrence 的完整脚本；验证随机与空间划分 |
| CMT-007 | Lobo 2008 重复件 | M06 | 复用既有 SDM-027 证据 | 不新增论文身份；链接 canonical Evidence Card |
| CMT-008 | Troubling Trends | M10 | 软件选择、盲目信任、开放性和可检查性 | 建立软件选择检查表；区分论文事实和当前软件状态 |
| CMT-009 | Fundamental niche 2026 | M00、M11 | 基础生态位、实现生态位、生存与繁殖证据、全球变化 | 与 BAM、target-first 和过程模型对读；不把 observed niche 直接提升为 fundamental niche |
| CMT-010 | ensembleM.zip | M09 | ensemble 与 ESM、单模型分歧、权重、稀有物种 | 展开 28 张课件与 2 个脚本；修复为相对路径；锁版本；补 seed；独立运行 |
| CMT-011 | Zhu 等 2020 大黄蜂 | M11 | 适宜性、ensemble、扩散模拟、监测与清除 | 合并到既有 ZHU-EXT-04 身份；复核适宜性到扩散的连接条件 |
| CMT-012 | thd.R | M06 | MTP、P10、固定阈值、NA 与二值化 | 建立单元测试；检查 0-1/0-1000 输入、全 NA、少于 10 点和 CRS |
| CMT-013 | Cobos 等 2019 | M05 | 启发式变量选择与穷举比较 | 提取各策略、评价条件和适用范围；连接 ENMeval/kuenm 操作 |
| CMT-014 | R package checklist | M10 | 各 R 包覆盖的建模步骤 | 建立包功能表；逐项核对当前版本、维护状态和官方文档 |

## 11. 优先核验的课程判断

以下表述很适合教学，但必须先写清生效条件，再进入课程主张：

- “5-8 个变量就够了”。
- “Pearson 相关系数低于 0.7 就可以”。
- “共线性不会影响 MaxEnt calibration”。
- “1-10 个点不建模，10-20 个点用 ESM，20 个以上做 ensemble”。
- “ensemble 会比单模型更可靠”。
- “AUC 高说明模型好”。
- “换成 partial ROC 或 Boyce 就解决了评价问题”。
- “随机 70/30 留出可以检验外推能力”。
- “Shiny 界面的结果等同于可复现分析”。
- “AI 生成的 GEE 代码能直接用于正式数据生产”。

核验时先比较 target、数据类型、M、尺度、评价指标和部署任务。不同论文结论相反时，优先检查这些条件是否不同。

## 12. 已发现的代码检查点

### 12.1 `ensembleM.R`

原始脚本保留为课程证据。公开课程使用重新实现并经过测试的版本。当前需要核对：

- Windows 绝对工作目录。
- 包版本未锁定。
- 空间稀疏、伪缺失抽样和模型拟合缺少统一 seed。
- `replicatin` 参数拼写。
- `Longitude/Latitude` 与 `x/y` 列名流转。
- 伪缺失数量与代码注释是否一致。
- 多算法结果拼接前的尺度和图层含义。
- 用 AUC 或 TSS 加权时的验证数据来源。

### 12.2 `ESM.R`

需要核对：

- `flexsdm` 当前版本中的函数参数。
- 稀有物种样例的校准范围。
- repeated k-fold 与空间部署任务是否匹配。
- ESM 的二变量子模型数量、权重和汇总方式。
- 标准模型与 ESM 的比较是否使用相同数据划分。

### 12.3 `thd.R`

至少建立以下测试：

- MTP。
- P10。
- 指定固定阈值。
- 0-1 与 0-1000 两种输入尺度。
- 点数少于 10。
- 全部为 NA 或部分为 NA。
- 输入点 CRS 与栅格 CRS 不一致。
- 阈值以下像元输出 0 还是 NA。

## 13. 图表与写作标准

### 13.1 图表分三类

- 分析结果图：由真实数据和脚本生成，可回到数值表。
- 概念图：解释流程、模型结构和尺度，明确标记为示意图。
- AI 场景图：帮助读者进入情境，明确标记为 AI 生成，不作为证据。

每幅图必须有 `figure_id`、图注、数据来源、生成脚本、许可和 non-claim。

### 13.2 中文写作

- 一句话只承担一个主要意思。
- 第一次出现专业词时写“中文（English term）”。
- 先讲生态问题，再讲函数和参数。
- 公式后立刻用日常语言解释每一项。
- 不把 suitability 写成 occurrence probability、abundance、fitness 或 habitat quality。
- 不把高 AUC、随机交叉验证或训练拟合写成跨时空可转移性。
- 不把 residual association 写成物种相互作用机制。

### 13.3 每节结尾

每节用六行收束：

- 直接答案。
- 证据与定位。
- 生效条件。
- 最强替代解释。
- non-claim。
- 置信度与下一项核验。

## 14. 版权、致谢和公开规则

### 14.1 已确认可公开的部分

- 上游 GitHub 代码：MIT License。保留 `Copyright (c) 2026 Qiao, Huijie`。
- Figshare 数据版本 2：CC BY 4.0。引用 Qiao, Huijie (2026)，保留 DOI 和版本。
- 13 份课程课件：经权利人确认允许公开，以 PPTX 与 PDF 两种格式保存于 `course/courseware/`；课件不自动适用仓库代码的 MIT 许可。
- Zhu 等 2020 大黄蜂论文：文章首页标明 CC BY 4.0。
- 本项目原创中文讲解、索引、代码适配和复现图：单独声明作者和许可。

### 14.2 默认不上传原件的部分

- `ensembleM.zip` 及其中脚本。CMT-010 课件获准公开不代表其配套 ZIP 自动获准。
- `thd.R` 原始文件。
- AAAS、Elsevier 和其他授权未核清的 PDF。
- 论文中的整页、原图和网页截图。

R package checklist 文章首页标明 CC BY-NC-ND 4.0。公开时默认提供元数据、链接和原创功能索引。若分发原文，必须保持原样并完整保留许可；翻译和改图另行核对授权。

### 14.3 公开文件

仓库必须提供：

- `ATTRIBUTION.md`
- `THIRD_PARTY_NOTICES.md`
- `evidence/rights-register.csv`
- `figures/provenance.csv`
- `data/manifests/`
- `CITATION.cff`

公开构建前执行版权白名单检查。`redistribution_status != allowed` 的 PDF、PPTX、ZIP、图片和原始代码不得进入公开构建物。

## 15. 分阶段执行

### Phase 0：冻结现状

产物：

- 当前 Git 提交、上游提交和复现提交登记。
- 当前目录清单。
- 现有网站构建和验证结果。
- 迁移前后文件映射。

通过条件：任何现有结果都能回到迁移前路径和提交。

### Phase 1：材料安置与权利登记

产物：

- 14 项顶层材料的稳定 ID、SHA-256 和路径。
- ZIP 内文件清单。
- 重复关系。
- 权利登记和公开策略。

通过条件：Downloads 不再保留这 14 份原件；每项材料在本地资料库中可找到；哈希与搬运前一致。

### Phase 2：逐页深读

产物：

- 每份独立材料的内部 Evidence Card。
- 逐页或逐幻灯片 coverage 表。
- 图表与代码块清单。
- workshop-note 核验队列。

通过条件：62/62 PDF 页和 168/168 幻灯片有状态；所有图片型页面完成视觉检查；两个重复件只指向一个 canonical identity。

### Phase 3：课程模块重构

产物：

- M00-M11 中文课文。
- 三条学习路径。
- D1-D15 与新模块的映射。
- 每模块练习与答案。

通过条件：新人不需要先理解 D1-D15 的文件顺序，也能沿生态问题读完整门课。

### Phase 4：代码与数据闭环

产物：

- 可公开的适配代码。
- `renv.lock`、doctor、bootstrap、run 和 verify。
- 数据下载清单与小型示例。
- 每模块独立运行日志。

通过条件：干净 clone 后可完成环境检查、样例下载、至少一个核心模块和结果核对；全部核心模块在新 R 会话运行。

### Phase 5：中文检索

产物：

- 七张主索引表。
- 中英术语和别名。
- 网站搜索 JSON。
- 20 个真实问题的搜索测试。

通过条件：每个测试问题的正确模块或证据卡进入前 5 条结果。

### Phase 6：网站与图表

产物：

- 网站由课程模块和索引生成。
- 分析图、概念图和 AI 场景图分类清楚。
- 图表来源和代码完整。

通过条件：无破图、无原始 LaTeX、无本机路径、无未登记素材；手机和电脑均可阅读。

### Phase 7：公开发布

产物：

- 公开发布清单。
- 权利白名单报告。
- 构建与复现验收报告。
- 版本标签和变更说明。

通过条件：公开仓库中受限原件数量为 0；代码、数据、文字和图片的许可分别写清；乔慧捷老师及课程来源得到完整致谢。

## 16. 总验收表

### 材料

- [ ] 14/14 项顶层材料有 ID、哈希、来源、版本、路径和权利状态。
- [ ] `ensembleM.zip` 内 3/3 项文件完成登记。
- [ ] 62/62 PDF 页有 coverage 状态。
- [ ] 168/168 幻灯片有 coverage 状态。
- [ ] 所有低文本或图片型幻灯片完成视觉检查。
- [ ] AUC 与大黄蜂重复件合并到 canonical identity。

### 证据

- [ ] 每条教学事实有 `source_id + locator`。
- [ ] 综合判断标为 `S-synthesis`。
- [ ] 讲师经验判断标为 `workshop-note`。
- [ ] 当前语料不能回答的问题标为 `U-unknown`。
- [ ] 每个关键判断包含条件、替代解释和 non-claim。

### 代码

- [ ] 没有本机绝对路径。
- [ ] 每个随机步骤有 seed。
- [ ] 每个模块可在新 R 会话运行。
- [ ] 数据下载有版本、参数、许可和校验和。
- [ ] 结果保存 source commit、data version、script hash 和环境信息。
- [ ] `thd.R`、ensemble 与 ESM 的测试通过。

### 检索

- [ ] 中文为主，英文专业名词可反查。
- [ ] 七个入口都能回到材料、代码、数据和证据。
- [ ] 常见错拼只作为别名。
- [ ] 20 个中文真实问题通过前 5 条结果验收。

### 公开

- [ ] 上游 MIT 版权声明完整。
- [ ] Figshare CC BY 4.0 署名、DOI 和版本完整。
- [ ] 获准公开的课件保留原署名，并与仓库 MIT 许可分开说明。
- [ ] 授权不清的 PPTX、PDF、ZIP、图片和代码未进入公开构建物。
- [ ] 网站明确说明它是独立学习讲解，不是课程官方页面。
- [ ] 课程原结果、我们的解释、AI 场景图和论文观点分开标记。

## 17. 明确边界

- 现有 27 篇核心 SDM 文献不做无目标的重新抽取。新问题需要时回到对应 Evidence Card 和 PDF 页码。
- Project4 迁移继续延期。本课程仓库不生成 Project4 映射、预测或应用结论。
- 公开课程不把课件经验判断自动升级为论文共识。
- 本仓库不承诺某一种算法永远最好。
- 软件包、GEE 数据集和网站工具都带 `last_verified`，避免把旧版本描述成当前状态。

## 18. 第一批执行顺序

1. 完成 14 份材料的逐页 coverage 和内部 Evidence Card。
2. 优先处理 M01、M02、M05、M06、M09、M10，因为新增材料集中在这些模块。
3. 修复并独立运行 `thd.R`、`ensembleM.R` 和 `ESM.R`。
4. 把现有 `enm-curriculum-reproduction` 的可公开代码、状态表和图接入课程仓库。
5. 建立七张中文索引表。
6. 用 M00-M11 重写网站导航，同时保留 D1-D15 对照入口。
7. 完成权利白名单、干净 clone 复现和公开发布检查。

完成这套建设后，仓库的主线会很清楚：先决定地图要回答什么，再检查记录和环境，接着理解模型怎样学习，随后用与真实任务匹配的方法验证，最后讨论地图怎样支持监测、迁移和管理。

# 上游课程原件在哪里

本目录收纳[乔慧捷老师 ENM Curriculum](https://github.com/qiaohj/ENM_curriculum) 中的原始课程文件。我们只调整了这些文件在本仓库中的位置，没有改动它们的内容。原版权声明见仓库根目录的 [LICENSE](../LICENSE)。中文讲解、复现图和学习路线由本仓库另行整理，见[中文入口](../README.zh-CN.md)。

| 想找什么 | 现在的位置 |
| --- | --- |
| D1–D15 课程脚本 | [day-scripts/](day-scripts/) |
| 扩散与环境生态位案例 | [topics/dispersal-enm/](topics/dispersal-enm/) |
| 果蝇专题 | [topics/fruitfly-brain/](topics/fruitfly-brain/) |
| 空间尺度案例 | [topics/scale-matters/](topics/scale-matters/) |
| R 统计基础课程 | [topics/r-statistics/](topics/r-statistics/) |
| LightRAG 示例 | [tools/lightrag/](tools/lightrag/) |
| 参与者代码与分布图 | [auxiliary/participants/](auxiliary/participants/) |
| 小型代码示例 | [auxiliary/examples/](auxiliary/examples/) |
| 原 HTML 课程提纲 | [reference/original-readme.html](reference/original-readme.html) |

每个原文件的旧路径、新路径和 SHA-256 校验值见[文件对照表](../catalog/upstream-file-map.csv)。想按生态问题找代码，可先读[学习导航](../docs/学习导航.md)。

## 运行前要准备什么

这些文件是课程原件，不是整理后就能逐个直接运行的独立程序。D1–D7 会沿用前一天创建的对象；D1、D15 和部分专题代码含原作者机器上的 `setwd()` 或假定旧目录结构。`../Data`、`../Figures`、`../MaleCNS` 等相对路径也会随着文件位置变化。运行某个案例前，应在自己的副本中确认工作目录、输入文件和包版本，并按实际数据位置适配路径。

仓库没有附齐所有输入数据。课程数据入口见[Figshare 发布页](https://doi.org/10.6084/m9.figshare.33453802)，部分脚本还会自行下载环境或物种记录；具体文件需求以对应脚本和[学习导航的准备说明](../docs/学习导航.md#运行前先看这里)为准。静态语法检查只能证明 R 代码可以被解析，不能代替数据获取、模型拟合或结果复现。

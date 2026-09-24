library(ggplot2)
library(ggforce)
library(patchwork)
library(data.table)

# 1. 假设读取近 3.6 Ma 的温度/环境数据 (如使用你的本地数据集 dt540_df 或 LR04/CENOGRID 转换的温度)
dt36_df <- readRDS("../Data/Paleo_ENV/dt3.6_df.rda")

# 2. 地质年代结构定义 (主划分：世 Epoch)
epochs <- data.frame(
  epoch = c("上新世 (晚期)", "更新世", "全新世"),
  start = c(3.6, 2.58, 0.0117),
  end   = c(2.58, 0.0117, 0)
)
epochs$mid <- (epochs$start + epochs$end) / 2

# 3. 细分阶/亚世 (Sub-epochs / Stages)
stages <- data.frame(
  name  = c("皮亚琴察期", "格拉斯期", "卡拉布里亚期", "中更新世", "晚更新世", "全新世"),
  start = c(3.60, 2.58, 1.80, 0.774, 0.129, 0.0117),
  end   = c(2.58, 1.80, 0.774, 0.129, 0.0117, 0),
  epoch = c("上新世 (晚期)", rep("更新世", 4), "全新世")
)
stages$mid <- (stages$start + stages$end) / 2

# 4. 顶部事件：气候转型、冰期与古环境事件
top_events <- data.frame(
  Ma = c(3.20, 2.70, 0.90, 0.120, 0.021),
  label = c(
    "中上新世暖期 (mPWP)\n(+2~3°C 类似现代变暖)", 
    "北半球大冰期全面启动\n(NHG / 巴拿马地峡闭合)", 
    "中更新世气候转型 (MPT)\n(41 kyr 转变为 100 kyr 周期)", 
    "末次间冰期\n(LIG)", 
    "末次盛冰期\n(LGM)"
  ),
  y_start = c(20.5, 21.0, 20.5, 21.2,  15.2)-10,
  y_end   = c(17.5, 16.8, 16.5, 15.0, 15.0)-10
)

# 5. 底部事件：古人类演化与古生物/文明技术事件
bottom_events <- data.frame(
  Ma = c(3.20, 2.80, 1.76, 0.30, 0.010),
  label = c(
    "南方古猿 (如'露西')\n繁盛期", 
    "人属 (Homo)\n最早化石记录", 
    "阿舍利石器技术\n/ 直立人扩散", 
    "解剖学现代人\n(智人) 起源", 
    "农业起源\n与定居文明"
  ),
  y_start = c(7.0, 6.0, 7.2, 6.0, 7.5)-15,
  y_end   = c(9.5, 9.8, 10.0, 10.5, 11.2)-15
)

# 6. 绘图
p <- ggplot() +
  # 背景世 (Epoch) 填充
  geom_rect(
    data = epochs, 
    aes(xmin = start, xmax = end, ymin = 5, ymax = 13, fill = epoch),
    alpha = 0.08, show.legend = FALSE
  ) +
  # 阶段垂直分割线
  geom_vline(xintercept = c(stages$start, 0), color = "gray80", linetype = "dotted", linewidth = 0.4) +
  geom_vline(xintercept = epochs$start, color = "gray50", linetype = "dashed", linewidth = 0.6) +
  
  # 温度/古气候曲线 (如果使用真实数据，取消下一行注释)
  geom_line(data = dt36_df[variable=="T"], aes(x = mya, y = mean_value), 
            color = "#d95f02", linewidth = 0.9) +
  
  # 顶部事件箭头与标注
  geom_segment(
    data = top_events, 
    aes(x = Ma, y = y_start, xend = Ma, yend = y_end),
    arrow = arrow(length = unit(0.15, "cm"), type = "closed"), 
    color = "#b2182b", linewidth = 0.55
  ) +
  geom_text(
    data = top_events, 
    aes(x = Ma, y = y_start + 0.3, label = label),
    color = "#b2182b", size = 2.7, fontface = "bold", vjust = 0, lineheight = 0.85
  ) +
  
  # 底部事件箭头与标注
  geom_segment(
    data = bottom_events, 
    aes(x = Ma, y = y_start, xend = Ma, yend = y_end),
    arrow = arrow(length = unit(0.15, "cm"), type = "closed"), 
    color = "#1b7837", linewidth = 0.55
  ) +
  geom_text(
    data = bottom_events, 
    aes(x = Ma, y = y_start - 0.3, label = label),
    color = "#1b7837", size = 2.7, fontface = "bold", vjust = 1, lineheight = 0.85
  ) +
  
  # 顶部地质年代标签
  geom_text(
    data = epochs, aes(x = mid, y = 13.5, label = epoch), 
    color = "gray20", fontface = "bold", size = 3.6
  ) +
  geom_text(
    data = stages, aes(x = mid, y = 12.7, label = name), 
    color = "gray45", size = 2.3
  ) +
  
  # 坐标轴与比例设置 (0 到 3.6 Ma)
  scale_x_reverse(
    limits = c(3.65, -0.1),
    breaks = seq(3.5, 0, by = -0.5),
    labels = function(x) paste0(x, " Ma")
  ) +
  scale_y_continuous(
    limits = c(-10, 14),
    breaks = seq(-10, 12, by = 2),
    labels = function(y) paste0(y, " °C")
  ) +
  scale_fill_manual(values = c("上新世 (晚期)" = "#fed976", "更新世" = "#bdd7e7", "全新世" = "#a1d99b")) +
  
  # 图表元信息与主题
  labs(
    title = "晚近地质历史（过去 360 万年）古气候演化与重大地质/演化事件",
    subtitle = "顶部红标：冰期启动与重大古气候事件 | 底部绿标：人类演化与智人物质文化事件",
    x = "地质年代（百万年前，Ma）",
    y = "估计全球平均地表温度 (°C)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
    plot.subtitle = element_text(size = 9.5, hjust = 0.5, color = "gray30", margin = margin(b = 10)),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

# 显示并保存
print(p)
ggsave(p, filename = "../Figures/T_3.6Ma.png", width = 12, height = 6.5, dpi = 300)


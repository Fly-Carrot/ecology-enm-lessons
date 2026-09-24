library(ggplot2)
library(ggforce)
library(patchwork)
library(data.table)
dt540_df<-readRDS("../Data/Paleo_ENV/dt540_df.rda")
periods <- data.frame(
  name = c("寒武纪", "奥陶纪", "志留纪", "泥盆纪", "石炭纪", "二叠纪", 
           "三叠纪", "侏罗纪", "白垩纪", "古近纪", "新近纪", "第四纪"),
  start = c(538.8, 485.4, 443.8, 419.2, 358.9, 298.9, 251.9, 201.4, 145.0, 66.0, 23.03, 2.58),
  end   = c(485.4, 443.8, 419.2, 358.9, 298.9, 251.9, 201.4, 145.0, 66.0, 23.03, 2.58, 0),
  era   = c(rep("古生代", 6), rep("中生代", 3), rep("新生代", 3))
)

periods$mid <- (periods$start + periods$end) / 2

eras <- data.frame(
  era   = c("古生代", "中生代", "新生代"),
  start = c(538.8, 251.9, 66.0),
  end   = c(251.9, 66.0, 0)
)
eras$mid <- (eras$start + eras$end) / 2

top_events <- data.frame(
  Ma = c(445, 252, 201, 66, 56),
  label = c("晚奥陶大冰期", "西伯利亚暗色岩爆发\n(二叠纪末大灭绝)", 
            "中大西洋岩浆省\n(CAMP火山)", "小行星撞击 / 德干火山\n(K-Pg灭绝)", 
            "PETM极热事件"),
  y_start = c(34, 35, 34, 35, 31)-5,
  y_end   = c(27, 28, 26, 26, 25)-5
)

bottom_events <- data.frame(
  Ma = c(518, 450, 233, 130, 66, 2.8),
  label = c("早期鱼类出现", "植物/节肢动物登陆", "恐龙出现", "被子植物辐射", "非鸟恐龙灭绝",
            "人属出现"),
  y_start = c(5, 4, 5, 4, 5, 11),
  y_end   = c(10, 11, 12, 11, 12, 6)
)

p <- ggplot() +
  geom_rect(data = periods, 
            aes(xmin = start, xmax = end, ymin = 0, ymax = 38, fill = era),
            alpha = 0.08, show.legend = FALSE) +
  geom_vline(xintercept = c(periods$start, 0), color = "gray75", linetype = "dotted", linewidth = 0.4) +
  geom_vline(xintercept = eras$start, color = "gray40", linetype = "dashed", linewidth = 0.7) +
  
  geom_line(data = dt540_df[variable=="T"], 
            aes(x = mya, y = mean_value), color = "#d95f02", linewidth = 1) +
  
  geom_segment(data = top_events, 
               aes(x = Ma, y = y_start, xend = Ma, yend = y_end),
               arrow = arrow(length = unit(0.18, "cm"), type = "closed"), 
               color = "#b2182b", linewidth = 0.6) +
  geom_text(data = top_events, 
            aes(x = Ma, y = y_start + 0.5, label = label),
            color = "#b2182b", size = 2.8, fontface = "bold", vjust = 0, lineheight = 0.85) +
  
  geom_segment(data = bottom_events, 
               aes(x = Ma, y = y_start, xend = Ma, yend = y_end),
               arrow = arrow(length = unit(0.18, "cm"), type = "closed"), 
               color = "#1b7837", linewidth = 0.6) +
  geom_text(data = bottom_events, 
            aes(x = Ma, y = y_start - 0.5, label = label),
            color = "#1b7837", size = 2.8, fontface = "bold", vjust = 1, lineheight = 0.85) +
  
  geom_text(data = eras, aes(x = mid, y = 37.5, label = era), 
            color = "gray20", fontface = "bold", size = 3.8) +
  geom_text(data = periods, aes(x = mid, y = 36, label = name), 
            color = "gray40", size = 2.4) +
  
  scale_x_reverse(
    limits = c(545, -15),
    breaks = seq(500, 0, by = -100),
    labels = function(x) paste0(x, " Ma")
  ) +
  scale_y_continuous(
    limits = c(0, 39),
    breaks = seq(5, 35, by = 5),
    labels = function(y) paste0(y, " °C")
  ) +
  scale_fill_manual(values = c("古生代" = "#386cb0", "中生代" = "#7fc97f", "新生代" = "#fdc086")) +
  labs(
    title = "显生宙（5.4 亿年前至现代）全球平均地表温度与关键历史事件",
    subtitle = "灾变事件/超级火山/撞击 | 底部绿标：重大生物演化事件",
    x = "地质年代（百万年前，Ma）",
    y = "估计全球平均地表温度 (°C)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5, color = "gray30", margin = margin(b = 10)),
    axis.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )


print(p)
ggsave(p, filename="../Figures/T.png", width=12, height=6)


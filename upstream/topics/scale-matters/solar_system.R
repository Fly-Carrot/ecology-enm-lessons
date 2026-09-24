library(ggplot2)
library(patchwork)

# -------------------------------------------------------------
# 1. 真实比例示意图 (To Scale)
# -------------------------------------------------------------
# 单位统一换算为百万公里 (Million km / M km)
# 太阳直径: ~1.39 M km (半径 r = 0.695)
# 地日距离: ~149.6 M km
# 地球直径: ~0.0127 M km (半径 r = 0.00637)
# 地月距离: ~0.384 M km
# 月球直径: ~0.00347 M km (半径 r = 0.00174)

scale_data <- data.frame(
  body = c("Sun", "Earth", "Moon"),
  x = c(0, 149.6, 149.6 + 0.384),
  y = c(0, 0, 0),
  radius_mkm = c(0.695, 0.00637, 0.00174),
  color = c("#FFA500", "#1E90FF", "#D3D3D3")
)

p_scale <- ggplot() +
  # 绘制太阳 (真实比例半径 ~0.7 M km)
  annotate("point", x = 0, y = 0, size = 10, color = "#FFA500") +
  # 绘制地月系统位置 (在当前尺度下极小，用标记线辅助识别)
  annotate("point", x = 149.6, y = 0, size = 1.2, color = "#1E90FF") +
  annotate("segment", x = 149.6, xend = 149.6, y = 0.5, yend = 0.1,
           arrow = arrow(length = unit(0.15, "cm")), color = "white") +
  # 英文注释
  annotate("text", x = 0, y = -0.5, label = "Sun (Radius ~696,000 km)", 
           color = "#FFA500", size = 3.5, fontface = "bold") +
  annotate("text", x = 149.6, y = 0.7, 
           label = "Earth-Moon System\n(Earth & Moon are sub-pixel at this scale)", 
           color = "white", size = 3, hjust = 0.8) +
  annotate("text", x = 75, y = -0.2, 
           label = "Distance: ~149.6 Million km (1 AU)", 
           color = "gray70", size = 3, fontface = "italic") +
  coord_fixed(ratio = 1, xlim = c(-5, 160), ylim = c(-1.5, 1.5)) +
  labs(
    title = "1. True Scale (Distances & Sizes Proportional)",
    subtitle = "At this scale, Earth (~12,742 km) and Moon (~3,474 km) are virtually invisible dots."
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#0B0C10", color = NA),
    plot.title = element_text(color = "white", size = 12, face = "bold", margin = margin(b = 4)),
    plot.subtitle = element_text(color = "gray75", size = 9, margin = margin(b = 10)),
    plot.margin = margin(15, 15, 15, 15)
  )

# -------------------------------------------------------------
# 2. 示意展示图 (Not to Scale / Schematic)
# -------------------------------------------------------------
p_schematic <- ggplot() +
  # 轨道线示意
  annotate("segment", x = 2, xend = 8, y = 0, yend = 0, 
           linetype = "dashed", color = "gray40") +
  annotate("path", 
           x = 8 + 1.2 * cos(seq(0, 2*pi, length.out = 100)),
           y = 0 + 1.2 * sin(seq(0, 2*pi, length.out = 100)),
           linetype = "dotted", color = "gray50") +
  # 天体绘制 (非真实比例放大)
  annotate("point", x = 2, y = 0, size = 26, color = "#FFA500") +       # Sun
  annotate("point", x = 8, y = 0, size = 9, color = "#1E90FF") +        # Earth
  annotate("point", x = 9.2, y = 0, size = 3.5, color = "#D3D3D3") +    # Moon
  # 英文注释
  annotate("text", x = 2, y = -1.5, label = "Sun\n(Illustrative size)", 
           color = "#FFA500", size = 3.5, fontface = "bold") +
  annotate("text", x = 8, y = -1.5, label = "Earth", 
           color = "#1E90FF", size = 3.5, fontface = "bold") +
  annotate("text", x = 9.2, y = 1.3, label = "Moon", 
           color = "#D3D3D3", size = 3.5, fontface = "bold") +
  annotate("text", x = 5, y = 0.4, label = "Not to Scale (For Illustration)", 
           color = "gray70", size = 3, fontface = "italic") +
  annotate("text", x = 9.2, y = -1.5, label = "Lunar Orbit", 
           color = "gray50", size = 2.8) +
  coord_fixed(ratio = 1, xlim = c(0, 11), ylim = c(-2.2, 2.2)) +
  labs(
    title = "2. Schematic Diagram (Not to Scale)",
    subtitle = "Sizes and distances are adjusted for visibility and educational presentation."
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#0B0C10", color = NA),
    plot.title = element_text(color = "white", size = 12, face = "bold", margin = margin(b = 4)),
    plot.subtitle = element_text(color = "gray75", size = 9, margin = margin(b = 10)),
    plot.margin = margin(15, 15, 15, 15)
  )

# -------------------------------------------------------------
# 3. 组合并输出图表
# -------------------------------------------------------------
final_plot <- p_scale / p_schematic +
  plot_layout(heights = c(1, 1.2))

# 显示图表
print(final_plot)

# 保存为高清图片
ggsave("../Figures/sun_earth_moon_comparison.png", final_plot, width = 10, height = 7, dpi = 300)

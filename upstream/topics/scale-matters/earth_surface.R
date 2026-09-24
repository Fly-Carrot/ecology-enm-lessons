

# 安装并加载必要包
# install.packages(c("ggplot2", "patchwork"))
library(ggplot2)
library(patchwork)

# -------------------------------------------------------------
# 1. 基础物理参数定义 (统一单位：公里 / km)
# -------------------------------------------------------------
R_earth <- 6371.0 # 地球平均半径 (km)

objects <- data.frame(
  name = c("5 米 (民居/树木)", "30 米 (10层楼)", "哈里发塔 (828 m)", 
           "珠穆朗玛峰 (8,848 m)", "天宫空间站 (~400 km)"),
  height_km = c(0.005, 0.030, 0.828, 8.848, 400.0),
  category = c("建筑/地面", "建筑/地面", "建筑/地面", "自然地理", "航天轨道"),
  color = c("#4cc9f0", "#4895ef", "#f72585", "#7209b7", "#ffb703")
)

# -------------------------------------------------------------
# 2. 主图：全景地球与天宫空间站真实比例
# -------------------------------------------------------------
# 计算圆周点（地球与轨道）
theta <- seq(0, 2 * pi, length.out = 500)
earth_circle <- data.frame(x = R_earth * cos(theta), y = R_earth * sin(theta))
orbit_circle <- data.frame(x = (R_earth + 400) * cos(theta), y = (R_earth + 400) * sin(theta))

# 空间站角度（设在45度角）
ang_tiangong <- pi / 4
tg_x0 <- R_earth * cos(ang_tiangong)
tg_y0 <- R_earth * sin(ang_tiangong)
tg_x1 <- (R_earth + 400) * cos(ang_tiangong)
tg_y1 <- (R_earth + 400) * sin(ang_tiangong)

# 珠峰等地面物体（设在90度角，即正北极点）
pole_x0 <- 0
pole_y0 <- R_earth
everest_y1 <- R_earth + 8.848

p_main <- ggplot() +
  # 地球本体
  geom_polygon(data = earth_circle, aes(x = x, y = y), fill = "#1d3557", color = "#457b9d", linewidth = 1) +
  geom_text(aes(x = 0, y = 0), label = "地球 (半径 R = 6,371 km)", color = "#f1faee", size = 4.5, fontface = "bold") +
  
  # 天宫空间站轨道虚线 (R + 400 km)
  geom_path(data = orbit_circle, aes(x = x, y = y), color = "#ffb703", linetype = "dashed", linewidth = 0.6) +
  # 空间站高度真实竖线
  geom_segment(aes(x = tg_x0, y = tg_y0, xend = tg_x1, yend = tg_y1), 
               color = "#ffb703", linewidth = 1.2, arrow = arrow(length = unit(0.2, "cm"))) +
  geom_point(aes(x = tg_x1, y = tg_y1), color = "#ffb703", size = 3) +
  geom_text(aes(x = tg_x1 + 400, y = tg_y1 + 400, 
                label = "天宫空间站\n高度: 400 km\n(占地球半径 ~6.3%)"), 
            color = "#ffb703", size = 3.2, hjust = 0, lineheight = 0.9) +
  
  # 北极点上的珠峰与建筑真实比例高度 (肉眼看就是紧贴地表的点)
  geom_segment(aes(x = pole_x0, y = pole_y0, xend = pole_x0, yend = everest_y1), 
               color = "#ef476f", linewidth = 1.5) +
  geom_point(aes(x = pole_x0, y = everest_y1), color = "#ef476f", size = 2) +
  geom_text(aes(x = 0, y = R_earth + 450, 
                label = "← 珠峰 (8.8 km) 与地面建筑群\n(真实比例下厚度不足0.14%，紧贴地表)"), 
            color = "#ef476f", size = 3.2, hjust = 0, lineheight = 0.9) +
  
  coord_fixed(xlim = c(-7500, 9500), ylim = c(-7500, 7800)) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#0b0f19", color = NA),
    panel.background = element_rect(fill = "#0b0f19", color = NA),
    plot.title = element_text(color = "#ffffff", face = "bold", size = 14, hjust = 0.5, margin = margin(t = 10, b = 5)),
    plot.subtitle = element_text(color = "#a8dadc", size = 9.5, hjust = 0.5, margin = margin(b = 10))
  ) +
  labs(
    title = "全景真实比例视图 (Global Scale)",
    subtitle = "在整颗地球尺度下，400 km 的空间站清晰可见，而珠峰和建筑完全贴在地表"
  )

# -------------------------------------------------------------
# 3. 插图：地表 0 ~ 10 km 微观局部真实比例放大视图
# -------------------------------------------------------------
# 选取地表前 4 个微观目标进行横向排列对比，纵轴为严格真实米数
micro_data <- objects[1:4, ]
micro_data$x_pos <- 1:4
micro_data$height_m <- micro_data$height_km * 1000

p_inset <- ggplot(micro_data) +
  # 地表参考线
  geom_hline(yintercept = 0, color = "#457b9d", linewidth = 1.2) +
  # 各物体的高度竖线
  geom_segment(aes(x = x_pos, xend = x_pos, y = 0, yend = height_m, color = name), 
               linewidth = 1.5, show.legend = FALSE) +
  geom_point(aes(x = x_pos, y = height_m, color = name), size = 3, show.legend = FALSE) +
  # 顶部高度文字标签
  geom_text(aes(x = x_pos, y = height_m, label = paste0(name, "\n", height_m, " m")), 
            vjust = -0.4, size = 3, color = "#f1faee", lineheight = 0.85) +
  scale_y_continuous(
    limits = c(0, 10500),
    breaks = seq(0, 10000, by = 2000),
    labels = function(y) paste0(y, " m")
  ) +
  scale_x_continuous(limits = c(0.4, 4.6), breaks = NULL) +
  scale_color_manual(values = c("5 米 (民居/树木)" = "#4cc9f0", 
                                "30 米 (10层楼)" = "#4895ef", 
                                "哈里发塔 (828 m)" = "#f72585", 
                                "珠穆朗玛峰 (8,848 m)" = "#7209b7")) +
  labs(
    title = "地表局域微观放大 (0 ~ 10,000 米真实比例)",
    subtitle = "对比 5m、30m、哈里发塔与珠峰的真实物理高差",
    x = NULL,
    y = "海拔高度 (米 / m)"
  ) +
  theme_minimal(base_size = 10) +
  theme(
    plot.background = element_rect(fill = "#141c2e", color = "#457b9d", linewidth = 0.6),
    panel.background = element_rect(fill = "#141c2e", color = NA),
    plot.title = element_text(color = "#ffffff", face = "bold", size = 11, hjust = 0.5),
    plot.subtitle = element_text(color = "#90e0ef", size = 8.5, hjust = 0.5),
    axis.title.y = element_text(color = "#a8dadc", size = 9),
    axis.text.y = element_text(color = "#a8dadc"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "#23334d", linetype = "dashed")
  )

# -------------------------------------------------------------
# 4. 拼图输出
# -------------------------------------------------------------
final_plot <- p_main + p_inset +
  plot_layout(widths = c(1.3, 1)) +
  plot_annotation(
    title = "地球真实物理尺度与高度关系精确定量图",
    subtitle = "基于真实地球平均半径 (6,371 km) 与精确海拔高度绘制",
    theme = theme(
      plot.background = element_rect(fill = "#0b0f19", color = NA),
      plot.title = element_text(color = "#ffffff", size = 16, face = "bold", hjust = 0.5, margin = margin(t = 12, b = 4)),
      plot.subtitle = element_text(color = "#90e0ef", size = 10.5, hjust = 0.5, margin = margin(b = 10))
    )
  )

print(final_plot)
ggsave("../Figures/earth_surface.png", final_plot, width = 10, height = 7, dpi = 300)

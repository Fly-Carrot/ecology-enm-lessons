
# 安装并加载必要包
# install.packages(c("ggplot2", "ggforce", "patchwork"))
library(ggplot2)
library(ggforce)
library(patchwork)

# -------------------------------------------------------------
# 公共主题与绘图函数配置
# -------------------------------------------------------------
dark_theme <- theme_void() +
  theme(
    plot.background = element_rect(fill = "#0d1b2a", color = NA),
    panel.background = element_rect(fill = "#0d1b2a", color = NA),
    plot.title = element_text(color = "#e0e1dd", face = "bold", size = 13, hjust = 0.5, margin = margin(t = 8, b = 4)),
    plot.subtitle = element_text(color = "#778da9", size = 10, hjust = 0.5, margin = margin(b = 8)),
    plot.caption = element_text(color = "#415a77", size = 8.5, hjust = 0.5, margin = margin(t = 4, b = 8))
  )

# -------------------------------------------------------------
# 1. 要素一：偏心率 (Eccentricity ~100 ka)
# -------------------------------------------------------------
p1 <- ggplot() +
  # 轨道：近圆轨道 (低偏心率)
  geom_ellipse(aes(x0 = 0, y0 = 0, a = 3.5, b = 3.5, angle = 0), 
               color = "#415a77", linetype = "dashed", linewidth = 0.8) +
  # 轨道：椭圆轨道 (高偏心率，示意放大偏心程度)
  geom_ellipse(aes(x0 = -1.2, y0 = 0, a = 4.7, b = 3.0, angle = 0), 
               color = "#00b4d8", linewidth = 1.1) +
  # 太阳 (位于椭圆焦点)
  geom_point(aes(x = 0, y = 0), color = "#ffb703", size = 11) +
  geom_point(aes(x = 0, y = 0), color = "#fb8500", size = 7) +
  geom_text(aes(x = 0, y = -0.7, label = "太阳"), color = "#ffb703", size = 3.5, fontface = "bold") +
  # 近日点地球
  geom_point(aes(x = 3.5, y = 0), color = "#48cae4", size = 5) +
  geom_text(aes(x = 3.5, y = 0.8, label = "近日点\n(太阳辐射强)"), color = "#e0e1dd", size = 3, lineheight = 0.85) +
  # 远日点地球
  geom_point(aes(x = -5.9, y = 0), color = "#48cae4", size = 5) +
  geom_text(aes(x = -5.9, y = 0.8, label = "远日点\n(太阳辐射弱)"), color = "#e0e1dd", size = 3, lineheight = 0.85) +
  # 图例说明
  annotate("text", x = 0, y = -4.3, 
           label = "虚线：近圆轨道 (e ≈ 0.00005)\n实线：椭圆轨道 (e ≈ 0.0679)\n影响地球接收到的年总日照量", 
           color = "#a9d6e5", size = 2.9, lineheight = 1.1, hjust = 0.5) +
  coord_fixed(xlim = c(-6.8, 4.8), ylim = c(-5.2, 4.5)) +
  labs(
    title = "1. 偏心率 (Eccentricity)",
    subtitle = "轨道形状变化 ｜ 周期：约 10 万年"
  ) +
  dark_theme

# -------------------------------------------------------------
# 2. 要素二：地轴倾角 (Obliquity ~41 ka)
# -------------------------------------------------------------
# 地球本体及轴线
p2 <- ggplot() +
  # 太阳光照示意 (左侧为太阳)
  geom_point(aes(x = -5.5, y = 0), color = "#ffb703", size = 14) +
  geom_point(aes(x = -5.5, y = 0), color = "#fb8500", size = 9) +
  geom_text(aes(x = -5.5, y = -1.1, label = "太阳"), color = "#ffb703", size = 3.5, fontface = "bold") +
  # 阳光照射射线
  geom_segment(aes(x = -4.5, y = c(1, 0, -1), xend = -1.8, yend = c(1, 0, -1)),
               arrow = arrow(length = unit(0.2, "cm")), color = "#ffd166", linetype = "dotted", linewidth = 0.6) +
  # 地球球体
  geom_circle(aes(x0 = 0.5, y0 = 0, r = 1.6), fill = "#0077b6", color = "#90e0ef", linewidth = 1) +
  # 地球赤道
  geom_ellipse(aes(x0 = 0.5, y0 = 0, a = 1.6, b = 0.45, angle = 23.4), color = "white", linetype = "dotted", linewidth = 0.6) +
  # 垂直参考线
  geom_segment(aes(x = 0.5, y = -2.7, xend = 0.5, yend = 2.7), color = "gray50", linetype = "dashed", linewidth = 0.6) +
  geom_text(aes(x = 0.5, y = 3.0, label = "轨道面垂直线"), color = "gray60", size = 2.7) +
  # 最小倾角轴 (22.1°)
  geom_segment(aes(x = 0.5 - 2.8 * sin(22.1 * pi / 180), y = -2.8 * cos(22.1 * pi / 180),
                   xend = 0.5 + 2.8 * sin(22.1 * pi / 180), yend = 2.8 * cos(22.1 * pi / 180)),
               color = "#06d6a0", linewidth = 0.8, linetype = "dashed") +
  geom_text(aes(x = 0.5 + 2.9 * sin(22.1 * pi / 180) - 0.5, y = 2.8, label = "22.1° (弱季节差)"), 
            color = "#06d6a0", size = 2.6) +
  # 最大倾角轴 (24.5°)
  geom_segment(aes(x = 0.5 - 2.8 * sin(24.5 * pi / 180), y = -2.8 * cos(24.5 * pi / 180),
                   xend = 0.5 + 2.8 * sin(24.5 * pi / 180), yend = 2.8 * cos(24.5 * pi / 180)),
               color = "#ef476f", linewidth = 0.9) +
  geom_text(aes(x = 0.5 + 2.9 * sin(24.5 * pi / 180) + 0.6, y = 2.8, label = "24.5° (强季节差)"), 
            color = "#ef476f", size = 2.6) +
  # 摆动双向弧线
  annotate("text", x = 0.5, y = -3.7, 
           label = "倾角在 22.1° 至 24.5° 之间摆动 (现为 23.44°)\n倾角越大：高纬度地区冬夏反差越剧烈\n倾角越小：利于极地夏季冰雪维持与冰期形成", 
           color = "#a9d6e5", size = 2.9, lineheight = 1.1, hjust = 0.5) +
  coord_fixed(xlim = c(-6.8, 4.8), ylim = c(-5.2, 4.5)) +
  labs(
    title = "2. 地轴倾角 (Obliquity)",
    subtitle = "地轴倾斜角度 ｜ 周期：约 4.1 万年"
  ) +
  dark_theme

# -------------------------------------------------------------
# 3. 要素三：岁差 / 进动 (Precession ~2.3 ka)
# -------------------------------------------------------------
p3 <- ggplot() +
  # 顶部进动轨迹圆 (陀螺圆锥底面)
  geom_ellipse(aes(x0 = 0, y0 = 2.2, a = 1.4, b = 0.45, angle = 0), 
               color = "#f72585", linetype = "dashed", linewidth = 0.9) +
  geom_text(aes(x = 0, y = 3.1, label = "地轴进动轨迹 (像陀螺摆动)"), color = "#f72585", size = 2.8, fontface = "bold") +
  # 地球球体
  geom_circle(aes(x0 = 0, y0 = -0.5, r = 1.5), fill = "#0077b6", color = "#90e0ef", linewidth = 1) +
  # 进动圆锥中心垂直线
  geom_segment(aes(x = 0, y = -2.5, xend = 0, yend = 2.5), color = "gray50", linetype = "dotted", linewidth = 0.6) +
  # 状态 A 地轴 (指向织女星方向)
  geom_segment(aes(x = 0 - 1.4, y = 2.2, xend = 0 + 0.8, yend = -2.2),
               arrow = arrow(length = unit(0.18, "cm")), color = "#4cc9f0", linewidth = 0.9) +
  geom_text(aes(x = -1.9, y = 2.3, label = "约1.1万年前\n(指向织女星)"), color = "#4cc9f0", size = 2.6, lineheight = 0.85) +
  # 状态 B 地轴 (指向北极星方向 - 现代)
  geom_segment(aes(x = 0 + 1.4, y = 2.2, xend = 0 - 0.8, yend = -2.2),
               arrow = arrow(length = unit(0.18, "cm")), color = "#7209b7", linewidth = 0.9) +
  geom_text(aes(x = 1.9, y = 2.3, label = "现代\n(指向北极星)"), color = "#b5179e", size = 2.6, lineheight = 0.85) +
  # 太阳示意 (底部标示距离)
  geom_point(aes(x = 0, y = -4.4), color = "#ffb703", size = 8) +
  geom_text(aes(x = 0, y = -4.4, label = "太阳"), color = "#0d1b2a", size = 2.2, fontface = "bold") +
  # 说明文本
  annotate("text", x = 0, y = -3.5, 
           label = "地轴自转方向在空间中缓慢扫出圆锥\n改变地球在近日点/远日点时对应的季节\n直接影响两半球日照的季节性分配", 
           color = "#a9d6e5", size = 2.9, lineheight = 1.1, hjust = 0.5) +
  coord_fixed(xlim = c(-3.5, 3.5), ylim = c(-5.2, 4.5)) +
  labs(
    title = "3. 地轴岁差 (Precession)",
    subtitle = "地轴自转进动 ｜ 周期：约 1.9 ~ 2.4 万年"
  ) +
  dark_theme

# -------------------------------------------------------------
# 4. 拼图与总标题排版
# -------------------------------------------------------------
final_plot <- p1 + p2 + p3 +
  plot_layout(ncol = 3) +
  plot_annotation(
    title = "米兰科维奇循环三大天文要素示意图",
    subtitle = "三大轨道参数周期性叠加，驱动了地球地质历史上的冰期与间冰期循环交替",
    caption = "制图：基于 Milankovitch 轨道参数驱动理论",
    theme = theme(
      plot.background = element_rect(fill = "#0d1b2a", color = NA),
      plot.title = element_text(color = "#ffffff", size = 18, face = "bold", hjust = 0.5, margin = margin(t = 15, b = 5)),
      plot.subtitle = element_text(color = "#90e0ef", size = 11, hjust = 0.5, margin = margin(b = 15)),
      plot.caption = element_text(color = "#415a77", size = 9, hjust = 0.95, margin = margin(t = 10, b = 10))
    )
  )

# 显示图表 (建议导出比例为 15x7 英寸)
print(final_plot)
ggsave("../Figures/milankovitch_cycles.png", final_plot, width = 15, height = 7, dpi = 300)


library(palinsol)
library(ggplot2)
library(patchwork)

# 2. 设定时间序列：过去 1000 kyr (100 万年) 到现代 (0 kyr)，步长为 1 kyr
time_kyr <- seq(-1000, 0, by = 1)
# 转换为年 (以公元 1950 年为基准，单位为年)
time_years <- time_kyr * 1000

# 3. 计算三大米兰科维奇参数 (使用 Laskar 2004 解: la04)
# la04() 返回: [1] 偏心率 e, [2] 地轴倾角 eps (弧度), [3] 岁差角 varpi (弧度)
orbit_data <- sapply(time_years, function(t) la04(t))

df <- data.frame(
  Time_kyr     = time_kyr,
  Eccentricity = orbit_data[1, ],
  Obliquity    = orbit_data[2, ] * 180 / pi,               # 弧度转为角度 (度)
  Precession   = orbit_data[1, ] * sin(orbit_data[3, ])    # 岁差指数 e * sin(ϖ)
)

# 4. 分别绘制三条曲线
# 4.1 偏心率 (~10万年 / ~40万年周期)
p_ecc <- ggplot(df, aes(x = Time_kyr, y = Eccentricity)) +
  geom_line(color = "#1f77b4", linewidth = 0.7) +
  labs(title = "米兰科维奇循环三大参数 (Laskar 2004 解)",
       y = "偏心率 (Eccentricity)") +
  theme_minimal() +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank())

# 4.2 倾角 (~4.1万年周期)
p_obl <- ggplot(df, aes(x = Time_kyr, y = Obliquity)) +
  geom_line(color = "#2ca02c", linewidth = 0.7) +
  labs(y = "地轴倾角 (°)") +
  theme_minimal() +
  theme(axis.title.x = element_blank(), axis.text.x = element_blank())

# 4.3 岁差参数 (~2.3万年 / ~1.9万年周期)
p_prec <- ggplot(df, aes(x = Time_kyr, y = Precession)) +
  geom_line(color = "#d62728", linewidth = 0.7) +
  labs(x = "时间 (kyr，0 = 现代)", y = "岁差指数 (e·sin ϖ)") +
  theme_minimal()

# 5. 组合展示图表
ppp<-(p_ecc / p_obl / p_prec)
ggsave(ppp, filename="../Figures/milankovitch_cycles_curves.png", width=10, height=6)

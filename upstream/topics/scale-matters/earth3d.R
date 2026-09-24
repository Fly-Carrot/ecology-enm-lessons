# 安装并加载必要包
# install.packages(c("rgl", "maps", "htmlwidgets"))
library(rgl)
library(maps)
library(htmlwidgets)

# 关闭之前的绘图设备
close3d()

# -------------------------------------------------------------
# 1. 真实地球物理参数 (WGS84 基准，单位: km)
# -------------------------------------------------------------
a <- 6378.137  # 赤道长半轴 (半径)
b <- 6356.752  # 极地短半轴

# -------------------------------------------------------------
# 2. 构建 WGS84 椭球体网格
# -------------------------------------------------------------
n_lat <- 100
n_lon <- 200

lat <- seq(-pi / 2, pi / 2, length.out = n_lat)
lon <- seq(-pi, pi, length.out = n_lon)

grid_lat <- outer(lat, rep(1, n_lon))
grid_lon <- outer(rep(1, n_lat), lon)

X <- a * cos(grid_lat) * cos(grid_lon)
Y <- a * cos(grid_lat) * sin(grid_lon)
Z <- b * sin(grid_lat)

# -------------------------------------------------------------
# 3. 生成高清、明亮的全球地理地图贴图
# -------------------------------------------------------------
temp_tex <- tempfile(fileext = ".png")
# 使用高饱和、明亮的色彩
png(temp_tex, width = 2048, height = 1024, bg = "#29B6F6") # 明亮天蓝色海洋
par(mar = c(0, 0, 0, 0))
# 陆地采用清新绿色，边界用深绿色描边
map("world", fill = TRUE, col = "#81C784", bg = "#29B6F6", 
    border = "#2E7D32", lwd = 1.2, resolution = 0)
dev.off()

# -------------------------------------------------------------
# 4. 渲染 3D 场景
# -------------------------------------------------------------
open3d(windowRect = c(50, 50, 900, 900))
bg3d(color = "#0a0e17") # 深黑宇宙背景

# A. 绘制地球椭球体 (核心修改：lit = FALSE，color = "white")
# 这样贴图 360° 全方位 100% 明亮呈现，无任何发黑阴影
surface3d(
  x = X, y = Y, z = Z,
  color = "white",
  texture = temp_tex,
  smooth = TRUE,
  lit = FALSE
)

# B. 高亮金黄色赤道圈
theta_eq <- seq(-pi, pi, length.out = 300)
lines3d(
  x = (a + 20) * cos(theta_eq),
  y = (a + 20) * sin(theta_eq),
  z = 0,
  color = "#FFD600",
  lwd = 3.5,
  lit = FALSE
)

# C. 荧光红自转地轴
axis_len <- b + 1800
segments3d(
  x = c(0, 0), y = c(0, 0), z = c(-axis_len, axis_len),
  color = "#FF1744",
  lwd = 4,
  lit = FALSE
)
texts3d(0, 0, axis_len + 350, text = "北极 (North Pole)", color = "#FF5252", cex = 1.2)
texts3d(0, 0, -axis_len - 350, text = "南极 (South Pole)", color = "#FF5252", cex = 1.2)

# D. 荧光青色天宫空间站轨道 (高度 400 km)
orbit_r <- a + 400
inc <- 41.5 * pi / 180
orb_t <- seq(0, 2 * pi, length.out = 300)
orb_x <- orbit_r * cos(orb_t)
orb_y <- orbit_r * sin(orb_t) * cos(inc)
orb_z <- orbit_r * sin(orb_t) * sin(inc)

lines3d(orb_x, orb_y, orb_z, color = "#00E5FF", lwd = 2.5, lit = FALSE)

# 标记空间站位置与文字
points3d(orb_x[60], orb_y[60], orb_z[60], color = "#00E5FF", size = 10, lit = FALSE)
texts3d(orb_x[60] + 600, orb_y[60] + 600, orb_z[60] + 600, 
        text = "天宫空间站 (H = 400 km)", color = "#00E5FF", cex = 1.1)

# -------------------------------------------------------------
# 5. 设置视角
# -------------------------------------------------------------
view3d(theta = 35, phi = 25, zoom = 0.75)

# -------------------------------------------------------------
# 6. 在 RStudio Viewer 面板中输出
# -------------------------------------------------------------
rglwidget()
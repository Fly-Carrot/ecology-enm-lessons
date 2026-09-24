library(data.table)
library(ggplot2)
library(randomForest)
library(lavaan)
library(mgcv)

set.seed(2026)
n <- 1500

dt <- data.table(id = 1:n)

# 1. 基础特质与环境变量
dt[, literacy := rnorm(n, mean = 60, sd = 12)]          # 个人科学素养（最核心驱动）
dt[, lab_base := rnorm(n, mean = 50, sd = 15)]          # 实验室基础/平台资源
dt[, push_tolerance := runif(n, min = 0.2, max = 1.8)]  # 对push的容忍/适配度（异质性）
dt[, work_stamina := rnorm(n, mean = 50, sd = 10)]      # 个人工作习惯/耐受力上限

# 2. 中介机制：PI的Push与学生实际工作时长的复杂互动
dt[, pi_push := rnorm(n, mean = 50, sd = 10)]           # 导师的push程度
# 实际工作时长受个人耐受力、习惯、以及 (PI的push × 个人耐受度) 共同决定
dt[, effective_hours := 20 + 0.3 * work_stamina + 0.4 * (pi_push * push_tolerance) + rnorm(n, 0, 5)]
# 限制工作时长在合理现实区间 [25, 80]
dt[effective_hours < 25, effective_hours := 25]
dt[effective_hours > 80, effective_hours := 80]

# 3. 核心机制：非线性与交互作用影响最终的 IF 总数
# - 科学素养是绝对最重要的（系数大）
# - 实验室基础有作用，但边际递减
# - 工作时长呈现倒U型：适度工作有效，超过 65 小时后因过劳产生负面作用 (effective_hours - 65)^2
dt[, fatigue_penalty := pmax(0, effective_hours - 65)^2 * 0.15]
dt[, luck := rnorm(n, mean = 0, sd = 4)]                # 个人运气

# 真实科研产出（IF总数）方程
dt[, IF_total := 3.2 * literacy + 
     1.2 * lab_base + 
     0.8 * effective_hours - 
     fatigue_penalty + 
     0.5 * (literacy * push_tolerance / 20) + # 互动项：科学素养高的人更能把push转化为成果
     luck]

head(dt)


# 正确设定：引入工作时长的二次项（捕捉上限/负面作用）以及核心交互项
model_correct <- lm(IF_total ~ literacy + lab_base + effective_hours + I(effective_hours^2) + 
                      pi_push * push_tolerance + literacy:push_tolerance, data = dt)
summary(model_correct)

model_incorrect <- lm(IF_total ~ effective_hours + pi_push + lab_base, data = dt)
summary(model_incorrect)

# 使用随机森林处理复杂交互与非线性
set.seed(2026)
rf_model <- randomForest(IF_total ~ literacy + lab_base + effective_hours + pi_push + push_tolerance + work_stamina, 
                         data = dt, importance = TRUE)
importance(rf_model)
varImpPlot(rf_model)


# 错误：引入了一个泄露目标信息的衍生特征（例如：把带有总分信息的“局内评估分数”作为特征）
dt[, leakage_feature := IF_total + rnorm(n, 0, 0.5)]

rf_leak <- randomForest(IF_total ~ literacy + lab_base + leakage_feature, data = dt)
importance(rf_leak)


sem_code <- '
  # 路径设定
  effective_hours ~ a * pi_push + work_stamina
  IF_total ~ c_prime * literacy + b * effective_hours + lab_base
  
  # 间接效应与总效应定义
  indirect := a * b
'
fit_sem <- sem(sem_code, data = dt)
summary(fit_sem, standardized = TRUE, fit.measures = TRUE)

sem_wrong_code <- '
  lab_base ~ IF_total
  pi_push ~ IF_total
'
fit_wrong <- sem(sem_wrong_code, data = dt)
summary(fit_wrong, standardized = TRUE, fit.measures = TRUE)

# 1. 预测值对比：正确模型（带二次项） vs 错误模型（纯线性）
dt[, pred_correct := predict(model_correct, newdata = dt)]
dt[, pred_incorrect := predict(model_incorrect, newdata = dt)]

# 2. 绘制工作时长与IF的关系及模型拟合曲线
ggplot(dt, aes(x = effective_hours)) +
  geom_point(aes(y = IF_total), alpha = 0.3, color = "gray50") +
  geom_smooth(aes(y = IF_total, color = "真实生成趋势 (Nonlinear)"), method = "loess", se = FALSE, linewidth = 1.2) +
  geom_line(aes(y = pred_correct, color = "正确回归模型 (Quadratic)"), linetype = "dashed", linewidth = 1) +
  geom_line(aes(y = pred_incorrect, color = "错误线性模型 (Linear Bias)"), linetype = "dotted", linewidth = 1.2) +
  scale_color_manual(values = c("真实生成趋势 (Nonlinear)" = "black", 
                                "正确回归模型 (Quadratic)" = "blue", 
                                "错误线性模型 (Linear Bias)" = "red")) +
  theme_minimal() +
  labs(title = "工作时长对科研总IF的非线性影响与模型误判",
       subtitle = "真相：工作超过65小时后因疲劳出现边际效用下降（倒U型），错误线性模型（红线）无法识别",
       x = "有效工作时长 (Hours)", y = "科研总 IF",
       color = "曲线图例") +
  theme(legend.position = "bottom")

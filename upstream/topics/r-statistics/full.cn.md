# 统计学基础核心概念与推断原理全解

## 目录
1. [样本方差（Sample Variance）的统计学意义与贝塞尔修正](#1-样本方差sample-variance的统计学意义与贝塞尔修正)
2. [大数定律（LLN）与中心极限定理（CLT）](#2-大数定律lln与中心极限定理clt)
3. [假设检验、$p$ 值本质与样本量（n）依赖机制](#3-假设检验p-值本质与样本量n依赖机制)
4. [核心参数辨析：$\mu_0$ 与 $\mu_{\text{true}}$](#4-核心参数辨析mu_0-与-mu_texttrue)
5. [单样本 Student's $t$ 检验数学公式（分步与统一形式）](#5-单样本-students-t-检验数学公式分步与统一形式)
6. [正态独立双总体的假设检验（双样本 $t$ 检验）](#6-正态独立双总体的假设检验双样本-t-检验)
7. [成对相关数据的检验（配对 $t$ 检验）](#7-成对相关数据的检验配对-t-检验)
8. [点估计与区间估计（比例估计与 Wilson 置信区间）](#8-点估计与区间估计比例估计与-wilson-置信区间)
9. [相关、多元回归分析与单因素方差分析（OLS、模型指标与 ANOVA）](#9-相关多元回归分析与单因素方差分析ols模型指标与-anova)
10. [拟合优度检验、列联表、非参数检验与广义线性模型（GLM）](#10-拟合优度检验列联表非参数检验与广义线性模型glm)
11. [时间序列分析基础（自协方差、自相关函数 ACF 与 AR(1)）](#11-时间序列分析基础自协方差自相关函数-acf-与-ar1)

---

## 1. 样本方差（Sample Variance）的统计学意义与贝塞尔修正

### 1.1 核心意义
样本方差（记为 $s^2$）用来衡量样本观测值偏离其均值的离散程度与波动大小：
$$s^2 = \frac{1}{n - 1} \sum_{i=1}^n (x_i - \bar{x})^2$$

### 1.2 为什么除以 $n-1$ 而不是 $n$？（贝塞尔修正 Bessel's Correction）

1. **极小值性质导致的系统性偏小**：
   对于任意实数 $c$，二次和 $\sum(x_i - c)^2$ 在 $c = \bar{x}$ 处取得全局极小值。由于真实总体均值 $\mu$ 未知，我们用样本均值 $\bar{x}$ 替代 $\mu$：
   $$\sum_{i=1}^n (x_i - \bar{x})^2 \le \sum_{i=1}^n (x_i - \mu)^2$$
   如果直接除以 $n$，计算结果会系统性低估总体方差 $\sigma^2$。

2. **自由度损失**：
   在计算出样本均值 $\bar{x}$ 后，样本偏差满足硬性约束 $\sum_{i=1}^n (x_i - \bar{x}) = 0$。前 $n-1$ 个偏差确定后，最后 1 个偏差被完全锁定。有效独立信息量仅为 $n-1$。

3. **严格无偏性数学证明**：
   利用 $E[(x_i - \mu)^2] = \sigma^2$ 以及 $\text{Var}(\bar{x}) = E[(\bar{x} - \mu)^2] = \frac{\sigma^2}{n}$：
   $$x_i - \bar{x} = (x_i - \mu) - (\bar{x} - \mu)$$
   两边平方并求和：
   $$\sum_{i=1}^n (x_i - \bar{x})^2 = \sum_{i=1}^n (x_i - \mu)^2 - n(\bar{x} - \mu)^2$$
   两端取数学期望：
   $$E\left[ \sum_{i=1}^n (x_i - \bar{x})^2 \right] = n\sigma^2 - n \left(\frac{\sigma^2}{n}\right) = (n - 1)\sigma^2$$
   因此：
   $$E\left[ s^2 \right] = E\left[ \frac{1}{n - 1} \sum_{i=1}^n (x_i - \bar{x})^2 \right] = \sigma^2 \quad \text{（无偏估计）}$$

---

## 2. 大数定律（LLN）与中心极限定理（CLT）

### 2.1 随机变量代数性质
* **期望线性性质**：$E[aX + bY + c] = aE[X] + bE[Y] + c$
* **方差运算性质**：$\text{Var}(aX + b) = a^2 \text{Var}(X)$，$\text{Var}(X + Y) = \text{Var}(X) + \text{Var}(Y) + 2\text{Cov}(X, Y)$

### 2.2 弱大数定律（WLLN）
设 $X_1, \dots, X_n$ 独立同分布（i.i.d.），$E[X_i] = \mu$。对任意微小正数 $\epsilon > 0$：
$$\lim_{n \to \infty} P\left(|\bar{X}_n - \mu| \ge \epsilon\right) = 0$$
* **统计学意义**：赋予了样本均值作为点估计量的**一致性（Consistency）**——样本量足够大时，估计值无限逼近真值。

### 2.3 中心极限定理（CLT）
设 $X_1, \dots, X_n$ 独立同分布，无论总体原始分布形态如何，只要总体方差 $\sigma^2 < \infty$：
$$Z_n = \frac{\bar{X}_n - \mu}{\sigma / \sqrt{n}} \xrightarrow{d} N(0, 1) \quad (\text{当 } n \to \infty)$$
* **LLN 与 CLT 的本质区别**：LLN 阐明收敛的目标（点收敛至 $\mu$）；CLT 阐明波动的分布形态（误差服从钟形正态曲线，离散度以 $1/\sqrt{n}$ 速率收缩）。

---

## 3. 假设检验、$p$ 值本质与样本量（n）依赖机制

### 3.1 $p$ 值的数学定义
$p$ 值是一个**条件概率**，定义在**原假设 $H_0$ 为真**的前提下：
* **双尾检验**：$p = P\left(|T| \ge |t_{\text{obs}}| \mid H_0\right) = 2 \cdot [1 - F(|t_{\text{obs}}| \mid H_0)]$
* **单尾检验（右侧）**：$p = P\left(T \ge t_{\text{obs}} \mid H_0\right) = 1 - F(t_{\text{obs}} \mid H_0)$

### 3.2 与样本量 $n$ 的传导放大机制
以单样本检验统计量为例：
$$t_{\text{obs}} = \frac{\bar{x} - \mu_0}{SE_{\bar{x}}} = \frac{\bar{x} - \mu_0}{s / \sqrt{n}} = \left(\frac{\bar{x} - \mu_0}{s}\right) \cdot \sqrt{n}$$
* **标准误衰减**：$SE$ 随 $\sqrt{n}$ 递减。
* **统计量膨胀**：只要真实效应量 $\mu - \mu_0 \ne 0$，随着 $n \to \infty$，统计量 $t_{\text{obs}} \to \infty$。
* **$p$ 值被压缩至 0**：$\lim_{n \to \infty} p = 0$。
* **实际影响**：
  * **大样本（Overpowered）**：极微小且无科学实际意义的差异都会产生极小的 $p$ 值（$p < 0.001$）。**统计学显著不等于科学或业务重要性**。
  * **小样本（Underpowered）**：标准误过大，导致真实的强效应也可能出现 $p > 0.05$（引发第二类错误 $\beta$）。

---

## 4. 核心参数辨析：$\mu_0$ 与 $\mu_{\text{true}}$

| 参数名称 | 统计学定义 | 现实属性 | 在模拟/代码中的用途 |
| :--- | :--- | :--- | :--- |
| **$\mu_0$ (原假设均值)** | 研究者设定的参考靶值/理论基准（如 $H_0: \mu = \mu_0$） | 已知的人工设定标准 | 用于构建检验统计量的偏离度：$(\bar{x} - \mu_0)$ |
| **$\mu_{\text{true}}$ (真实总体均值)** | 数据生成机制背后的客观真值（Ground Truth） | 未知且不可直接观测的物理客观值 | 在 Monte Carlo 模拟中充当参数生成样本数据（如 `rnorm(n, mu_true)`） |

* **效应量（Effect Size）**：$\Delta = \mu_{\text{true}} - \mu_0$。当 $\Delta = 0$ 时检验拒绝 $H_0$ 为第一类错误；当 $\Delta \ne 0$ 时 $H_0$ 本身错误，检验目标是确保有足够的检验功效（Power = $1-\beta$）将其检出。

---

## 5. 单样本 Student's $t$ 检验数学公式（分步与统一形式）

### 5.1 分步计算公式（对应 R 代码实现）

1. **样本均值（`x_bar <- mean(x)`）**：
   $$\bar{x} = \frac{1}{n} \sum_{i=1}^n x_i$$

2. **均值标准误（`se <- sd(x) / sqrt(n)`）**：
   $$SE_{\bar{x}} = \frac{s}{\sqrt{n}} = \frac{1}{\sqrt{n}} \sqrt{\frac{1}{n - 1} \sum_{i=1}^n (x_i - \bar{x})^2}$$

3. **$t$ 检验统计量（`t_val <- (x_bar - mu_0) / se`）**：
   $$t = \frac{\bar{x} - \mu_0}{SE_{\bar{x}}} = \frac{\bar{x} - \mu_0}{s / \sqrt{n}}$$

4. **双尾 $p$ 值（`p_val <- 2 * (1 - pt(abs(t_val), df = n - 1))`）**：
   $$p = 2 \cdot \left[ 1 - F_{t}\left( |t|, \, \nu = n - 1 \right) \right] = 2 \cdot \int_{|t|}^{+\infty} f_{t}(u; \, n - 1) \, du$$
   *其中 $F_t(\cdot)$ 为自由度 $\nu = n - 1$ 的 Student's $t$ 分布累积分布函数（即 R 中的 `pt()` 函数）。*

---

### 5.2 闭式统一解析公式（Full Unified Formula）

将上述所有分步代数式整合为一个统一表达式，双尾 $p$ 值的完整解析形式为：

$$p = 2 \cdot \left[ 1 - F_{t}\left( \left| \frac{\left( \frac{1}{n}\sum_{i=1}^n x_i \right) - \mu_0}{\sqrt{\frac{1}{n(n - 1)} \sum_{i=1}^n \left( x_i - \frac{1}{n}\sum_{j=1}^n x_j \right)^2}} \right|, \, \nu = n - 1 \right) \right]$$



## 6. 正态独立双总体的假设检验（双样本 $t$ 检验）

### 6.1 统计学背景与场景辨析
用于检验两个相互独立的总体均值是否存在显著差异（$H_0: \mu_1 - \mu_2 = 0$）。
* **方差齐性（Equal Variance assumed）**：使用合并方差（Pooled Variance）Student's $t$ 检验。
* **方差不齐（Unequal Variance）**：使用 Welch's $t$ 检验，通过 Welch-Satterthwaite 方程修正自由度。

### 6.2 分步计算公式

#### 情况 A：方差齐性（Pooled $t$-test）
1. **组均值与样本方差：**
   $$\bar{x}_1 = \frac{1}{n_1} \sum_{i=1}^{n_1} x_{1i}, \quad s_1^2 = \frac{1}{n_1 - 1} \sum_{i=1}^{n_1} (x_{1i} - \bar{x}_1)^2$$
   $$\bar{x}_2 = \frac{1}{n_2} \sum_{j=1}^{n_2} x_{2j}, \quad s_2^2 = \frac{1}{n_2 - 1} \sum_{j=1}^{n_2} (x_{2j} - \bar{x}_2)^2$$

2. **合并方差估计量（Pooled Variance）：**
   $$s_p^2 = \frac{(n_1 - 1)s_1^2 + (n_2 - 1)s_2^2}{n_1 + n_2 - 2}$$

3. **均值差标准误：**
   $$SE_{\text{pooled}} = \sqrt{s_p^2 \left( \frac{1}{n_1} + \frac{1}{n_2} \right)}$$

4. **$t$ 统计量与自由度：**
   $$t_{\text{pooled}} = \frac{\bar{x}_1 - \bar{x}_2}{SE_{\text{pooled}}}, \quad \nu_{\text{pooled}} = n_1 + n_2 - 2$$

5. **双尾 $p$ 值：**
   $$p = 2 \cdot \left[ 1 - F_t\left( |t_{\text{pooled}}|, \, \nu = \nu_{\text{pooled}} \right) \right]$$

#### 情况 B：方差不齐（Welch's $t$-test）
1. **未合并标准误：**
   $$SE_{\text{welch}} = \sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}$$

2. **Welch $t$ 统计量：**
   $$t_{\text{welch}} = \frac{\bar{x}_1 - \bar{x}_2}{\sqrt{\frac{s_1^2}{n_1} + \frac{s_2^2}{n_2}}}$$

3. **Welch-Satterthwaite 调整自由度：**
   $$\nu_{\text{welch}} = \frac{\left( \frac{s_1^2}{n_1} + \frac{s_2^2}{n_2} \right)^2}{\frac{(s_1^2 / n_1)^2}{n_1 - 1} + \frac{(s_2^2 / n_2)^2}{n_2 - 1}}$$

4. **双尾 $p$ 值：**
   $$p = 2 \cdot \left[ 1 - F_t\left( |t_{\text{welch}}|, \, \nu = \nu_{\text{welch}} \right) \right]$$

### 6.3 统一闭式公式（Welch's $t$-test）
$$p = 2 \cdot \left[ 1 - F_t\left( \left| \frac{\bar{x}_1 - \bar{x}_2}{\sqrt{\frac{\sum_{i=1}^{n_1}(x_{1i}-\bar{x}_1)^2}{n_1(n_1-1)} + \frac{\sum_{j=1}^{n_2}(x_{2j}-\bar{x}_2)^2}{n_2(n_2-1)}}} \right|, \, \nu = \frac{\left( \frac{s_1^2}{n_1} + \frac{s_2^2}{n_2} \right)^2}{\frac{s_1^4}{n_1^2(n_1-1)} + \frac{s_2^4}{n_2^2(n_2-1)}} \right) \right]$$

---

## 7. 成对相关数据的检验（配对 $t$ 检验）

### 7.1 统计学背景与场景辨析
当数据为同一受试对象的前后测量（Matched pairs / Pre-post）时，由于两组观测存在内在相关性，不能使用独立双样本检验。配对检验的核心是通过差分运算将二维配对问题降维为一维单样本检验。

### 7.2 分步计算公式
1. **样本差分（Difference Calculation）：**
   $$d_i = x_{1i} - x_{2i}, \quad i = 1, 2, \dots, n$$

2. **差分均值与差分标准差：**
   $$\bar{d} = \frac{1}{n} \sum_{i=1}^n d_i, \quad s_d = \sqrt{\frac{1}{n - 1} \sum_{i=1}^n (d_i - \bar{d})^2}$$

3. **差分标准误：**
   $$SE_{\bar{d}} = \frac{s_d}{\sqrt{n}}$$

4. **配对 $t$ 统计量：**
   $$t_{\text{paired}} = \frac{\bar{d} - \mu_d}{SE_{\bar{d}}} \quad (\text{通常 } H_0: \mu_d = 0)$$

5. **双尾 $p$ 值：**
   $$p = 2 \cdot \left[ 1 - F_t\left( |t_{\text{paired}}|, \, \nu = n - 1 \right) \right]$$

### 7.3 统一闭式公式
$$p = 2 \cdot \left[ 1 - F_t\left( \left| \frac{\frac{1}{n}\sum_{i=1}^n (x_{1i} - x_{2i})}{\sqrt{\frac{1}{n(n-1)}\sum_{i=1}^n \left( (x_{1i}-x_{2i}) - \frac{1}{n}\sum_{j=1}^n (x_{1j}-x_{2j}) \right)^2}} \right|, \, \nu = n - 1 \right) \right]$$

---

## 8. 点估计与区间估计（比例估计与 Wilson 置信区间）

### 8.1 统计学背景与场景辨析
在二项分布试验中（$n$ 次试验成功 $x$ 次），点估计量为样本比例 $\hat{p} = x/n$。
* **Wald 区间**：基于渐近正态近似，在极小样本或边界值（$p \approx 0$ 或 $1$）时覆盖率严重失真。
* **Wilson 得分区间（Wilson Score Interval）**：对二项方差进行中心矫正，小样本下稳健性更好。

### 8.2 分步计算公式
1. **点估计量（Point Estimator）：**
   $$\hat{p} = \frac{x}{n}$$

2. **临界值（Critical Z-score）：**
   $$z = \Phi^{-1}\left(1 - \frac{\alpha}{2}\right)$$

3. **Wilson 调整中心点（Adjusted Center）：**
   $$\tilde{p}_{\text{center}} = \frac{\hat{p} + \frac{z^2}{2n}}{1 + \frac{z^2}{n}}$$

4. **Wilson 误差界（Margin of Error）：**
   $$\text{ME}_{\text{wilson}} = \frac{z \sqrt{\frac{\hat{p}(1 - \hat{p})}{n} + \frac{z^2}{4n^2}}}{1 + \frac{z^2}{n}}$$

5. **置信区间上下限：**
   $$\text{CI}_{\text{lower}} = \tilde{p}_{\text{center}} - \text{ME}_{\text{wilson}}, \quad \text{CI}_{\text{upper}} = \tilde{p}_{\text{center}} + \text{ME}_{\text{wilson}}$$

### 8.3 统一闭式公式
$$\text{CI}_{1-\alpha} = \frac{\hat{p} + \frac{z^2}{2n} \pm z\sqrt{\frac{\hat{p}(1-\hat{p})}{n} + \frac{z^2}{4n^2}}}{1 + \frac{z^2}{n}}$$

---

## 9. 相关、多元回归分析与单因素方差分析（OLS、模型指标与 ANOVA）

### 9.1 统计学背景与场景辨析
* **因变量 ($Y$)**：预测目标。
* **自变量 ($X$)**：核心解释变量。
* **控制变量 ($Z$)**：排除混杂偏误的伴随协变量。
* **模型评估矩阵**：
  * $R^2$：总体解释方差比。
  * $\text{Adjusted } R^2$：引入自变量惩罚项。
  * $\text{Within } R^2$：面板去均值后（Fixed Effects）个体内部变异解释度。
  * $\text{RMSE} / \text{MAE}$：预测绝对误差指标。
  * $\text{AIC} / \text{AICc}$：似然度与参数复杂度权衡。

### 9.2 分步计算公式

#### Part 1: Pearson 相关系数
$$r = \frac{\sum_{i=1}^n (x_i - \bar{x})(y_i - \bar{y})}{\sqrt{\sum_{i=1}^n (x_i - \bar{x})^2} \sqrt{\sum_{i=1}^n (y_i - \bar{y})^2}}$$

#### Part 2: 多元线性回归（OLS 矩阵解）与残差
1. **参数估计向量：**
   $$\hat{\boldsymbol{\beta}} = (\mathbf{X}^T \mathbf{X})^{-1} \mathbf{X}^T \mathbf{y}$$
2. **拟合值与残差向量：**
   $$\hat{\mathbf{y}} = \mathbf{X}\hat{\boldsymbol{\beta}}, \quad \mathbf{e} = \mathbf{y} - \hat{\mathbf{y}}$$
3. **平方和分解：**
   $$SS_{\text{tot}} = \sum_{i=1}^n (y_i - \bar{y})^2, \quad SS_{\text{res}} = \sum_{i=1}^n e_i^2 = \mathbf{e}^T\mathbf{e}$$

#### Part 3: 模型评价指标体系
1. **判定系数 $R^2$ 与校正系数 $\text{Adj-}R^2$：**
   $$R^2 = 1 - \frac{SS_{\text{res}}}{SS_{\text{tot}}}, \quad R^2_{\text{adj}} = 1 - \left[ \frac{SS_{\text{res}} / (n - k - 1)}{SS_{\text{tot}} / (n - 1)} \right]$$
2. **固定效应组内解释度 $\text{Within } R^2$（去均值法）：**
   $$\tilde{y}_{it} = y_{it} - \bar{y}_i, \quad \tilde{x}_{it} = x_{it} - \bar{x}_i \implies \text{Within } R^2 = 1 - \frac{\sum ( \tilde{y}_{it} - \tilde{x}_{it}\hat{\beta}_{\text{fe}} )^2}{\sum \tilde{y}_{it}^2}$$
3. **RMSE 与 MAE：**
   $$\text{RMSE} = \sqrt{\frac{1}{n}\sum_{i=1}^n e_i^2}, \quad \text{MAE} = \frac{1}{n}\sum_{i=1}^n |e_i|$$
4. **对数似然与 AICc（小样本校正）：**
   $$\ln L = -\frac{n}{2}\ln(2\pi) - \frac{n}{2}\ln\left(\frac{SS_{\text{res}}}{n}\right) - \frac{n}{2}$$
   $$\text{AIC} = 2(k+2) - 2\ln L, \quad \text{AICc} = \text{AIC} + \frac{2(k+2)(k+3)}{n - (k+2) - 1}$$
   *(其中 $k$ 为自变量数，$+2$ 对应截距项与误差方差 $\sigma^2$)*

#### Part 4: 单因素方差分析（One-Way ANOVA）
1. **组间平方和（SSB）与组内平方和（SSW）：**
   $$SSB = \sum_{j=1}^K n_j (\bar{y}_{\cdot j} - \bar{y}_{\cdot\cdot})^2, \quad SSW = \sum_{j=1}^K \sum_{i=1}^{n_j} (y_{ij} - \bar{y}_{\cdot j})^2$$
2. **均方与 $F$ 检验统计量：**
   $$MSB = \frac{SSB}{K - 1}, \quad MSW = \frac{SSW}{n - K}, \quad F = \frac{MSB}{MSW}$$
3. **$p$ 值：**
   $$p = 1 - F_F(F, \, df_1 = K - 1, \, df_2 = n - K)$$

---

## 10. 拟合优度检验、列联表、非参数检验与广义线性模型（GLM）

### 10.1 统计学背景与场景辨析
* **卡方独立性检验**：检验二维分类列联表行列变量的相关性。
* **Wilcoxon 秩和检验**：总体非正态连续分布时的两样本中位数位置检验。
* **GLM 逻辑回归**：因变量服从二项分布，通过 Logit 链接函数 $g(p) = \ln(\frac{p}{1-p}) = \mathbf{X}\boldsymbol{\beta}$，采用迭代加权最小二乘（IRLS）求解。

### 10.2 分步计算公式

#### Part 1: 卡方独立性检验（Chi-Square Test）
1. **期望频数矩阵：**
   $$E_{ij} = \frac{R_i \cdot C_j}{N}$$
2. **卡方统计量：**
   $$\chi^2 = \sum_{i=1}^r \sum_{j=1}^c \frac{(O_{ij} - E_{ij})^2}{E_{ij}}$$
3. **$p$ 值（自由度 $\nu = (r-1)(c-1)$）：**
   $$p = 1 - F_{\chi^2}\left(\chi^2, \, df = (r-1)(c-1)\right)$$

#### Part 2: 非参数 Wilcoxon 秩和检验（Mann-Whitney $U$）
1. **联合升序排名并求秩和：**
   $$W_1 = \sum_{i \in \text{Group 1}} \text{Rank}(x_{1i})$$
2. **Mann-Whitney $U$ 统计量：**
   $$U_1 = W_1 - \frac{n_1(n_1 + 1)}{2}$$

#### Part 3: GLM Logistic 回归（牛顿-拉夫逊 / IRLS 算法）
1. **Logit 映射与发生概率：**
   $$p_i = \frac{1}{1 + e^{-\mathbf{x}_i^T \boldsymbol{\beta}}}$$
2. **对角权重矩阵与工作变量：**
   $$\mathbf{W} = \text{diag}(p_i(1 - p_i)), \quad \mathbf{g} = \mathbf{X}^T (\mathbf{y} - \mathbf{p})$$
3. **参数迭代更新（Newton-Raphson Step）：**
   $$\boldsymbol{\beta}^{(t+1)} = \boldsymbol{\beta}^{(t)} + \left( \mathbf{X}^T \mathbf{W}^{(t)} \mathbf{X} \right)^{-1} \mathbf{X}^T (\mathbf{y} - \mathbf{p}^{(t)})$$

---

## 11. 时间序列分析基础（自协方差、自相关函数 ACF 与 AR(1)）

### 11.1 统计学背景与场景辨析
时间序列数据具有时间依赖性（自相关性），违反经典统计假设。核心分析工具包括衡量不同滞后阶数（Lag）相关性的自相关函数（ACF）以及一阶自回归过程 AR(1) 参数估计。

### 11.2 分步计算公式
1. **样本序列均值：**
   $$\bar{y} = \frac{1}{n} \sum_{t=1}^n y_t$$

2. **滞后 $k$ 阶样本自协方差（Sample Autocovariance $\gamma_k$）：**
   $$\hat{\gamma}_k = \frac{1}{n} \sum_{t=1}^{n-k} (y_t - \bar{y})(y_{t+k} - \bar{y}), \quad k = 0, 1, 2, \dots$$

3. **滞后 $k$ 阶样本自相关系数（ACF $\rho_k$）：**
   $$\hat{\rho}_k = \frac{\hat{\gamma}_k}{\hat{\gamma}_0} = \frac{\sum_{t=1}^{n-k} (y_t - \bar{y})(y_{t+k} - \bar{y})}{\sum_{t=1}^n (y_t - \bar{y})^2}$$

4. **AR(1) 模型与 Yule-Walker 方程估计量：**
   $$y_t = \phi y_{t-1} + \epsilon_t \implies \hat{\phi}_{\text{YW}} = \hat{\rho}_1 = \frac{\hat{\gamma}_1}{\hat{\gamma}_0}$$

### 11.3 统一闭式公式（Lag-1 ACF / AR(1) 估计量）
$$\hat{\phi}_{\text{YW}} = \hat{\rho}_1 = \frac{\sum_{t=1}^{n-1} \left( y_t - \frac{1}{n}\sum_{i=1}^n y_i \right)\left( y_{t+1} - \frac{1}{n}\sum_{i=1}^n y_i \right)}{\sum_{t=1}^n \left( y_t - \frac{1}{n}\sum_{i=1}^n y_i \right)^2}$$
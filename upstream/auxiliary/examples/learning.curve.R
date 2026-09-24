library(data.table)
library(ggplot2)

time_seq <- seq(0, 100, length.out = 500)

# Curve 1: Script-based (Logistic)
L1 <- 100
k1 <- 0.15
x01 <- 40
y_script <- L1 / (1 + exp(-k1 * (time_seq - x01)))

# Curve 2: GUI-based (Negative Exponential / Monod type)
L2 <- 40
k2 <- 0.08
y_gui <- L2 * (1 - exp(-k2 * time_seq))

dt_curves <- data.table(
  Time = rep(time_seq, 2),
  Achievement = c(y_script, y_gui),
  Approach = rep(c("Script-based (e.g., R / Python)", "GUI-based Tools"), each = length(time_seq))
)

dt_stages <- data.table(
  Time = c(18, 48, 72, 92),
  Career_Stage = c("Master's Student", "PhD Candidate", "Early-career Scientist", "Senior Scientist"),
  Annotation = c(
    "",
    "",
    "",
    ""
  ),
  Y_Pos = c(75, 82, 85, 88)
)

p <- ggplot() +
  geom_vline(
    data = dt_stages,
    aes(xintercept = Time),
    linetype = "dashed",
    color = "grey65",
    linewidth = 0.7
  ) +
  geom_text(
    data = dt_stages,
    aes(x = Time, y = Y_Pos, label = paste0(Career_Stage, "\n—\n", Annotation)),
    size = 3.3,
    lineheight = 0.9,
    color = "grey25",
    vjust = 1,
    nudge_x = 1.2,
    hjust = 0
  ) +
  geom_line(
    data = dt_curves,
    aes(x = Time, y = Achievement, color = Approach, linetype = Approach),
    linewidth = 1.3
  ) +
  scale_color_manual(
    values = c(
      "Script-based (e.g., R / Python)" = "#1B7837",
      "GUI-based Tools" = "#762A83"
    )
  ) +
  scale_linetype_manual(
    values = c(
      "Script-based (e.g., R / Python)" = "solid",
      "GUI-based Tools" = "longdash"
    )
  ) +
  scale_x_continuous(
    limits = c(0, 115),
    breaks = seq(0, 100, by = 20),
    expand = expansion(mult = c(0.01, 0.02))
  ) +
  scale_y_continuous(
    limits = c(0, 105),
    breaks = seq(0, 100, by = 20),
    expand = expansion(mult = c(0.01, 0.05))
  ) +
  labs(
    title = "Learning Curves: Script-Driven vs. GUI-Based Scientific Analysis",
    x = "Time & Effort Invested",
    y = "Analytical Capability & Productivity",
    color = "Approach",
    linetype = "Approach"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, margin = margin(b = 6)),
    plot.subtitle = element_text(color = "grey30", size = 11, margin = margin(b = 15)),
    legend.position = "top",
    legend.justification = "left",
    legend.title = element_blank(),
    legend.text = element_text(size = 10, face = "bold"),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.line = element_line(color = "grey30", linewidth = 0.6)
  )

print(p)
ggsave(p, filename="../Figures/learning_curve.png", width=12, height=6)

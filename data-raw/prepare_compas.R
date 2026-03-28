# Simulated COMPAS-like recidivism prediction dataset
# Based on published statistics from ProPublica (2016)
set.seed(20160523)
n <- 1000
race <- sample(c("White", "Black"), n, replace = TRUE, prob = c(0.4, 0.6))
# Systematic bias: higher risk scores for Black defendants
base_risk <- ifelse(race == "Black", runif(n, 0.3, 0.8), runif(n, 0.15, 0.65))
actual_recid <- rbinom(n, 1, 0.45)
# Add noise correlated with actual outcome
risk_score <- pmin(1, pmax(0, base_risk + (actual_recid - 0.5) * 0.3 + rnorm(n, 0, 0.1)))
compas_sim <- data.frame(
  risk_score = round(risk_score, 4),
  recidivism = actual_recid,
  race = race,
  stringsAsFactors = FALSE
)
save(compas_sim, file = "data/compas_sim.rda", compress = "xz")
cat("compas_sim:", nrow(compas_sim), "rows\n")

metric_data <- function() {
  data.frame(
    obs = c(0.10, 0.40, -0.20, 0.90, 0.30, 0.55),
    pred = c(0.20, 0.30, 0.00, 0.10, 0.35, 0.50),
    v = c(0.01, 0.04, 0.02, 0.04, 0.03, 0.02),
    grp = rep(c("a", "b"), each = 3)
  )
}

test_that("inverse_var_rmse() is a weighted RMSE", {
  d <- metric_data()
  w <- 1 / d$v
  expected <- sqrt(sum(w * (d$obs - d$pred)^2) / sum(w))
  expect_equal(inverse_var_rmse_vec(d$obs, d$pred, variance = d$v),
               expected)
  res <- inverse_var_rmse(d, obs, pred, variance = v)
  expect_s3_class(res, "tbl_df")
  expect_identical(res$.metric, "inverse_var_rmse")
  expect_identical(res$.estimator, "standard")
  expect_equal(res$.estimate, expected)
  expect_identical(attr(inverse_var_rmse, "direction"), "minimize")
  grouped <- inverse_var_rmse(dplyr::group_by(d, grp), obs, pred,
                              variance = v)
  expect_equal(nrow(grouped), 2)
  # Equal variances give the ordinary RMSE
  expect_equal(inverse_var_rmse_vec(d$obs, d$pred, variance = rep(1, 6)),
               yardstick::rmse_vec(d$obs, d$pred))
})

test_that("inverse_var_rmse() uses case weights and handles NA", {
  skip_if_not_installed("hardhat")
  d <- metric_data()
  d$w <- hardhat::importance_weights(1 / d$v)
  expect_equal(inverse_var_rmse(d, obs, pred, case_weights = w)$.estimate,
               inverse_var_rmse_vec(d$obs, d$pred, variance = d$v))
  ms <- yardstick::metric_set(inverse_var_rmse, yardstick::rmse)
  res <- ms(d, truth = obs, estimate = pred, case_weights = w)
  expect_equal(nrow(res), 2)
  d$pred[1] <- NA
  expect_equal(inverse_var_rmse_vec(d$obs, d$pred, variance = d$v),
               inverse_var_rmse_vec(d$obs[-1], d$pred[-1],
                                    variance = d$v[-1]))
  expect_true(is.na(inverse_var_rmse_vec(d$obs, d$pred, variance = d$v,
                                         na_rm = FALSE)))
  expect_error(inverse_var_rmse_vec(d$obs, d$pred), "weights are needed")
  expect_error(inverse_var_rmse_vec(1:2, 1:2, variance = c(1, -1)),
               "positive")
})

test_that("coverage_prob() counts observations inside the intervals", {
  d <- metric_data()
  se <- sqrt(d$v)
  inside <- abs(d$obs - d$pred) <= stats::qnorm(0.975) * se
  expect_equal(coverage_prob_vec(d$obs, d$pred, std_error = se),
               mean(inside))
  d$se <- se
  res <- coverage_prob(d, obs, pred, std_error = se, level = 0.5)
  inside50 <- abs(d$obs - d$pred) <= stats::qnorm(0.75) * se
  expect_equal(res$.estimate, mean(inside50))
  expect_identical(res$.metric, "coverage_prob")
  expect_identical(attr(coverage_prob, "direction"), "maximize")
  expect_error(coverage_prob_vec(d$obs, d$pred, std_error = 1),
               "one value per prediction")
  expect_error(coverage_prob_vec(d$obs, d$pred, std_error = se,
                                 level = 1.2), "between 0 and 1")
})

test_that("heterogeneity_r2() compares residual and total tau2", {
  es <- meta_effect_size(bcg_trials, "RR", event1 = tpos,
                         n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg)
  fit <- meta_regress(es, ~ ablat, method = "DL")
  es$pred <- predict(fit, newdata = es)$.pred
  r2 <- heterogeneity_r2_vec(es$.yi, es$pred, variance = es$.vi)
  w <- 1 / es$.vi
  k <- nrow(es)
  mu <- sum(w * es$.yi) / sum(w)
  tau0 <- (sum(w * (es$.yi - mu)^2) - (k - 1)) /
    (sum(w) - sum(w^2) / sum(w))
  taur <- max(0, (sum(w * (es$.yi - es$pred)^2) - (k - 1)) /
                (sum(w) - sum(w^2) / sum(w)))
  expect_equal(r2, max(0, 1 - taur / tau0))
  expect_true(r2 > 0.5 && r2 <= 1)
  # Predicting the pooled mean explains nothing
  expect_equal(heterogeneity_r2_vec(es$.yi, rep(mu, k), variance = es$.vi),
               0)
  res <- heterogeneity_r2(es, .yi, pred, variance = .vi)
  expect_equal(res$.estimate, r2)
  expect_warning(
    h <- heterogeneity_r2_vec(c(0.1, 0.1, 0.1), c(0, 0, 0),
                              variance = c(1, 1, 1)),
    "no between-study heterogeneity"
  )
  expect_true(is.na(h))
  expect_error(heterogeneity_r2_vec(es$.yi, es$pred, variance = es$.vi,
                                    case_weights = w), "case weights")
})

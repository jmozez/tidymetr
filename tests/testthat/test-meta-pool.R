bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}
`%||%` <- function(x, y) if (is.null(x)) y else x
tight <- list(threshold = 1e-12, tol = 1e-12, maxiter = 5000)

test_that("every estimator matches metafor::rma()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  for (m in c("FE", "DL", "REML", "ML", "PM", "SJ")) {
    for (t in c("z", "hksj")) {
      fit <- meta_pool(es, method = m, test = t)
      ref <- suppressWarnings(metafor::rma(
        es$.yi, es$.vi, method = if (m == "FE") "EE" else m,
        test = if (t == "hksj") "knha" else "z", control = tight
      ))
      g <- glance(fit)
      pr <- predict(ref)
      expect_equal(fit$estimate, c(ref$beta), tolerance = 1e-6,
                   info = paste(m, t))
      expect_equal(fit$std.error, ref$se, tolerance = 1e-6)
      expect_equal(fit$p.value, ref$pval, tolerance = 1e-6)
      expect_equal(fit$conf.low, ref$ci.lb, tolerance = 1e-6)
      expect_equal(g$tau2, ref$tau2, tolerance = 1e-6)
      expect_equal(g$I2, ref$I2, tolerance = 1e-6)
      expect_equal(g$H2, ref$H2, tolerance = 1e-6)
      expect_equal(g$QE, ref$QE, tolerance = 1e-8)
      expect_equal(g$pred.low, as.vector(pr$pi.lb %||% pr$ci.lb),
                   tolerance = 1e-6)
      expect_equal(g$pred.high, as.vector(pr$pi.ub %||% pr$ci.ub),
                   tolerance = 1e-6)
    }
  }
})

test_that("Q-profile intervals, likelihoods and se(tau2) match metafor", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  fit <- meta_pool(es)
  ref <- metafor::rma(es$.yi, es$.vi, control = tight)
  ci <- stats::confint(ref, control = list(tol = 1e-10))
  g <- glance(fit)
  expect_equal(g$tau2.low, ci$random[1, 2], tolerance = 1e-5)
  expect_equal(g$tau2.high, ci$random[1, 3], tolerance = 1e-5)
  expect_equal(g$logLik, c(stats::logLik(ref)), tolerance = 1e-8)
  expect_equal(g$AIC, stats::AIC(ref), tolerance = 1e-8)
  expect_equal(g$BIC, stats::BIC(ref), tolerance = 1e-8)
  ml <- meta_pool(es, method = "ML")
  ref_ml <- metafor::rma(es$.yi, es$.vi, method = "ML", control = tight)
  expect_equal(glance(ml)$logLik, c(stats::logLik(ref_ml)),
               tolerance = 1e-8)
})

test_that("DerSimonian-Laird matches the closed form", {
  es <- bcg_es()
  w <- 1 / es$.vi
  mu_fe <- sum(w * es$.yi) / sum(w)
  q <- sum(w * (es$.yi - mu_fe)^2)
  tau2 <- max(0, (q - 12) / (sum(w) - sum(w^2) / sum(w)))
  ws <- 1 / (es$.vi + tau2)
  fit <- meta_pool(es, method = "DL")
  expect_equal(glance(fit)$tau2, tau2)
  expect_equal(fit$estimate, sum(ws * es$.yi) / sum(ws))
  expect_equal(fit$std.error, sqrt(1 / sum(ws)))
  fe <- meta_pool(es, method = "common")
  expect_equal(fe$estimate, mu_fe)
  expect_equal(glance(fe)$tau2, 0)
})

test_that("homogeneous data give tau2 = 0", {
  dat <- data.frame(y = c(0.20, 0.21, 0.19, 0.20), v = rep(0.04, 4))
  for (m in c("REML", "ML", "DL", "PM")) {
    expect_equal(glance(meta_pool(dat, yi = y, vi = v, method = m))$tau2, 0)
  }
})

test_that("meta_pool() works with plain data frames and study labels", {
  dat <- data.frame(lab = letters[1:4], y = c(0.1, 0.5, 0.3, 0.2),
                    v = c(0.01, 0.02, 0.015, 0.03))
  fit <- meta_pool(dat, yi = y, vi = v, study = lab)
  expect_s3_class(fit, "meta_fit")
  expect_identical(augment(fit)$.study, letters[1:4])
  expect_identical(fit$term, "overall")
})

test_that("missing values are dropped with a warning", {
  dat <- data.frame(y = c(0.1, NA, 0.3, 0.2), v = c(0.01, 0.02, 0.015, 0.03))
  expect_warning(fit <- meta_pool(dat, yi = y, vi = v), "Dropped 1 row")
  expect_equal(glance(fit)$nobs, 3L)
})

test_that("invalid input gives clear errors", {
  es <- bcg_es()
  expect_error(meta_pool(es, method = "XX"), "must be one of")
  expect_error(meta_pool(es, test = "q"), "must be one of")
  expect_error(meta_pool(es, level = 2), "between 0 and 1")
  expect_error(meta_pool(1:3), "data frame")
  expect_error(meta_pool(data.frame(y = 1, v = 0), yi = y, vi = v),
               "strictly positive")
  expect_error(meta_pool(data.frame(y = "a", v = 1), yi = y, vi = v),
               "numeric")
})

test_that("a single study is returned as is with a warning for tau2", {
  dat <- data.frame(y = 0.3, v = 0.04)
  expect_warning(fit <- meta_pool(dat, yi = y, vi = v), "set to 0")
  expect_equal(fit$estimate, 0.3)
})

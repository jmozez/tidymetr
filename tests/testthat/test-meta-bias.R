bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}
tight <- list(threshold = 1e-12, tol = 1e-12, maxiter = 5000)

test_that("Egger's test matches metafor::regtest()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  ref_fit <- metafor::rma(es$.yi, es$.vi, control = tight)
  eg <- meta_egger(es)
  ref <- metafor::regtest(ref_fit, model = "lm")
  expect_equal(eg$statistic, ref$zval, tolerance = 1e-8)
  expect_equal(eg$p.value, ref$pval, tolerance = 1e-8)
  expect_equal(eg$df, ref$dfs)
  expect_equal(eg$limit_estimate, unname(ref$est), tolerance = 1e-8)
  eg2 <- meta_egger(es, model = "rma")
  ref2 <- metafor::regtest(ref_fit, model = "rma")
  expect_equal(eg2$statistic, ref2$zval, tolerance = 1e-6)
  expect_equal(eg2$p.value, ref2$pval, tolerance = 1e-6)
  eg3 <- meta_egger(es, predictor = "vi")
  ref3 <- metafor::regtest(ref_fit, model = "lm", predictor = "vi")
  expect_equal(eg3$statistic, ref3$zval, tolerance = 1e-8)
  expect_identical(eg3$predictor, "vi")
})

test_that("Egger's test accepts a fitted model", {
  es <- bcg_es()
  fit <- meta_pool(es)
  expect_equal(meta_egger(fit), meta_egger(es))
  expect_error(meta_egger(meta_regress(es, ~ablat)), "meta_pool")
  expect_error(meta_egger(es[1:2, ]), "At least 3")
})

test_that("Begg's rank test matches metafor::ranktest()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  bg <- meta_begg(es)
  ref <- metafor::ranktest(es$.yi, es$.vi)
  expect_equal(bg$estimate, unname(ref$tau), tolerance = 1e-8)
  expect_equal(bg$p.value, ref$pval, tolerance = 1e-8)
  expect_identical(bg$test, "Begg")
})

test_that("trim-and-fill matches metafor::trimfill()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  for (est in c("L0", "R0")) {
    for (m in c("REML", "FE", "DL")) {
      tf <- meta_trimfill(es, estimator = est, method = m)
      ref_fit <- metafor::rma(es$.yi, es$.vi,
                              method = if (m == "FE") "EE" else m,
                              control = tight)
      ref <- metafor::trimfill(ref_fit, estimator = est)
      g <- glance(tf)
      expect_equal(g$k0, ref$k0, info = paste(est, m))
      expect_equal(tf$estimate, c(ref$beta), tolerance = 1e-6)
      expect_equal(tf$std.error, ref$se, tolerance = 1e-6)
      expect_equal(g$se.k0, ref$se.k0, tolerance = 1e-8)
      expect_identical(g$side, ref$side)
    }
  }
})

test_that("trim-and-fill fills studies on the requested side", {
  set.seed(42)
  vi <- stats::runif(20, 0.01, 0.2)
  yi <- 0.3 + stats::rnorm(20, 0, sqrt(vi))
  keep <- !(yi < 0.3 & vi > 0.08)
  dat <- data.frame(yi = yi[keep], vi = vi[keep])
  tf <- meta_trimfill(dat, yi = yi, vi = vi)
  g <- glance(tf)
  aug <- augment(tf)
  expect_s3_class(tf, "meta_fit")
  expect_equal(sum(aug$.filled), g$k0)
  expect_equal(nrow(aug), nrow(dat) + g$k0)
  expect_true(g$k0 > 0)
  expect_identical(g$side, "left")
  expect_true(tf$estimate < meta_pool(dat, yi = yi, vi = vi)$estimate)
  expect_error(meta_trimfill(dat, yi = yi, vi = vi, side = "up"),
               "must be one of")
})

test_that("PET-PEESE follows the conditional rule", {
  es <- bcg_es()
  pp <- meta_pet_peese(es)
  expect_equal(nrow(pp), 2)
  expect_identical(pp$model, c("PET", "PEESE"))
  pet <- stats::lm(es$.yi ~ sqrt(es$.vi), weights = 1 / es$.vi)
  peese <- stats::lm(es$.yi ~ es$.vi, weights = 1 / es$.vi)
  expect_equal(pp$estimate, unname(c(stats::coef(pet)[1],
                                     stats::coef(peese)[1])))
  cs <- summary(pet)$coefficients
  expect_equal(pp$p.value[1], cs[1, 4])
  expect_identical(pp$selected, c(cs[1, 4] >= 0.05, cs[1, 4] < 0.05))
  expect_equal(sum(pp$selected), 1)
  ci <- stats::confint(pet)
  expect_equal(pp$conf.low[1], unname(ci[1, 1]))
})

test_that("fail-safe N matches metafor::fsn()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  r <- meta_failsafe(es)
  ref <- metafor::fsn(es$.yi, es$.vi, type = "Rosenthal")
  expect_equal(r$fail_safe_n, ref$fsnum)
  expect_equal(r$p.value, ref$pval, tolerance = 1e-8)
  o <- meta_failsafe(es, type = "orwin", target = -0.1)
  ref <- metafor::fsn(es$.yi, es$.vi, type = "Orwin", target = -0.1)
  expect_equal(o$fail_safe_n, ref$fsnum)
  expect_equal(o$target, -0.1)
  rb <- meta_failsafe(es, type = "rosenberg")
  ref <- metafor::fsn(es$.yi, es$.vi, type = "Rosenberg")
  expect_equal(rb$fail_safe_n, ref$fsnum)
  expect_equal(rb$estimate, ref$meanes, tolerance = 1e-8)
})

test_that("bias functions validate input", {
  es <- bcg_es()
  expect_error(meta_failsafe(es, type = "x"), "must be one of")
  expect_error(meta_pet_peese(es, alpha = 2), "between 0 and 1")
  expect_error(meta_begg(es[1:2, ]), "At least 3")
})

bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}
tight <- list(threshold = 1e-12, tol = 1e-12, maxiter = 5000)

test_that("leave-one-out matches metafor::leave1out()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  for (t in c("z", "hksj")) {
    l1 <- meta_leave1out(es, test = t)
    ref <- metafor::leave1out(metafor::rma(
      es$.yi, es$.vi, test = if (t == "hksj") "knha" else "z",
      control = tight
    ))
    expect_equal(l1$estimate, ref$estimate, tolerance = 1e-6)
    expect_equal(l1$std.error, ref$se, tolerance = 1e-6)
    expect_equal(l1$p.value, ref$pval, tolerance = 1e-6)
    expect_equal(l1$tau2, ref$tau2, tolerance = 1e-6)
    expect_equal(l1$I2, ref$I2, tolerance = 1e-6)
    expect_equal(l1$QE, ref$Q, tolerance = 1e-8)
  }
  expect_identical(meta_leave1out(es)$study, es$author)
})

test_that("leave-one-out reuses the settings of a fitted model", {
  es <- bcg_es()
  fit <- meta_pool(es, method = "DL", test = "hksj")
  expect_equal(meta_leave1out(fit), meta_leave1out(es, method = "DL",
                                                   test = "hksj"))
  expect_error(meta_leave1out(es[1:2, ]), "At least 3")
})

test_that("cumulative meta-analysis matches metafor::cumul()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  cm <- meta_cumulative(es, order = year)
  ref_fit <- metafor::rma(es$.yi, es$.vi, control = tight)
  ref <- metafor::cumul(ref_fit, order = es$year)
  expect_equal(cm$estimate, as.vector(ref$estimate), tolerance = 1e-6)
  expect_equal(cm$std.error, ref$se, tolerance = 1e-6)
  expect_equal(cm$tau2, ref$tau2, tolerance = 1e-6)
  expect_identical(cm$k, seq_len(13L))
  expect_identical(cm$study, es$author[order(es$year)])
  expect_true(is.na(cm$I2[1]))
  expect_equal(cm$estimate[1], es$.yi[order(es$year)][1])
  last <- meta_pool(es)
  expect_equal(cm$estimate[13], last$estimate)
})

test_that("cumulative order can be decreasing or the row order", {
  es <- bcg_es()
  dec <- meta_cumulative(es, order = year, decreasing = TRUE)
  expect_identical(dec$study, es$author[order(es$year, decreasing = TRUE)])
  row <- meta_cumulative(es)
  expect_identical(row$study, es$author)
  expect_error(meta_cumulative(es, order = c(1, 2)), "one value per study")
})

test_that("influence diagnostics match metafor::influence()", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  inf <- meta_influence(meta_pool(es))
  ref <- stats::influence(metafor::rma(es$.yi, es$.vi, control = tight))
  r <- ref$inf
  expect_equal(inf$rstudent, r$rstudent, tolerance = 1e-5)
  expect_equal(inf$dffits, r$dffits, tolerance = 1e-5)
  expect_equal(inf$cooks_distance, r$cook.d, tolerance = 1e-5)
  expect_equal(inf$cov_ratio, r$cov.r, tolerance = 1e-5)
  expect_equal(inf$tau2_del, r$tau2.del, tolerance = 1e-5)
  expect_equal(inf$QE_del, r$QE.del, tolerance = 1e-6)
  expect_equal(inf$hat, r$hat, tolerance = 1e-6)
  expect_equal(inf$weight, r$weight, tolerance = 1e-6)
  expect_equal(inf$dfbetas_intercept, ref$dfbs$intrcpt, tolerance = 1e-5)
  expect_identical(inf$influential, unname(ref$is.infl))
})

test_that("influence diagnostics work for meta-regression", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  inf <- meta_influence(meta_regress(es, ~ ablat))
  ref <- stats::influence(metafor::rma(.yi, .vi, mods = ~ ablat, data = es,
                                       control = tight))
  expect_equal(inf$cooks_distance, ref$inf$cook.d, tolerance = 1e-5)
  expect_equal(inf$dfbetas_ablat, ref$dfbs$ablat, tolerance = 1e-5)
  expect_true(all(c("dfbetas_intercept", "dfbetas_ablat") %in% names(inf)))
})

test_that("influence diagnostics need a pooled or regression fit", {
  es <- bcg_es()
  expect_error(meta_influence(es), "meta_pool")
  expect_error(meta_influence(meta_subgroup(es, alloc)), "meta_pool")
})

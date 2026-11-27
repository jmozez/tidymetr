# Reference values from clubSandwich 0.6 (coef_test, vcov = "CR2"),
# metafor 4.8 (selmodel, type = "stepfun") and bayesmeta 3.5.

test_that("meta_robust() matches clubSandwich for a multilevel model", {
  fit <- meta_multilevel(school_calendar, yi = yi, vi = vi,
                         cluster = district, within = school)
  res <- meta_robust(fit)
  expect_equal(res$estimate, 0.1847131637, tolerance = 1e-6)
  expect_equal(res$std.error, 0.08445799544, tolerance = 1e-5)
  expect_equal(res$df, 9.863156233, tolerance = 1e-5)
  expect_equal(res$p.value, 0.05396674247, tolerance = 1e-4)
  expect_equal(attr(res, "n_clusters"), 11L)
  expect_true(res$df_ok)
})

test_that("meta_robust() matches clubSandwich for meta-regression", {
  fit <- meta_regress(school_calendar, ~year, yi = yi, vi = vi)
  res <- meta_robust(fit, cluster = district)
  expect_equal(res$std.error, c(17.95196201878, 0.00901070775),
               tolerance = 1e-5)
  expect_equal(res$df, c(3.269288028, 3.301626466), tolerance = 1e-5)
  expect_false(any(res$df_ok))
  ml <- meta_multilevel(school_calendar, yi = yi, vi = vi,
                        cluster = district, within = school, mods = ~year)
  res2 <- meta_robust(ml)
  expect_equal(res2$std.error, c(19.91892886272, 0.01000342432),
               tolerance = 1e-5)
  expect_equal(res2$df, c(4.154730055, 4.188998651), tolerance = 1e-5)
})

test_that("meta_robust() checks its input", {
  fit <- meta_pool(school_calendar, yi = yi, vi = vi)
  expect_error(meta_robust(fit), "cluster")
  expect_error(meta_robust(school_calendar), "meta_fit")
  expect_error(meta_robust(fit, cluster = c(1, 2)), "one non-missing")
})

test_that("meta_selection() matches metafor", {
  adh <- meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni)
  res <- meta_selection(adh)
  expect_equal(res$term,
               c("overall", "tau2", "weight (0.025, 1]"))
  expect_equal(res$estimate, c(0.091545209350, 0.005563569904,
                               0.240384938825), tolerance = 1e-4)
  expect_equal(res$std.error[c(1, 3)], c(0.044456813537, 0.200286499558),
               tolerance = 5e-3)
  expect_equal(attr(res, "lrt")$statistic, 2.985081166705,
               tolerance = 1e-4)
  expect_equal(unname(attr(res, "k_per_interval")), c(9L, 7L))
  expect_gt(attr(res, "unadjusted"), res$estimate[1])
  fe <- meta_selection(adh, method = "FE")
  expect_equal(fe$estimate, c(0.09493434735, 0.19561707277),
               tolerance = 1e-4)
  expect_equal(attr(fe, "lrt")$statistic, 5.08482535882, tolerance = 1e-4)
})

test_that("meta_selection() checks its input", {
  adh <- meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni)
  expect_error(meta_selection(adh, steps = c(0.5, 0.025)), "increasing")
  expect_error(meta_selection(adh, steps = 1), "between")
  expect_warning(meta_selection(adh, steps = c(0.025, 0.05, 0.5)),
                 "fewer than 3")
  expect_error(meta_selection(meta_regress(adh, ~year)), "moderators")
})

bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
  )
}

test_that("meta_bayes() matches bayesmeta and direct quadrature", {
  res <- meta_bayes(bcg_es())
  tau <- res[res$term == "tau", ]
  expect_equal(c(tau$estimate, tau$mean, tau$sd),
               c(0.5537537973, 0.5719096716, 0.1430049490), tolerance = 1e-5)
  expect_equal(c(tau$conf.low, tau$conf.high), c(0.3455038200, 0.9018950856),
               tolerance = 1e-4)
  mu <- res[res$term == "overall", ]
  # Adaptive quadrature with stats::integrate(); bayesmeta agrees to 1e-3
  expect_equal(mu$mean, -0.7118600082, tolerance = 1e-6)
  expect_equal(mu$conf.low, -1.091196874, tolerance = 1e-5)
  expect_equal(mu$mean, -0.7118214, tolerance = 1e-3)
  pred <- res[res$term == "prediction", ]
  expect_equal(pred$mean, mu$mean)
  expect_gt(pred$sd, mu$sd)
  expect_lt(attr(res, "prob_positive"), 0.001)
  post <- attr(res, "posterior")
  d <- post$density
  area <- sum(diff(post$tau) * (d[-1] + d[-length(d)]) / 2)
  expect_equal(area, 1, tolerance = 1e-8)
})

test_that("meta_bayes() handles priors and few studies", {
  es <- bcg_es()
  r2 <- meta_bayes(es, mu_sd = 4, tau_prior = "half_cauchy")
  expect_equal(r2$mean[2], 0.5879780, tolerance = 1e-5)
  few <- meta_bayes(es[1:3, ])
  expect_equal(few$estimate[2], 0.2609205, tolerance = 1e-5)
  expect_true(all(few$conf.low < few$conf.high))
  expect_error(meta_bayes(es, tau_scale = 0), "tau_scale")
  expect_error(meta_bayes(es, mu_sd = -1), "mu_sd")
})

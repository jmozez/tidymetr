bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}
tight <- list(threshold = 1e-12, tol = 1e-12, maxiter = 5000)

test_that("meta_regress() matches metafor for every estimator", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  for (m in c("FE", "DL", "REML", "ML", "PM", "SJ")) {
    for (t in c("z", "hksj")) {
      fit <- meta_regress(es, ~ ablat + year, method = m, test = t)
      ref <- suppressWarnings(metafor::rma(
        .yi, .vi, mods = ~ ablat + year, data = es,
        method = if (m == "FE") "EE" else m,
        test = if (t == "hksj") "knha" else "z", control = tight
      ))
      g <- glance(fit)
      expect_equal(fit$estimate, unname(c(ref$beta)), tolerance = 1e-6,
                   info = paste(m, t))
      expect_equal(fit$std.error, ref$se, tolerance = 1e-6)
      expect_equal(fit$p.value, ref$pval, tolerance = 1e-6)
      expect_equal(g$tau2, ref$tau2, tolerance = 1e-6)
      expect_equal(g$QM, ref$QM, tolerance = 1e-6)
      expect_equal(g$p.QM, ref$QMp, tolerance = 1e-6)
      expect_equal(g$QE, ref$QE, tolerance = 1e-6)
      expect_equal(g$I2, ref$I2, tolerance = 1e-6)
      if (m != "FE") {
        expect_equal(g$R2, ref$R2, tolerance = 1e-5)
      }
    }
  }
})

test_that("categorical moderators and predictions work", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  fit <- meta_regress(es, ~ factor(alloc))
  ref <- metafor::rma(.yi, .vi, mods = ~ factor(alloc), data = es,
                      control = tight)
  expect_equal(fit$estimate, unname(c(ref$beta)), tolerance = 1e-6)
  fit <- meta_regress(es, ~ ablat)
  ref <- metafor::rma(.yi, .vi, mods = ~ ablat, data = es, control = tight)
  nd <- data.frame(ablat = c(10, 30, 50))
  p <- predict(fit, newdata = nd, interval = "prediction")
  pr <- predict(ref, newmods = nd$ablat)
  expect_equal(p$.pred, as.vector(pr$pred), tolerance = 1e-6)
  expect_equal(p$.se, as.vector(pr$se), tolerance = 1e-6)
  expect_equal(p$.pred_lower, as.vector(pr$pi.lb), tolerance = 1e-6)
  pc <- predict(fit, newdata = nd)
  expect_equal(pc$.pred_upper, as.vector(pr$ci.ub), tolerance = 1e-6)
  expect_named(predict(fit, nd, interval = "none"), c(".pred", ".se"))
  expect_equal(nrow(predict(fit)), nrow(es))
})

test_that("meta_regress() validates the formula and drops missing values", {
  es <- bcg_es()
  expect_error(meta_regress(es, "ablat"), "one-sided formula")
  expect_error(meta_regress(es, y ~ ablat), "one-sided formula")
  es$ablat[2] <- NA
  expect_warning(fit <- meta_regress(es, ~ ablat), "missing moderator")
  expect_equal(glance(fit)$nobs, 12L)
})

test_that("separate subgroup analyses match pooled subsets", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  fit <- meta_subgroup(es, alloc)
  for (l in unique(es$alloc)) {
    ref <- metafor::rma(.yi, .vi, data = es, subset = alloc == l,
                        control = tight)
    row <- fit[fit$term == l, ]
    expect_equal(row$estimate, c(ref$beta), tolerance = 1e-6)
    expect_equal(row$tau2, ref$tau2, tolerance = 1e-6)
  }
  g <- glance(fit)
  w <- 1 / fit$std.error^2
  qb <- sum(w * (fit$estimate - sum(w * fit$estimate) / sum(w))^2)
  expect_equal(g$Q.between, qb)
  expect_equal(g$df.between, 2L)
  expect_identical(g$tau2_type, "separate")
})

test_that("common tau2 subgroups match a model without an intercept", {
  skip_if_not_installed("metafor")
  es <- bcg_es()
  fit <- meta_subgroup(es, alloc, tau2 = "common")
  ref <- metafor::rma(.yi, .vi, mods = ~ 0 + alloc, data = es,
                      control = tight)
  ref2 <- metafor::rma(.yi, .vi, mods = ~ alloc, data = es, control = tight)
  expect_equal(fit$estimate, unname(c(ref$beta)), tolerance = 1e-6)
  expect_equal(glance(fit)$Q.between, ref2$QM, tolerance = 1e-6)
  hk <- meta_subgroup(es, alloc, tau2 = "common", test = "hksj")
  ref3 <- metafor::rma(.yi, .vi, mods = ~ alloc, data = es, test = "knha",
                       control = tight)
  expect_equal(glance(hk)$Q.between, ref3$QM, tolerance = 1e-6)
  expect_equal(glance(hk)$p.between, ref3$QMp, tolerance = 1e-6)
  p <- predict(fit, newdata = data.frame(alloc = "random"),
               interval = "prediction")
  expect_equal(p$.pred, fit$estimate[fit$term == "random"])
})

test_that("subgroups with one study and invalid groups are handled", {
  es <- bcg_es()
  es$grp <- c(rep("a", 12), "b")
  expect_message(fit <- meta_subgroup(es, grp), "one study")
  expect_equal(fit$estimate[fit$term == "b"], es$.yi[13])
  expect_error(meta_subgroup(es, rep("a", 13)), "at least two levels")
  expect_equal(nrow(predict(fit)), 13)
  es$grp[1] <- NA
  expect_warning(suppressMessages(meta_subgroup(es, grp)), "missing group")
  expect_error(predict(fit, newdata = data.frame(x = 1)), "grouping column")
})

test_that("three-level models match metafor::rma.mv()", {
  skip_if_not_installed("metafor")
  fit <- meta_multilevel(school_calendar, district, yi = yi, vi = vi,
                         within = school)
  ref <- metafor::rma.mv(yi, vi, random = ~ 1 | district / school,
                         data = school_calendar)
  g <- glance(fit)
  expect_equal(fit$estimate, c(ref$beta), tolerance = 1e-5)
  expect_equal(fit$std.error, ref$se, tolerance = 1e-5)
  expect_equal(g$sigma2_district, ref$sigma2[1], tolerance = 1e-4)
  expect_equal(g$sigma2_school, ref$sigma2[2], tolerance = 1e-4)
  expect_equal(g$logLik, c(stats::logLik(ref)), tolerance = 1e-6)
  expect_equal(g$QE, ref$QE, tolerance = 1e-8)
  ml <- meta_multilevel(school_calendar, district, yi = yi, vi = vi,
                        within = school, mods = ~ I(year - 1990),
                        method = "ML", test = "t")
  ref <- metafor::rma.mv(yi, vi, mods = ~ I(year - 1990),
                         random = ~ 1 | district / school,
                         data = school_calendar, method = "ML", test = "t")
  expect_equal(ml$estimate, unname(c(ref$beta)), tolerance = 1e-5)
  expect_equal(ml$p.value, ref$pval, tolerance = 1e-5)
  expect_equal(glance(ml)$QM, ref$QM, tolerance = 1e-4)
})

test_that("phylogenetic correlation matrices are used", {
  skip_if_not_installed("metafor")
  set.seed(2026)
  sp <- paste0("sp", 1:8)
  R <- outer(1:8, 1:8, function(i, j) 0.6^abs(i - j))
  dimnames(R) <- list(sp, sp)
  dat <- data.frame(species = rep(sp, each = 3))
  dat$vi <- stats::runif(24, 0.01, 0.05)
  dat$yi <- 0.3 + rep(stats::rnorm(8, 0, 0.3), each = 3) +
    stats::rnorm(24, 0, sqrt(dat$vi))
  dat$es_id <- seq_len(24)
  fit <- meta_multilevel(dat, species, yi = yi, vi = vi, cor_matrix = R)
  ref <- metafor::rma.mv(yi, vi, random = list(~ 1 | species, ~ 1 | es_id),
                         R = list(species = R), data = dat)
  expect_equal(fit$estimate, c(ref$beta), tolerance = 1e-4)
  expect_equal(glance(fit)$sigma2_species,
               ref$sigma2[1], tolerance = 1e-3)
  expect_error(meta_multilevel(dat, species, yi = yi, vi = vi,
                               cor_matrix = R[1:4, 1:4]), "Missing")
  bad <- R
  bad[1, 1] <- 2
  expect_error(meta_multilevel(dat, species, yi = yi, vi = vi,
                               cor_matrix = bad), "unit")
  expect_error(meta_multilevel(dat, species, yi = yi, vi = vi,
                               cor_matrix = unname(R)), "names")
})

test_that("multilevel I2 follows Nakagawa and Santos (2012)", {
  fit <- meta_multilevel(school_calendar, district, yi = yi, vi = vi,
                         within = school)
  g <- glance(fit)
  w <- 1 / school_calendar$vi
  k <- nrow(school_calendar)
  vt <- (k - 1) * sum(w) / (sum(w)^2 - sum(w^2))
  s2 <- c(g$sigma2_district, g$sigma2_school)
  expect_equal(g$I2_district, 100 * s2[1] / (sum(s2) + vt))
  expect_equal(g$I2, 100 * sum(s2) / (sum(s2) + vt))
  aug <- augment(fit)
  expect_true(all(c(".fitted", ".resid", ".std_resid") %in% names(aug)))
  p <- predict(fit, interval = "prediction")
  expect_equal(nrow(p), 1)
  expect_equal(p$.pred_lower, g$pred.low)
})

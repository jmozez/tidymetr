test_that("log risk and odds ratios match metafor", {
  skip_if_not_installed("metafor")
  rr <- meta_effect_size(bcg_trials, "RR", event1 = tpos, n1 = tpos + tneg,
                         event2 = cpos, n2 = cpos + cneg)
  ref <- metafor::escalc("RR", ai = tpos, bi = tneg, ci = cpos, di = cneg,
                         data = bcg_trials)
  expect_equal(rr$.yi, c(ref$yi))
  expect_equal(rr$.vi, c(ref$vi))
  or <- meta_effect_size(bcg_trials, "logOR", event1 = tpos,
                         n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg)
  ref <- metafor::escalc("OR", ai = tpos, bi = tneg, ci = cpos, di = cneg,
                         data = bcg_trials)
  expect_equal(or$.yi, c(ref$yi))
  expect_equal(or$.vi, c(ref$vi))
  expect_identical(attr(or, "measure"), "OR")
})

test_that("Hedges' g and mean differences match metafor", {
  skip_if_not_installed("metafor")
  g <- meta_effect_size(stroke_los, "SMD", m1 = m1, sd1 = sd1, n1 = n1,
                        m2 = m2, sd2 = sd2, n2 = n2)
  ref <- metafor::escalc("SMD", m1i = m1, sd1i = sd1, n1i = n1, m2i = m2,
                         sd2i = sd2, n2i = n2, data = stroke_los)
  expect_equal(g$.yi, c(ref$yi))
  expect_equal(g$.vi, c(ref$vi))
  md <- meta_effect_size(stroke_los, "MD", m1 = m1, sd1 = sd1, n1 = n1,
                         m2 = m2, sd2 = sd2, n2 = n2)
  ref <- metafor::escalc("MD", m1i = m1, sd1i = sd1, n1i = n1, m2i = m2,
                         sd2i = sd2, n2i = n2, data = stroke_los)
  expect_equal(md$.yi, c(ref$yi))
  expect_equal(md$.vi, c(ref$vi))
})

test_that("Hedges' g follows the textbook formula", {
  g <- meta_effect_size(data.frame(a = 1), "g", m1 = 10, sd1 = 2, n1 = 20,
                        m2 = 9, sd2 = 2, n2 = 20)
  j <- exp(lgamma(38 / 2) - log(sqrt(38 / 2)) - lgamma(37 / 2))
  expect_equal(g$.yi, j * 0.5)
  expect_equal(g$.vi, 1 / 20 + 1 / 20 + (j * 0.5)^2 / 80)
  expect_lt(j, 1)
})

test_that("Fisher's z, logit proportions and rate ratios match metafor", {
  skip_if_not_installed("metafor")
  z <- meta_effect_size(adherence_cor, "fisher_z", r = ri, n = ni)
  ref <- metafor::escalc("ZCOR", ri = ri, ni = ni, data = adherence_cor)
  expect_equal(z$.yi, c(ref$yi))
  expect_equal(z$.vi, c(ref$vi))
  p <- meta_effect_size(smoking_cessation, "PLO", event = xi, n = ni)
  ref <- metafor::escalc("PLO", xi = xi, ni = ni, data = smoking_cessation)
  expect_equal(p$.yi, c(ref$yi))
  expect_equal(p$.vi, c(ref$vi))
  ir <- data.frame(x1 = c(5, 0, 12), t1 = c(100, 80, 300),
                   x2 = c(9, 4, 10), t2 = c(110, 90, 250))
  i <- meta_effect_size(ir, "IRR", event1 = x1, time1 = t1, event2 = x2,
                        time2 = t2)
  ref <- metafor::escalc("IRR", x1i = x1, t1i = t1, x2i = x2, t2i = t2,
                         data = ir)
  expect_equal(i$.yi, c(ref$yi))
  expect_equal(i$.vi, c(ref$vi))
})

test_that("zero cell corrections are applied as requested", {
  dat <- data.frame(e1 = c(0, 5), n1 = c(20, 20), e2 = c(3, 4),
                    n2 = c(20, 20))
  only0 <- meta_effect_size(dat, "OR", event1 = e1, n1 = n1, event2 = e2,
                            n2 = n2)
  expect_equal(only0$.yi[1], log((0.5 * 17.5) / (20.5 * 3.5)))
  expect_equal(only0$.yi[2], log((5 * 16) / (15 * 4)))
  all <- meta_effect_size(dat, "OR", event1 = e1, n1 = n1, event2 = e2,
                          n2 = n2, to = "all")
  expect_equal(all$.yi[2], log((5.5 * 16.5) / (15.5 * 4.5)))
  expect_warning(
    none <- meta_effect_size(dat, "OR", event1 = e1, n1 = n1, event2 = e2,
                             n2 = n2, to = "none"),
    "non-positive or infinite"
  )
  expect_true(is.na(none$.yi[1]))
})

test_that("generic effect sizes accept variances or standard errors", {
  dat <- data.frame(y = c(0.1, 0.3), v = c(0.01, 0.04), s = c(0.1, 0.2))
  a <- meta_effect_size(dat, "GEN", yi = y, vi = v)
  b <- meta_effect_size(dat, "GEN", yi = y, sei = s)
  expect_equal(a$.vi, b$.vi)
  expect_identical(attr(a, "measure"), "GEN")
})

test_that("input errors are informative", {
  expect_error(meta_effect_size(bcg_trials, "XYZ"), "Unknown effect size")
  expect_error(meta_effect_size(bcg_trials, "OR", event1 = tpos),
               "Missing")
  expect_error(meta_effect_size(bcg_trials, "OR", event1 = author,
                                n1 = tpos, event2 = cpos, n2 = cneg),
               "numeric")
  expect_error(meta_effect_size(bcg_trials, "RR", tpos), "must be empty")
  expect_error(meta_effect_size(data.frame(r = 1.2, n = 10), "ZCOR",
                                r = r, n = n), "between -1 and 1")
  expect_error(meta_effect_size(data.frame(e = 5, n = 3), "PLO",
                                event = e, n = n), "between 0")
  expect_error(meta_effect_size(data.frame(a = 1), "SMD", m1 = 1, sd1 = 1,
                                n1 = 1, m2 = 1, sd2 = 1, n2 = 5),
               "at least 2")
  expect_error(meta_effect_size(data.frame(a = 1), "IRR", event1 = 1,
                                time1 = 0, event2 = 1, time2 = 1),
               "positive")
  expect_error(meta_effect_size(data.frame(a = 1), "OR", event1 = 5,
                                n1 = 3, event2 = 1, n2 = 4),
               "group size")
})

test_that("meta_transform() back-transforms estimates", {
  fit <- meta_pool(meta_effect_size(bcg_trials, "RR", event1 = tpos,
                                    n1 = tpos + tneg, event2 = cpos,
                                    n2 = cpos + cneg))
  out <- meta_transform(fit)
  expect_equal(out$estimate, exp(fit$estimate))
  z <- meta_pool(meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni))
  expect_equal(meta_transform(z)$estimate, tanh(z$estimate))
  expect_equal(
    meta_transform(tibble::tibble(estimate = 0, conf.low = -1,
                                  conf.high = 1), measure = "PLO")$estimate,
    0.5
  )
})

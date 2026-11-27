smoking_pw <- function() {
  meta_pairwise(smoking_cessation, study = study, treatment = trt,
                measure = "OR", event = xi, n = ni)
}

test_that("meta_pairwise() builds every within-study contrast", {
  pw <- smoking_pw()
  expect_s3_class(pw, "meta_es")
  # 22 two-arm studies and 2 three-arm studies (3 contrasts each)
  expect_equal(nrow(pw), 22 + 6)
  row <- pw[pw$study == 1, ]
  expect_equal(row$.yi, log((75 / 656) / (363 / 351)))
  cont <- data.frame(s = c(1, 1, 2, 2), t = c("a", "b", "a", "b"),
                     m = c(10, 12, 9, 11), sd = c(2, 2, 3, 3),
                     n = c(20, 20, 30, 30))
  md <- meta_pairwise(cont, study = s, treatment = t, measure = "MD",
                      mean = m, sd = sd, n = n)
  expect_equal(md$.yi, c(-2, -2))
  expect_error(meta_pairwise(cont, s, t, measure = "OR", event = m),
               "needs")
  expect_error(meta_pairwise(cont, s, t, measure = "ZCOR"), "two groups")
  dup <- cont
  dup$t[2] <- "a"
  expect_error(meta_pairwise(dup, s, t, measure = "MD", mean = m, sd = sd,
                             n = n), "duplicated")
  single <- cont[-4, ]
  expect_warning(meta_pairwise(single, s, t, measure = "MD", mean = m,
                               sd = sd, n = n), "single arm")
})

test_that("common-effect NMA matches GLS in metafor::rma.mv()", {
  skip_if_not_installed("metafor")
  nma <- meta_network(smoking_pw(), study = study, treat1 = treat1,
                      treat2 = treat2, reference = "no_contact",
                      method = "FE")
  b <- attr(nma, "nma")$basic
  X <- b$X[, setdiff(colnames(b$X), "no_contact")]
  ref <- metafor::rma.mv(b$y, b$S, mods = X, intercept = FALSE,
                         method = "FE")
  eff <- nma[nma$treatment != "no_contact", ]
  expect_equal(eff$estimate, unname(c(ref$beta)[match(eff$treatment,
                                                     colnames(X))]),
               tolerance = 1e-8)
  expect_equal(eff$std.error, unname(ref$se[match(eff$treatment,
                                                  colnames(X))]),
               tolerance = 1e-8)
  expect_equal(glance(nma)$Q, ref$QE, tolerance = 1e-8)
})

test_that("random-effects NMA matches rma.mv() with a consistent tau2", {
  skip_if_not_installed("metafor")
  nma <- meta_network(smoking_pw(), study = study, treat1 = treat1,
                      treat2 = treat2, reference = "no_contact")
  b <- attr(nma, "nma")$basic
  X <- b$X[, setdiff(colnames(b$X), "no_contact")]
  dd <- data.frame(y = b$y, study = b$study, row = seq_along(b$y))
  ref <- metafor::rma.mv(y, b$S, mods = X, intercept = FALSE,
                         random = ~ factor(row) | study, struct = "CS",
                         rho = 0.5, data = dd)
  eff <- nma[nma$treatment != "no_contact", ]
  idx <- match(eff$treatment, colnames(X))
  expect_equal(glance(nma)$tau2, ref$tau2, tolerance = 1e-4)
  expect_equal(eff$estimate, unname(c(ref$beta)[idx]), tolerance = 1e-5)
  expect_equal(eff$std.error, unname(ref$se[idx]), tolerance = 1e-5)
})

test_that("three-arm studies keep their within-study covariance", {
  pw <- smoking_pw()
  nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
                      reference = "no_contact")
  b <- attr(nma, "nma")$basic
  rows <- which(b$study == "2")
  expect_length(rows, 2)
  S <- b$S[rows, rows]
  # Arm variances recovered exactly from the three pairwise variances
  v <- pw$.vi[pw$study == 2]
  s_base <- (v[1] + v[2] - v[3]) / 2
  expect_equal(S[1, 2], s_base)
  expect_equal(b$M[rows, rows], matrix(c(1, 0.5, 0.5, 1), 2))
})

test_that("P-scores, league table and splits are coherent", {
  nma <- meta_network(smoking_pw(), study = study, treat1 = treat1,
                      treat2 = treat2, reference = "no_contact",
                      small_values = "bad")
  expect_equal(mean(nma$pscore), 0.5)
  expect_true(all(nma$pscore >= 0 & nma$pscore <= 1))
  expect_identical(nma$treatment[which.min(nma$pscore)], "no_contact")
  good <- meta_network(smoking_pw(), study = study, treat1 = treat1,
                       treat2 = treat2, reference = "no_contact",
                       small_values = "good")
  expect_equal(good$pscore, 1 - nma$pscore)
  league <- tidy(nma, type = "league")
  expect_equal(nrow(league), 12)
  ab <- league[league$treat1 == "self_help" &
                 league$treat2 == "grp_counseling", ]
  ba <- league[league$treat1 == "grp_counseling" &
                 league$treat2 == "self_help", ]
  expect_equal(ab$estimate, -ba$estimate)
  expect_equal(ab$std.error, ba$std.error)
  split <- tidy(nma, type = "split")
  expect_true(all(c("direct", "indirect", "difference") %in% names(split)))
  ok <- !is.na(split$indirect)
  w_dir <- 1 / split$direct_se[ok]^2
  w_ind <- 1 / split$indirect_se[ok]^2
  expect_equal(
    (w_dir * split$direct[ok] + w_ind * split$indirect[ok]) /
      (w_dir + w_ind),
    split$network[ok]
  )
  inc <- tidy(nma, type = "inconsistency")
  expect_equal(inc$Q[1], inc$Q[2] + inc$Q[3])
  expect_equal(inc$df[1], inc$df[2] + inc$df[3])
  expect_s3_class(tidy(nma, type = "designs"), "tbl_df")
  expect_equal(tidy(nma, exponentiate = TRUE)$estimate, exp(nma$estimate))
})

test_that("meta_network() checks its input", {
  pw <- smoking_pw()
  drop <- pw$study == 2 & pw$treat1 == "ind_counseling"
  expect_error(meta_network(pw[!drop, ],
                            study = study, treat1 = treat1,
                            treat2 = treat2), "every pairwise")
  two <- pw[pw$treat1 %in% c("no_contact", "ind_counseling") &
              pw$treat2 %in% c("no_contact", "ind_counseling"), ]
  expect_error(meta_network(two, study = study, treat1 = treat1,
                            treat2 = treat2), "at least three")
  disc <- data.frame(s = 1:4, a = c("A", "A", "C", "C"),
                     b = c("B", "B", "D", "D"), y = 0.1, v = 0.1)
  expect_error(meta_network(disc, study = s, treat1 = a, treat2 = b,
                            yi = y, vi = v), "not connected")
  expect_error(meta_network(pw, study = study, treat1 = treat1,
                            treat2 = treat2, reference = "x"),
               "not in the network")
  self <- pw
  self$treat2[1] <- self$treat1[1]
  expect_error(meta_network(self, study = study, treat1 = treat1,
                            treat2 = treat2), "itself")
})

test_that("the default reference is the most connected treatment", {
  nma <- meta_network(smoking_pw(), study = study, treat1 = treat1,
                      treat2 = treat2)
  expect_identical(glance(nma)$reference, "ind_counseling")
  aug <- augment(nma)
  expect_equal(nrow(aug), 28)
  expect_equal(aug$.resid, aug$yi - aug$.fitted)
})

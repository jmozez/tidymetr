test_that("leave-one-study-out holds out every study once", {
  folds <- meta_leave_study_out_cv(school_calendar, study = district)
  expect_s3_class(folds, c("meta_leave_study_out_cv", "rset"))
  expect_equal(nrow(folds), length(unique(school_calendar$district)))
  held <- lapply(folds$splits, function(s) {
    unique(rsample::assessment(s)$district)
  })
  expect_true(all(lengths(held) == 1))
  expect_setequal(unlist(held), unique(school_calendar$district))
  for (s in folds$splits) {
    a <- rsample::analysis(s)
    h <- rsample::assessment(s)
    expect_equal(nrow(a) + nrow(h), nrow(school_calendar))
    expect_length(intersect(a$district, h$district), 0)
  }
  expect_identical(folds$id, as.character(unique(school_calendar$district)))
  expect_output(print(folds), "Leave-one-study-out")
})

test_that("leave-one-study-out validates the study column", {
  expect_error(meta_leave_study_out_cv(school_calendar, study = 1:3),
               "one value per row")
  d <- school_calendar
  d$district[1] <- NA
  expect_error(meta_leave_study_out_cv(d, study = district), "missing")
  expect_error(meta_leave_study_out_cv(d[1:2, ], study = rep(1, 2)),
               "two studies")
  expect_error(meta_leave_study_out_cv(1:3, study = x), "data frame")
})

test_that("cluster cross-validation keeps clusters together", {
  set.seed(1)
  folds <- meta_cluster_cv(school_calendar, district, v = 4)
  expect_s3_class(folds, c("meta_cluster_cv", "rset"))
  expect_equal(nrow(folds), 4)
  assess <- lapply(folds$splits, rsample::assessment)
  expect_equal(sum(vapply(assess, nrow, integer(1))),
               nrow(school_calendar))
  cl <- lapply(assess, function(a) unique(a$district))
  expect_length(unlist(cl), length(unique(school_calendar$district)))
  sizes <- vapply(assess, nrow, integer(1))
  biggest <- max(table(school_calendar$district))
  expect_true(max(sizes) - min(sizes) <= biggest)
  expect_output(print(folds), "4-fold")
})

test_that("cluster cross-validation repeats and validates", {
  set.seed(2)
  folds <- meta_cluster_cv(school_calendar, district, v = 3, repeats = 2)
  expect_equal(nrow(folds), 6)
  expect_identical(names(folds)[2:3], c("id", "id2"))
  expect_identical(unique(folds$id), c("Repeat1", "Repeat2"))
  expect_error(meta_cluster_cv(school_calendar, district, v = 100),
               "cannot exceed")
  expect_error(meta_cluster_cv(school_calendar, district, v = 1))
  expect_error(meta_cluster_cv(school_calendar, 1:2), "one non-missing")
})

test_that("splits work with model fitting", {
  folds <- meta_leave_study_out_cv(school_calendar, study = district)
  s <- folds$splits[[1]]
  fit <- meta_pool(rsample::analysis(s), yi = yi, vi = vi)
  expect_s3_class(fit, "meta_fit")
  expect_equal(glance(fit)$nobs, nrow(rsample::analysis(s)))
})

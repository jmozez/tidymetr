bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}

test_that("meta_effect_size() returns a meta_es tibble", {
  es <- bcg_es()
  expect_s3_class(es, c("meta_es", "tbl_df", "tbl", "data.frame"))
  expect_true(is_meta_es(es))
  expect_identical(attr(es, "measure"), "RR")
  expect_identical(attr(es, "study"), "author")
  expect_true(all(c(".yi", ".vi", ".sei") %in% names(es)))
  expect_equal(es$.sei, sqrt(es$.vi))
})

test_that("the class survives dplyr verbs that keep the effect sizes", {
  es <- bcg_es()
  expect_s3_class(dplyr::filter(es, year > 1960), "meta_es")
  expect_s3_class(dplyr::mutate(es, z = .yi / .sei), "meta_es")
  expect_s3_class(dplyr::arrange(es, year), "meta_es")
  expect_s3_class(es[1:3, ], "meta_es")
  expect_identical(attr(dplyr::filter(es, year > 1960), "measure"), "RR")
})

test_that("the class falls back to a tibble without .yi or .vi", {
  es <- bcg_es()
  out <- dplyr::select(es, author, year)
  expect_false(is_meta_es(out))
  expect_s3_class(out, "tbl_df")
  expect_false(is_meta_es(es[, 1:2]))
})

test_that("vctrs coercion and casting work", {
  es <- bcg_es()
  both <- vctrs::vec_rbind(es[1:2, ], es[3:5, ])
  expect_s3_class(both, "meta_es")
  expect_equal(nrow(both), 5)
  mixed <- vctrs::vec_rbind(es[1:2, ], tibble::as_tibble(es)[3:4, ])
  expect_false(is_meta_es(mixed))
  expect_s3_class(mixed, "tbl_df")
  ptype <- vctrs::vec_ptype2(es, es)
  expect_s3_class(ptype, "meta_es")
  cast <- vctrs::vec_cast(tibble::as_tibble(es), es)
  expect_s3_class(cast, "meta_es")
  back <- vctrs::vec_cast(es, tibble::as_tibble(es))
  expect_false(is_meta_es(back))
  expect_s3_class(back, "tbl_df")
  other <- es
  attr(other, "measure") <- "OR"
  expect_false(is_meta_es(vctrs::vec_ptype2(es, other)))
})

test_that("as_meta_es() wraps precomputed effect sizes", {
  dat <- data.frame(id = 1:3, g = c(0.2, 0.5, 0.1), se = c(0.2, 0.1, 0.3))
  es <- as_meta_es(dat, yi = g, sei = se, study = id)
  expect_s3_class(es, "meta_es")
  expect_equal(es$.vi, dat$se^2)
  expect_identical(attr(es, "study"), "id")
  expect_error(as_meta_es(dat, yi = g), "vi")
  expect_error(as_meta_es(data.frame(g = 1, v = -1), yi = g, vi = v),
               "strictly positive")
  expect_error(as_meta_es(1:3, yi = g, vi = v), "data frame")
})

test_that("new_meta_es() builds an empty object", {
  es <- new_meta_es()
  expect_s3_class(es, "meta_es")
  expect_equal(nrow(es), 0)
})

test_that("meta_fit and meta_nma classes behave like tibbles", {
  fit <- meta_pool(bcg_es())
  expect_true(is_meta_fit(fit))
  expect_s3_class(dplyr::filter(fit, term == "overall"), "meta_fit")
  expect_false(is_meta_fit(dplyr::select(fit, std.error)))
  expect_s3_class(vctrs::vec_rbind(fit, fit), "tbl_df")
  expect_false(is_meta_fit(vctrs::vec_rbind(fit, fit)))
  expect_s3_class(vctrs::vec_cast(fit, fit), "meta_fit")
  expect_s3_class(vctrs::vec_ptype2(fit, tibble::tibble()), "tbl_df")
  pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
                      measure = "OR", event = xi, n = ni)
  nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2)
  expect_true(is_meta_nma(nma))
  expect_s3_class(dplyr::arrange(nma, pscore), "meta_nma")
  expect_false(is_meta_nma(dplyr::select(nma, pscore)))
  expect_s3_class(vctrs::vec_cast(nma, nma), "meta_nma")
  expect_false(is_meta_nma(vctrs::vec_rbind(nma, nma)))
})

test_that("print and format methods run", {
  es <- bcg_es()
  expect_output(print(es), "Measure")
  expect_output(print(meta_pool(es)), "Meta-analysis")
  expect_output(print(meta_pool(es, test = "hksj")), "Hartung-Knapp")
  expect_output(print(meta_subgroup(es, alloc)), "subgroup differences")
  expect_output(print(meta_trimfill(meta_pool(es))), "filled")
  expect_output(
    print(meta_multilevel(school_calendar, district, yi = yi, vi = vi)),
    "sigma"
  )
  pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
                      measure = "OR", event = xi, n = ni)
  expect_output(
    print(meta_network(pw, study = study, treat1 = treat1, treat2 = treat2)),
    "Network meta-analysis"
  )
})

bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}

test_that("autoplot() draws every meta_fit plot type", {
  fit <- meta_pool(bcg_es())
  for (type in c("forest", "funnel", "baujat", "radial")) {
    p <- ggplot2::autoplot(fit, type = type)
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot2::ggplot_build(p))
  }
  expect_error(ggplot2::autoplot(fit, type = "pie"), "must be one of")
})

test_that("forest plots include the studies and the summary", {
  fit <- meta_pool(bcg_es())
  p <- ggplot2::autoplot(fit)
  built <- ggplot2::ggplot_build(p)
  labels <- unlist(lapply(built$layout$panel_params, function(pp) {
    pp$y$get_labels()
  }))
  expect_true(all(unique(bcg_trials$author) %in% labels))
  expect_true("Pooled estimate" %in% labels)
})

test_that("autoplot() handles subgroup, regression, trim-and-fill and
          multilevel fits", {
  es <- bcg_es()
  plots <- list(
    ggplot2::autoplot(meta_subgroup(es, alloc)),
    ggplot2::autoplot(meta_regress(es, ~ ablat), type = "funnel"),
    ggplot2::autoplot(meta_trimfill(es), type = "funnel"),
    ggplot2::autoplot(meta_multilevel(school_calendar, district, yi = yi,
                                      vi = vi, within = school))
  )
  for (p in plots) {
    expect_s3_class(p, "ggplot")
    expect_no_error(ggplot2::ggplot_build(p))
  }
})

test_that("autoplot() draws network graphs and network forest plots", {
  pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
                      measure = "OR", event = xi, n = ni)
  nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
                      reference = "no_contact")
  net <- ggplot2::autoplot(nma)
  fst <- ggplot2::autoplot(nma, type = "forest")
  expect_s3_class(net, "ggplot")
  expect_s3_class(fst, "ggplot")
  expect_no_error(ggplot2::ggplot_build(net))
  expect_no_error(ggplot2::ggplot_build(fst))
  expect_error(ggplot2::autoplot(nma, type = "funnel"), "must be one of")
})

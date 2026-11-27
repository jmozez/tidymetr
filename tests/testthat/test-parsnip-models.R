bcg_es <- function() {
  meta_effect_size(bcg_trials, "RR",
    event1 = tpos, n1 = tpos + tneg,
    event2 = cpos, n2 = cpos + cneg,
    study = author
  )
}

test_that("meta_linear() is registered with three engines", {
  spec <- meta_linear()
  expect_s3_class(spec, c("meta_linear", "model_spec"))
  expect_identical(spec$engine, "reml")
  engines <- parsnip::show_engines("meta_linear")
  expect_setequal(engines$engine, c("reml", "dl", "fe"))
  expect_output(print(spec), "Meta-regression model specification")
  expect_error(meta_linear(mode = "classification"), "regression")
})

test_that("parsnip fits match meta_regress()", {
  es <- bcg_es()
  for (eng in c("reml", "dl", "fe")) {
    ft <- parsnip::fit(meta_linear(engine = eng), .yi ~ ablat, data = es)
    ref <- meta_regress(es, ~ ablat,
                        method = c(reml = "REML", dl = "DL", fe = "FE")[[eng]])
    expect_equal(ft$fit$estimate, ref$estimate, info = eng)
    expect_equal(ft$fit$std.error, ref$std.error)
  }
})

test_that("predictions have numeric, conf_int and pred_int types", {
  es <- bcg_es()
  ft <- parsnip::fit(meta_linear(), .yi ~ ablat, data = es)
  ref <- meta_regress(es, ~ ablat)
  nd <- data.frame(ablat = c(10, 40))
  p <- predict(ft, new_data = nd)
  expect_named(p, ".pred")
  expect_equal(p$.pred, predict(ref, newdata = nd)$.pred)
  ci <- predict(ft, new_data = nd, type = "conf_int")
  expect_named(ci, c(".pred_lower", ".pred_upper"))
  expect_equal(ci$.pred_lower, predict(ref, newdata = nd)$.pred_lower)
  pi <- predict(ft, new_data = nd, type = "pred_int")
  expect_equal(pi$.pred_upper,
               predict(ref, newdata = nd, interval = "prediction")$.pred_upper)
  expect_true(all(pi$.pred_upper >= ci$.pred_upper))
  ci90 <- predict(ft, new_data = nd, type = "conf_int", level = 0.9)
  expect_true(all(ci90$.pred_lower > ci$.pred_lower))
})

test_that("case weights replace the .vi column", {
  skip_if_not_installed("hardhat")
  es <- bcg_es()
  es$w <- hardhat::importance_weights(1 / es$.vi)
  ft <- parsnip::fit(meta_linear(engine = "dl"), .yi ~ ablat, data = es,
                     case_weights = es$w)
  ref <- meta_regress(es, ~ ablat, method = "DL")
  expect_equal(ft$fit$estimate, ref$estimate)
  expect_error(meta_linear_fit(.yi ~ ablat, data = es, weights = -es$.vi),
               "positive")
  plain <- tibble::as_tibble(es)[, c(".yi", "ablat")]
  expect_error(meta_linear_fit(.yi ~ ablat, data = plain),
               "Sampling variances are needed")
  expect_equal(meta_linear_fit(.yi ~ 1, data = es)$estimate,
               meta_pool(es)$estimate)
})

test_that("meta_linear() works inside a workflow", {
  skip_if_not_installed("workflows")
  skip_if_not_installed("hardhat")
  es <- bcg_es()
  es$w <- hardhat::importance_weights(1 / es$.vi)
  wf <- workflows::workflow() |>
    workflows::add_model(meta_linear(engine = "fe")) |>
    workflows::add_formula(.yi ~ ablat) |>
    workflows::add_case_weights(w)
  wff <- parsnip::fit(wf, data = es)
  p <- predict(wff, es[1:3, ])
  ref <- meta_regress(es, ~ ablat, method = "FE")
  expect_equal(p$.pred, predict(ref, newdata = es[1:3, ])$.pred)
})

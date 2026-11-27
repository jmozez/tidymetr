library(recipes)

printed <- function(x) {
  msg <- utils::capture.output(out <- utils::capture.output(print(x)),
                               type = "message")
  paste(c(out, msg), collapse = "\n")
}

test_that("step_meta_effect_size() matches meta_effect_size()", {
  rec <- recipe(~., data = bcg_trials) |>
    step_mutate(n_t = tpos + tneg, n_c = cpos + cneg) |>
    step_meta_effect_size(event1 = tpos, n1 = n_t, event2 = cpos,
                          n2 = n_c, measure = "RR")
  pr <- prep(rec)
  baked <- bake(pr, new_data = NULL)
  ref <- meta_effect_size(bcg_trials, "RR", event1 = tpos,
                          n1 = tpos + tneg, event2 = cpos,
                          n2 = cpos + cneg)
  expect_equal(baked$.yi, ref$.yi)
  expect_equal(baked$.vi, ref$.vi)
  new <- bake(pr, new_data = bcg_trials[1:3, ])
  expect_equal(new$.yi, ref$.yi[1:3])
  expect_true("tpos" %in% names(baked))
})

test_that("step_meta_effect_size() handles names, roles and dropping", {
  rec <- recipe(~., data = stroke_los) |>
    step_meta_effect_size(m1 = m1, sd1 = sd1, n1 = n1, m2 = m2, sd2 = sd2,
                          n2 = n2, measure = "MD", yi_name = "md",
                          vi_name = "md_var", keep_original_cols = FALSE)
  pr <- prep(rec)
  baked <- bake(pr, NULL)
  expect_equal(baked$md, stroke_los$m1 - stroke_los$m2)
  expect_false("m1" %in% names(baked))
  expect_true(all(c("md", "md_var") %in% names(baked)))
  td <- tidy(pr, 1)
  expect_s3_class(td, "tbl_df")
  expect_true(all(c("terms", "argument", "measure", "id") %in% names(td)))
  expect_setequal(td$argument, c("m1", "sd1", "n1", "m2", "sd2", "n2"))
  td0 <- tidy(rec, 1)
  expect_equal(nrow(td0), 6)
  expect_match(printed(rec), "Effect size")
  expect_match(printed(pr), "Effect size")
  expect_identical(required_pkgs(pr), c("recipes", "tidysynthesis"))
})

test_that("step_meta_effect_size() rejects bad inputs", {
  rec <- recipe(~., data = stroke_los)
  expect_error(prep(step_meta_effect_size(rec, m1, sd1, measure = "MD")),
               "named")
  expect_error(prep(step_meta_effect_size(rec, m1 = m1, measure = "MD")),
               "needs")
  expect_error(step_meta_effect_size(rec, m1 = m1, measure = "XYZ"),
               "Unknown")
})

test_that("step_meta_precision() derives precision features", {
  es <- meta_effect_size(bcg_trials, "RR", event1 = tpos,
                         n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg)
  rec <- recipe(.yi ~ .vi + ablat, data = tibble::as_tibble(es)) |>
    step_meta_precision(.vi, output = c("sei", "precision", "weight"),
                        tau2 = 0.1)
  pr <- prep(rec)
  baked <- bake(pr, NULL)
  expect_equal(baked$.vi_sei, sqrt(es$.vi))
  expect_equal(baked$.vi_precision, 1 / sqrt(es$.vi))
  expect_equal(baked$.vi_weight, 1 / (es$.vi + 0.1))
  td <- tidy(pr, 1)
  expect_equal(nrow(td), 3)
  expect_match(printed(pr), "Precision")
  rec2 <- recipe(.yi ~ ., data = tibble::as_tibble(es)) |>
    step_meta_precision(.sei, input = "sei", output = "weight",
                        keep_original_cols = FALSE)
  baked2 <- bake(prep(rec2), NULL)
  expect_equal(baked2$.sei_weight, 1 / es$.vi)
  expect_false(".sei" %in% names(baked2))
  bad <- data.frame(y = 1:2, v = c(-1, 1))
  expect_error(prep(step_meta_precision(recipe(y ~ v, data = bad), v)),
               "positive")
  expect_error(step_meta_precision(recipe(y ~ v, data = bad), v,
                                   output = "x"), "must use")
  expect_identical(required_pkgs(pr), c("recipes", "tidysynthesis"))
})

test_that("step_meta_impute_sd() fills missing standard deviations", {
  d <- stroke_los
  d$sd1[c(2, 5)] <- NA
  d$sd2[3] <- NA
  med <- bake(prep(recipe(~., data = d) |>
                     step_meta_impute_sd(sd1, sd2)), NULL)
  expect_equal(med$sd1[2], stats::median(d$sd1, na.rm = TRUE))
  expect_equal(med$sd2[3], stats::median(d$sd2, na.rm = TRUE))
  expect_equal(med$sd1[1], d$sd1[1])
  pooled <- prep(recipe(~., data = d) |>
                   step_meta_impute_sd(sd1, sd2, method = "pooled",
                                       n = c(n1, n2)))
  ok <- !is.na(d$sd1)
  expect_equal(
    bake(pooled, NULL)$sd1[5],
    sqrt(sum((d$n1[ok] - 1) * d$sd1[ok]^2) / sum(d$n1[ok] - 1))
  )
  cv <- prep(recipe(~., data = d) |>
               step_meta_impute_sd(sd1, sd2, method = "cv",
                                   means = c(m1, m2)))
  ratio <- stats::median(d$sd1[ok] / abs(d$m1[ok]))
  expect_equal(bake(cv, NULL)$sd1[2], ratio * abs(d$m1[2]))
  td <- tidy(cv, 1)
  expect_equal(td$value[1], ratio)
  expect_true(all(is.na(tidy(recipe(~., data = d) |>
                               step_meta_impute_sd(sd1), 1)$value)))
  expect_match(printed(cv), "Standard deviation imputation")
  expect_error(step_meta_impute_sd(recipe(~., data = d), sd1,
                                   method = "pooled"), "required")
  expect_error(step_meta_impute_sd(recipe(~., data = d), sd1,
                                   method = "cv"), "required")
  expect_error(prep(step_meta_impute_sd(recipe(~., data = d), sd1, sd2,
                                        method = "pooled", n = n1)),
               "one")
  expect_identical(required_pkgs(cv), c("recipes", "tidysynthesis"))
})

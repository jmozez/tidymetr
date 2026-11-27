# step_meta_effect_size -------------------------------------------------------

#' Compute effect sizes in a recipe
#'
#' `step_meta_effect_size()` creates a *specification* of a recipe step that
#' computes an effect size and its sampling variance from summary
#' statistics, using the same formulas as [meta_effect_size()]. The inputs
#' are given as named selections, for example
#' `m1 = mean_t, sd1 = sd_t, n1 = n_t`, so the names say which role each
#' column plays.
#'
#' @param recipe A recipe object. The step will be added to the sequence of
#'   operations for this recipe.
#' @param ... Named <[`tidy-select`][dplyr::dplyr_tidy_select]> selections
#'   of single columns. The names must be the inputs required by `measure`
#'   (see [meta_effect_size()]), for example `event1`, `n1`, `event2` and
#'   `n2` for `"OR"`.
#' @param measure The effect size measure.
#' @param role The role of the new columns. Defaults to `"predictor"`; use
#'   [recipes::update_role()] to make the effect size an outcome.
#' @param trained A logical to indicate if the quantities for preprocessing
#'   have been estimated.
#' @param yi_name,vi_name Names of the new effect size and variance columns.
#' @param add,to Zero cell correction, see [meta_effect_size()].
#' @param columns A named character vector of the selected columns. This is
#'   `NULL` until the step is trained by [recipes::prep()].
#' @param keep_original_cols Keep the input columns?
#' @param skip A logical. Should the step be skipped when the recipe is
#'   baked by [recipes::bake()]?
#' @param id A character string that is unique to this step to identify it.
#'
#' @return An updated version of `recipe` with the new step added to the
#'   sequence of any existing operations. [tidy()] returns a tibble with
#'   columns `terms`, `argument`, `measure` and `id`.
#' @family recipe steps
#' @export
#' @examples
#' library(recipes)
#' rec <- recipe(~., data = bcg_trials) |>
#'   step_mutate(n_t = tpos + tneg, n_c = cpos + cneg) |>
#'   step_meta_effect_size(event1 = tpos, n1 = n_t, event2 = cpos,
#'                         n2 = n_c, measure = "RR")
#' prepped <- prep(rec)
#' bake(prepped, new_data = NULL)
#' tidy(prepped, number = 2)
step_meta_effect_size <- function(recipe, ..., measure = "SMD",
                                  role = "predictor", trained = FALSE,
                                  yi_name = ".yi", vi_name = ".vi",
                                  add = 0.5, to = "only0", columns = NULL,
                                  keep_original_cols = TRUE, skip = FALSE,
                                  id = recipes::rand_id("meta_effect_size")) {
  measure <- match_measure(measure)
  if (measure == "GEN") {
    cli::cli_abort("{.arg measure} cannot be {.val GEN} in a recipe step.")
  }
  to <- arg_match(to, c("only0", "all", "none"))
  recipes::add_step(
    recipe,
    step_meta_effect_size_new(
      terms = enquos(...), measure = measure, role = role,
      trained = trained, yi_name = yi_name, vi_name = vi_name, add = add,
      to = to, columns = columns, keep_original_cols = keep_original_cols,
      skip = skip, id = id
    )
  )
}

step_meta_effect_size_new <- function(terms, measure, role, trained, yi_name,
                                      vi_name, add, to, columns,
                                      keep_original_cols, skip, id) {
  recipes::step(
    subclass = "meta_effect_size", terms = terms, measure = measure,
    role = role, trained = trained, yi_name = yi_name, vi_name = vi_name,
    add = add, to = to, columns = columns,
    keep_original_cols = keep_original_cols, skip = skip, id = id
  )
}

#' @export
prep.step_meta_effect_size <- function(x, training, info = NULL, ...) {
  sel <- tidyselect::eval_select(expr(c(!!!x$terms)), data = training)
  needed <- measure_inputs(x$measure)
  missing_args <- setdiff(needed, names(sel))
  if (length(missing_args) > 0L) {
    cli::cli_abort(
      c(
        "{.fn step_meta_effect_size} with measure {.val {x$measure}} \\
         needs named selections for {.arg {needed}}.",
        "x" = "Missing: {.arg {missing_args}}."
      )
    )
  }
  extra <- setdiff(names(sel), needed)
  if (length(extra) > 0L) {
    cli::cli_abort(
      "Unused selections for measure {.val {x$measure}}: {.arg {extra}}."
    )
  }
  columns <- stats::setNames(names(training)[sel], names(sel))
  columns <- columns[needed]
  recipes::check_type(training[, unname(columns)], types = c("double",
                                                             "integer"))
  step_meta_effect_size_new(
    terms = x$terms, measure = x$measure, role = x$role, trained = TRUE,
    yi_name = x$yi_name, vi_name = x$vi_name, add = x$add, to = x$to,
    columns = columns, keep_original_cols = x$keep_original_cols,
    skip = x$skip, id = x$id
  )
}

#' @export
bake.step_meta_effect_size <- function(object, new_data, ...) {
  recipes::check_new_data(unname(object$columns), object, new_data)
  values <- lapply(object$columns, function(col) as.double(new_data[[col]]))
  names(values) <- names(object$columns)
  es <- es_compute(object$measure, values, add = object$add, to = object$to)
  res <- tibble::tibble(!!object$yi_name := es$yi,
                        !!object$vi_name := es$vi)
  res <- recipes::check_name(res, new_data, object, names(res))
  new_data <- vctrs::vec_cbind(new_data, res)
  recipes::remove_original_cols(new_data, object, unname(object$columns))
}

#' @export
print.step_meta_effect_size <- function(x,
                                        width = max(20, options()$width - 35),
                                        ...) {
  title <- paste0("Effect sizes (", x$measure, ") from ")
  recipes::print_step(unname(x$columns), x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_meta_effect_size
#' @param x A `step_meta_effect_size` object.
#' @export
tidy.step_meta_effect_size <- function(x, ...) {
  if (recipes::is_trained(x)) {
    res <- tibble::tibble(terms = unname(x$columns),
                          argument = names(x$columns),
                          measure = x$measure)
  } else {
    res <- tibble::tibble(terms = recipes::sel2char(x$terms),
                          argument = names(x$terms),
                          measure = x$measure)
  }
  res$id <- x$id
  res
}

#' @export
required_pkgs.step_meta_effect_size <- function(x, ...) {
  c("tidysynthesis")
}

# step_meta_precision ---------------------------------------------------------

#' Precision features for meta-analytic models
#'
#' `step_meta_precision()` creates a *specification* of a recipe step that
#' turns sampling variances (or standard errors) into precision features:
#' the standard error (`"sei"`), the precision \eqn{1/SE} (`"precision"`) or
#' the inverse variance weight \eqn{1/(v + \tau^2)} (`"weight"`). Standard
#' errors and variances are the predictors of Egger and PET-PEESE type
#' models of small-study effects.
#'
#' @inheritParams step_meta_effect_size
#' @param ... One or more selector functions to choose the variance (or
#'   standard error) columns. See [recipes::selections()].
#' @param input Are the selected columns sampling variances (`"vi"`) or
#'   standard errors (`"sei"`)?
#' @param output One or more of `"sei"`, `"precision"` and `"weight"`.
#' @param tau2 Between-study variance added to the variances for
#'   `"weight"`. Use 0 for common-effect weights.
#' @param columns A character vector of the selected columns. This is `NULL`
#'   until the step is trained by [recipes::prep()].
#'
#' @return An updated version of `recipe` with the new step added. The new
#'   columns are named `<column>_<output>`. [tidy()] returns a tibble with
#'   columns `terms`, `output` and `id`.
#' @family recipe steps
#' @export
#' @examples
#' library(recipes)
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' rec <- recipe(.yi ~ .vi + ablat, data = bcg) |>
#'   step_meta_precision(.vi, output = c("sei", "weight"))
#' bake(prep(rec), new_data = NULL)
step_meta_precision <- function(recipe, ..., input = c("vi", "sei"),
                                output = "sei", tau2 = 0,
                                role = "predictor", trained = FALSE,
                                columns = NULL, keep_original_cols = TRUE,
                                skip = FALSE,
                                id = recipes::rand_id("meta_precision")) {
  input <- arg_match(input)
  output <- unique(output)
  bad <- setdiff(output, c("sei", "precision", "weight"))
  if (length(bad) > 0L || length(output) == 0L) {
    cli::cli_abort(
      "{.arg output} must use {.val sei}, {.val precision} or {.val weight}."
    )
  }
  check_number(tau2, min = 0)
  recipes::add_step(
    recipe,
    step_meta_precision_new(
      terms = enquos(...), input = input, output = output, tau2 = tau2,
      role = role, trained = trained, columns = columns,
      keep_original_cols = keep_original_cols, skip = skip, id = id
    )
  )
}

step_meta_precision_new <- function(terms, input, output, tau2, role,
                                    trained, columns, keep_original_cols,
                                    skip, id) {
  recipes::step(
    subclass = "meta_precision", terms = terms, input = input,
    output = output, tau2 = tau2, role = role, trained = trained,
    columns = columns, keep_original_cols = keep_original_cols,
    skip = skip, id = id
  )
}

#' @export
prep.step_meta_precision <- function(x, training, info = NULL, ...) {
  columns <- recipes::recipes_eval_select(x$terms, training, info)
  recipes::check_type(training[, columns], types = c("double", "integer"))
  vals <- unlist(lapply(columns, function(col) training[[col]]))
  if (any(vals <= 0, na.rm = TRUE)) {
    cli::cli_abort("Variances and standard errors must be positive.")
  }
  step_meta_precision_new(
    terms = x$terms, input = x$input, output = x$output, tau2 = x$tau2,
    role = x$role, trained = TRUE, columns = columns,
    keep_original_cols = x$keep_original_cols, skip = x$skip, id = x$id
  )
}

#' @export
bake.step_meta_precision <- function(object, new_data, ...) {
  recipes::check_new_data(object$columns, object, new_data)
  res <- list()
  for (col in object$columns) {
    v <- as.double(new_data[[col]])
    if (object$input == "sei") {
      v <- v^2
    }
    for (o in object$output) {
      res[[paste0(col, "_", o)]] <- switch(o,
        sei = sqrt(v),
        precision = 1 / sqrt(v),
        weight = 1 / (v + object$tau2)
      )
    }
  }
  res <- tibble::as_tibble(res)
  res <- recipes::check_name(res, new_data, object, names(res))
  new_data <- vctrs::vec_cbind(new_data, res)
  recipes::remove_original_cols(new_data, object, object$columns)
}

#' @export
print.step_meta_precision <- function(x, width = max(20, options()$width - 35),
                                      ...) {
  title <- paste0("Precision features (", paste(x$output, collapse = ", "),
                  ") from ")
  recipes::print_step(x$columns, x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_meta_precision
#' @param x A `step_meta_precision` object.
#' @export
tidy.step_meta_precision <- function(x, ...) {
  terms <- if (recipes::is_trained(x)) x$columns else
    recipes::sel2char(x$terms)
  res <- tidyr_expand(terms, x$output)
  res$id <- x$id
  res
}

tidyr_expand <- function(terms, output) {
  grid <- expand.grid(output = output, terms = terms,
                      stringsAsFactors = FALSE)
  tibble::tibble(terms = grid$terms, output = grid$output)
}

#' @export
required_pkgs.step_meta_precision <- function(x, ...) {
  c("tidysynthesis")
}

# step_meta_impute_sd ---------------------------------------------------------

#' Impute missing standard deviations
#'
#' `step_meta_impute_sd()` creates a *specification* of a recipe step that
#' fills in missing standard deviations, a common problem when extracting
#' continuous outcomes for meta-analysis. The imputation values are learned
#' from the studies that do report them (in the training set):
#'
#' * `"median"` uses the median of the reported standard deviations
#'   (Furukawa et al., 2006).
#' * `"pooled"` uses the pooled standard deviation
#'   \eqn{\sqrt{\sum (n_i - 1) s_i^2 / \sum (n_i - 1)}}; supply the sample
#'   size columns in `n`, in the same order as the selected columns.
#' * `"cv"` multiplies the absolute mean of each study by the median
#'   coefficient of variation; supply the mean columns in `means`.
#'
#' @inheritParams step_meta_effect_size
#' @param ... One or more selector functions to choose the standard
#'   deviation columns. See [recipes::selections()].
#' @param method `"median"`, `"pooled"` or `"cv"`.
#' @param n,means <[`tidy-select`][dplyr::dplyr_tidy_select]> Sample size or
#'   mean columns paired, in order, with the selected standard deviation
#'   columns. Needed for `method = "pooled"` and `method = "cv"`.
#' @param role Not used by this step since no new variables are created.
#' @param columns,pairs,values Learned by [recipes::prep()]: the selected
#'   columns, their paired columns and the imputation values.
#'
#' @return An updated version of `recipe` with the new step added. [tidy()]
#'   returns a tibble with columns `terms`, `method`, `value` and `id`.
#' @references
#' Furukawa, T. A., Barbui, C., Cipriani, A., Brambilla, P. and Watanabe,
#' N. (2006). Imputing missing standard deviations in meta-analyses can
#' provide accurate results. *Journal of Clinical Epidemiology*, 59(1),
#' 7-10. \doi{10.1016/j.jclinepi.2005.06.006}
#' @family recipe steps
#' @export
#' @examples
#' library(recipes)
#' dat <- stroke_los
#' dat$sd1[c(2, 5)] <- NA
#' rec <- recipe(~., data = dat) |>
#'   step_meta_impute_sd(sd1, method = "pooled", n = n1)
#' bake(prep(rec), new_data = NULL)
step_meta_impute_sd <- function(recipe, ..., method = c("median", "pooled",
                                                         "cv"),
                                n = NULL, means = NULL, role = NA,
                                trained = FALSE, columns = NULL,
                                pairs = NULL, values = NULL, skip = FALSE,
                                id = recipes::rand_id("meta_impute_sd")) {
  method <- arg_match(method)
  n <- enquo(n)
  means <- enquo(means)
  if (method == "pooled" && quo_is_null(n)) {
    cli::cli_abort("{.arg n} is required when {.code method = \"pooled\"}.")
  }
  if (method == "cv" && quo_is_null(means)) {
    cli::cli_abort("{.arg means} is required when {.code method = \"cv\"}.")
  }
  # Selections are stored as lists of quosures (or NULL) so that recipes
  # can inspect the step arguments.
  n <- if (quo_is_null(n)) NULL else list(n)
  means <- if (quo_is_null(means)) NULL else list(means)
  recipes::add_step(
    recipe,
    step_meta_impute_sd_new(
      terms = enquos(...), method = method, n = n, means = means,
      role = role, trained = trained, columns = columns, pairs = pairs,
      values = values, skip = skip, id = id
    )
  )
}

step_meta_impute_sd_new <- function(terms, method, n, means, role, trained,
                                    columns, pairs, values, skip, id) {
  recipes::step(
    subclass = "meta_impute_sd", terms = terms, method = method, n = n,
    means = means, role = role, trained = trained, columns = columns,
    pairs = pairs, values = values, skip = skip, id = id
  )
}

#' @export
prep.step_meta_impute_sd <- function(x, training, info = NULL, ...) {
  columns <- recipes::recipes_eval_select(x$terms, training, info)
  recipes::check_type(training[, columns], types = c("double", "integer"))
  pairs <- NULL
  if (x$method %in% c("pooled", "cv")) {
    pair_quo <- (if (x$method == "pooled") x$n else x$means)[[1]]
    loc <- tidyselect::eval_select(pair_quo, training)
    pairs <- names(training)[loc]
    if (length(pairs) != length(columns)) {
      cli::cli_abort(
        c(
          "Select one paired column for each standard deviation column.",
          "x" = "{length(columns)} standard deviation column{?s} but \\
                 {length(pairs)} paired column{?s}."
        )
      )
    }
    names(pairs) <- columns
  }
  values <- vapply(columns, function(col) {
    s <- training[[col]]
    ok <- !is.na(s)
    if (!any(ok)) {
      cli::cli_abort("Column {.field {col}} has no observed values.")
    }
    switch(x$method,
      median = stats::median(s[ok]),
      pooled = {
        nn <- training[[pairs[[col]]]]
        ok <- ok & !is.na(nn)
        sqrt(sum((nn[ok] - 1) * s[ok]^2) / sum(nn[ok] - 1))
      },
      cv = {
        m <- training[[pairs[[col]]]]
        ok <- ok & !is.na(m) & m != 0
        stats::median(s[ok] / abs(m[ok]))
      }
    )
  }, numeric(1))
  step_meta_impute_sd_new(
    terms = x$terms, method = x$method, n = x$n, means = x$means,
    role = x$role, trained = TRUE, columns = columns, pairs = pairs,
    values = values, skip = x$skip, id = x$id
  )
}

#' @export
bake.step_meta_impute_sd <- function(object, new_data, ...) {
  needed <- c(object$columns, if (object$method == "cv") object$pairs)
  recipes::check_new_data(unname(needed), object, new_data)
  for (col in object$columns) {
    s <- new_data[[col]]
    miss <- is.na(s)
    if (!any(miss)) {
      next
    }
    fill <- if (object$method == "cv") {
      object$values[[col]] * abs(new_data[[object$pairs[[col]]]][miss])
    } else {
      object$values[[col]]
    }
    s <- as.double(s)
    s[miss] <- fill
    new_data[[col]] <- s
  }
  new_data
}

#' @export
print.step_meta_impute_sd <- function(x, width = max(20, options()$width - 35),
                                      ...) {
  title <- paste0("Standard deviation imputation (", x$method, ") for ")
  recipes::print_step(x$columns, x$terms, x$trained, title, width)
  invisible(x)
}

#' @rdname step_meta_impute_sd
#' @param x A `step_meta_impute_sd` object.
#' @export
tidy.step_meta_impute_sd <- function(x, ...) {
  if (recipes::is_trained(x)) {
    res <- tibble::tibble(terms = unname(x$columns), method = x$method,
                          value = unname(x$values))
  } else {
    terms <- recipes::sel2char(x$terms)
    res <- tibble::tibble(terms = terms, method = x$method,
                          value = rep(NA_real_, length(terms)))
  }
  res$id <- x$id
  res
}

#' @export
required_pkgs.step_meta_impute_sd <- function(x, ...) {
  c("tidysynthesis")
}

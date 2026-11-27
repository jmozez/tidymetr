#' Meta-regression model specification for parsnip
#'
#' `meta_linear()` defines a mixed-effects meta-regression for use with
#' `parsnip`, `workflows` and `tune`. The outcome is the effect size and
#' the predictors are study level moderators. The inverse sampling
#' variances enter as case weights, for example with
#' `hardhat::importance_weights(1 / vi)`; if no case weights are given, a
#' column named `.vi` in the training data is used.
#'
#' @section Engines:
#' \describe{
#'   \item{`"reml"`}{Random effects with \eqn{\tau^2} estimated by
#'     restricted maximum likelihood (the default).}
#'   \item{`"dl"`}{Random effects with the DerSimonian-Laird estimator.}
#'   \item{`"fe"`}{Common effect (fixed effect) meta-regression.}
#' }
#'
#' @param mode A single character string for the model mode. Only
#'   `"regression"` is available.
#' @param engine A single character string for the engine: `"reml"`, `"dl"`
#'   or `"fe"`.
#'
#' @return A `meta_linear` model specification.
#' @export
#' @examples
#' library(parsnip)
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' spec <- meta_linear(engine = "reml")
#' spec
#' fitted <- fit(spec, .yi ~ ablat, data = bcg)
#' predict(fitted, new_data = data.frame(ablat = c(10, 40)))
meta_linear <- function(mode = "regression", engine = "reml") {
  if (mode != "regression") {
    cli::cli_abort("{.arg mode} must be {.val regression}.")
  }
  parsnip::new_model_spec(
    "meta_linear",
    args = list(),
    eng_args = NULL,
    mode = mode,
    user_specified_mode = !missing(mode),
    method = NULL,
    engine = engine,
    user_specified_engine = !missing(engine)
  )
}

#' @export
print.meta_linear <- function(x, ...) {
  cli::cat_line("Meta-regression model specification (", x$mode, ")")
  cli::cat_line("")
  if (!is.null(x$engine)) {
    cli::cat_line("Computational engine: ", x$engine)
  }
  invisible(x)
}

#' Fit function used by the meta_linear() engines
#'
#' `meta_linear_fit()` is called by `parsnip` to fit [meta_linear()]
#' models. It is exported so `parsnip` can find it; most users will not call
#' it directly.
#'
#' @param formula A model formula with the effect size on the left.
#' @param data The training data.
#' @param weights Inverse variance case weights. When `NULL`, the `.vi`
#'   column of `data` is used.
#' @param method The estimator passed to [meta_regress()].
#' @param test `"z"` or `"hksj"`.
#' @param level Confidence level.
#'
#' @return A [`<meta_fit>`][new_meta_fit()].
#' @keywords internal
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_linear_fit(.yi ~ ablat, data = bcg, weights = 1 / bcg$.vi)
meta_linear_fit <- function(formula, data, weights = NULL, method = "REML",
                            test = "z", level = 0.95) {
  method <- match_method(method)
  test <- match_test(test)
  if (!is.null(weights)) {
    w <- as.double(vctrs::vec_data(weights))
    if (any(w <= 0, na.rm = TRUE)) {
      cli::cli_abort("Inverse variance case weights must be positive.")
    }
    vi <- 1 / w
  } else if (".vi" %in% names(data)) {
    vi <- data$.vi
  } else {
    cli::cli_abort(
      c(
        "Sampling variances are needed to fit {.fn meta_linear}.",
        "i" = "Supply inverse variance case weights, for example \\
               {.code hardhat::importance_weights(1 / vi)}, or a {.field .vi} \\
               column."
      )
    )
  }
  mf <- model.frame(formula, data = data, na.action = na.pass)
  yi <- model.response(mf)
  tt <- delete.response(terms(mf))
  data2 <- as_bare_tibble(data)
  data2$.tidysynthesis_yi <- yi
  data2$.tidysynthesis_vi <- vi
  labels <- attr(tt, "term.labels")
  mods <- if (length(labels) == 0L) {
    ~1
  } else {
    stats::reformulate(labels, intercept = attr(tt, "intercept") == 1)
  }
  meta_regress(data2, mods = mods, yi = .data$.tidysynthesis_yi,
               vi = .data$.tidysynthesis_vi, method = method, test = test,
               level = level)
}

register_meta_linear <- function() {
  current <- parsnip::get_model_env()
  if ("meta_linear" %in% current$models) {
    return(invisible(FALSE))
  }
  parsnip::set_new_model("meta_linear")
  parsnip::set_model_mode("meta_linear", "regression")
  engines <- c(reml = "REML", dl = "DL", fe = "FE")
  for (eng in names(engines)) {
    parsnip::set_model_engine("meta_linear", "regression", eng)
    parsnip::set_dependency("meta_linear", eng, "tidysynthesis",
                            mode = "regression")
    parsnip::set_fit(
      model = "meta_linear", eng = eng, mode = "regression",
      value = list(
        interface = "formula",
        protect = c("formula", "data", "weights"),
        func = c(pkg = "tidysynthesis", fun = "meta_linear_fit"),
        defaults = list(method = engines[[eng]])
      )
    )
    parsnip::set_encoding(
      model = "meta_linear", eng = eng, mode = "regression",
      options = list(
        predictor_indicators = "none",
        compute_intercept = FALSE,
        remove_intercept = FALSE,
        allow_sparse_x = FALSE
      )
    )
    parsnip::set_pred(
      model = "meta_linear", eng = eng, mode = "regression",
      type = "numeric",
      value = list(
        pre = NULL,
        post = function(results, object) results$.pred,
        func = c(fun = "predict"),
        args = list(
          object = quote(object$fit),
          newdata = quote(new_data),
          interval = "none"
        )
      )
    )
    parsnip::set_pred(
      model = "meta_linear", eng = eng, mode = "regression",
      type = "conf_int",
      value = list(
        pre = NULL,
        post = function(results, object) {
          tibble::tibble(.pred_lower = results$.pred_lower,
                         .pred_upper = results$.pred_upper)
        },
        func = c(fun = "predict"),
        args = list(
          object = quote(object$fit),
          newdata = quote(new_data),
          interval = "confidence",
          level = quote(level)
        )
      )
    )
    parsnip::set_pred(
      model = "meta_linear", eng = eng, mode = "regression",
      type = "pred_int",
      value = list(
        pre = NULL,
        post = function(results, object) {
          tibble::tibble(.pred_lower = results$.pred_lower,
                         .pred_upper = results$.pred_upper)
        },
        func = c(fun = "predict"),
        args = list(
          object = quote(object$fit),
          newdata = quote(new_data),
          interval = "prediction",
          level = quote(level)
        )
      )
    )
  }
  invisible(TRUE)
}

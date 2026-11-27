# Shared helper: evaluate an optional column inside a (possibly grouped)
# summarise call and return a yardstick style tibble.
meta_metric_summarise <- function(data, name, fn, truth, estimate,
                                  extra = list(), na_rm = TRUE,
                                  case_weights = quo(NULL)) {
  cw_null <- quo_is_null(case_weights)
  extra_exprs <- lapply(extra, function(q) {
    if (is.null(q) || quo_is_null(q)) NULL else q
  })
  out <- dplyr::summarise(
    data,
    .metric = name,
    .estimator = "standard",
    .estimate = inject(fn(
      truth = !!truth,
      estimate = !!estimate,
      !!!extra_exprs,
      na_rm = na_rm,
      case_weights = !!(if (cw_null) quote(NULL) else case_weights)
    ))
  )
  tibble::as_tibble(out)
}

# inverse_var_rmse ------------------------------------------------------------

#' Inverse variance weighted root mean squared error
#'
#' `inverse_var_rmse()` is a `yardstick` numeric metric for predictions of
#' study level effect sizes. Each squared error is weighted by the inverse
#' of the study's sampling variance, so precise studies count for more,
#' exactly as they do in the meta-analytic model. Weights come from the
#' `variance` column, or from `case_weights` (for example
#' `hardhat::importance_weights(1 / vi)`) when `variance` is not given.
#'
#' @param data A data frame with the columns given in `truth`, `estimate`
#'   and `variance`.
#' @param truth <[`data-masking`][rlang::args_data_masking]> Observed effect
#'   sizes.
#' @param estimate <[`data-masking`][rlang::args_data_masking]> Predicted
#'   effect sizes.
#' @param variance <[`data-masking`][rlang::args_data_masking]> Sampling
#'   variances. For the `_vec()` function, a numeric vector.
#' @param na_rm A logical value indicating whether `NA` values should be
#'   stripped before the computation proceeds.
#' @param case_weights <[`data-masking`][rlang::args_data_masking]> Optional
#'   case weights, used when `variance` is `NULL`.
#' @param ... Not currently used.
#'
#' @return A tibble with columns `.metric`, `.estimator` and `.estimate`
#'   (one row per group for grouped data). `inverse_var_rmse_vec()` returns
#'   a single number.
#' @family meta metrics
#' @export
#' @examples
#' df <- data.frame(obs = c(0.1, 0.4, -0.2), pred = c(0.2, 0.3, 0),
#'                  v = c(0.01, 0.04, 0.02))
#' inverse_var_rmse(df, obs, pred, variance = v)
#' inverse_var_rmse_vec(df$obs, df$pred, variance = df$v)
inverse_var_rmse <- function(data, ...) {
  UseMethod("inverse_var_rmse")
}
inverse_var_rmse <- yardstick::new_numeric_metric(
  inverse_var_rmse,
  direction = "minimize"
)

#' @rdname inverse_var_rmse
#' @export
inverse_var_rmse.data.frame <- function(data, truth, estimate,
                                        variance = NULL, na_rm = TRUE,
                                        case_weights = NULL, ...) {
  meta_metric_summarise(
    data, "inverse_var_rmse", inverse_var_rmse_vec,
    truth = enquo(truth), estimate = enquo(estimate),
    extra = list(variance = enquo(variance)), na_rm = na_rm,
    case_weights = enquo(case_weights)
  )
}

#' @rdname inverse_var_rmse
#' @export
inverse_var_rmse_vec <- function(truth, estimate, variance = NULL,
                                 na_rm = TRUE, case_weights = NULL, ...) {
  yardstick::check_numeric_metric(truth, estimate, case_weights)
  w <- metric_weights(variance, case_weights, length(truth))
  keep <- !(is.na(truth) | is.na(estimate) | is.na(w))
  if (!all(keep)) {
    if (!na_rm) {
      return(NA_real_)
    }
    truth <- truth[keep]
    estimate <- estimate[keep]
    w <- w[keep]
  }
  sqrt(sum(w * (truth - estimate)^2) / sum(w))
}

metric_weights <- function(variance, case_weights, n,
                           call = caller_env()) {
  if (!is.null(variance)) {
    if (!is.numeric(variance) || length(variance) != n) {
      cli::cli_abort(
        "{.arg variance} must be numeric with one value per prediction.",
        call = call
      )
    }
    if (any(variance <= 0, na.rm = TRUE)) {
      cli::cli_abort("{.arg variance} must be positive.", call = call)
    }
    return(1 / variance)
  }
  if (!is.null(case_weights)) {
    return(as.double(vctrs::vec_data(case_weights)))
  }
  cli::cli_abort(
    c(
      "Inverse variance weights are needed.",
      "i" = "Supply {.arg variance} or {.arg case_weights}."
    ),
    call = call
  )
}

# coverage_prob ---------------------------------------------------------------

#' Coverage probability of interval predictions
#'
#' `coverage_prob()` is a `yardstick` numeric metric giving the share of
#' observed values that fall inside Wald intervals
#' \eqn{\hat y \pm z_{(1 + level)/2} SE}. Use the prediction standard error,
#' \eqn{\sqrt{SE^2 + \tau^2 + v_i}}, to check the calibration of prediction
#' intervals for new studies. A well calibrated model has coverage close to
#' `level`.
#'
#' @inheritParams inverse_var_rmse
#' @param std_error <[`data-masking`][rlang::args_data_masking]> Standard
#'   errors of the predictions. For the `_vec()` function, a numeric vector.
#' @param level The nominal level of the intervals.
#'
#' @return A tibble with columns `.metric`, `.estimator` and `.estimate`.
#'   `coverage_prob_vec()` returns a single number between 0 and 1.
#' @family meta metrics
#' @export
#' @examples
#' df <- data.frame(obs = c(0.1, 0.4, -0.2, 0.9), pred = c(0.2, 0.3, 0, 0.1),
#'                  se = c(0.1, 0.2, 0.15, 0.2))
#' coverage_prob(df, obs, pred, std_error = se)
coverage_prob <- function(data, ...) {
  UseMethod("coverage_prob")
}
coverage_prob <- yardstick::new_numeric_metric(
  coverage_prob,
  direction = "maximize"
)

#' @rdname coverage_prob
#' @export
coverage_prob.data.frame <- function(data, truth, estimate, std_error,
                                     level = 0.95, na_rm = TRUE,
                                     case_weights = NULL, ...) {
  check_level(level)
  meta_metric_summarise(
    data, "coverage_prob", coverage_prob_vec,
    truth = enquo(truth), estimate = enquo(estimate),
    extra = list(std_error = enquo(std_error), level = quo(!!level)),
    na_rm = na_rm, case_weights = enquo(case_weights)
  )
}

#' @rdname coverage_prob
#' @export
coverage_prob_vec <- function(truth, estimate, std_error, level = 0.95,
                              na_rm = TRUE, case_weights = NULL, ...) {
  yardstick::check_numeric_metric(truth, estimate, case_weights)
  check_level(level)
  if (!is.numeric(std_error) || length(std_error) != length(truth)) {
    cli::cli_abort(
      "{.arg std_error} must be numeric with one value per prediction."
    )
  }
  w <- if (is.null(case_weights)) rep(1, length(truth)) else
    as.double(vctrs::vec_data(case_weights))
  keep <- !(is.na(truth) | is.na(estimate) | is.na(std_error) | is.na(w))
  if (!all(keep)) {
    if (!na_rm) {
      return(NA_real_)
    }
    truth <- truth[keep]
    estimate <- estimate[keep]
    std_error <- std_error[keep]
    w <- w[keep]
  }
  z <- qnorm(1 - (1 - level) / 2)
  inside <- abs(truth - estimate) <= z * std_error
  sum(w * inside) / sum(w)
}

# heterogeneity_r2 ------------------------------------------------------------

#' Proportion of heterogeneity explained by predictions
#'
#' `heterogeneity_r2()` is a `yardstick` numeric metric that measures how
#' much of the between-study heterogeneity a model explains. The total
#' heterogeneity \eqn{\tau^2_0} is the DerSimonian-Laird estimate for the
#' observed effect sizes. The residual heterogeneity is the matching moment
#' estimate around the predictions,
#' \eqn{\tau^2_r = \max\{0, (Q_r - (k - 1)) / (\sum w_i - \sum w_i^2 /
#' \sum w_i)\}} with \eqn{Q_r = \sum w_i (y_i - \hat y_i)^2} and
#' \eqn{w_i = 1 / v_i}. Both estimates use the same scaling, so predicting
#' the weighted mean for every study gives 0 and perfect predictions give 1.
#' The metric is \eqn{\max(0, 1 - \tau^2_r / \tau^2_0)}, the
#' out-of-sample analogue of the pseudo \eqn{R^2} of meta-regression
#' (Raudenbush, 2009). It is `NA` when there is no heterogeneity to
#' explain.
#'
#' @inheritParams inverse_var_rmse
#' @param case_weights Not supported. Must be `NULL`.
#'
#' @return A tibble with columns `.metric`, `.estimator` and `.estimate`.
#'   `heterogeneity_r2_vec()` returns a single number between 0 and 1.
#' @family meta metrics
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' fit <- meta_regress(bcg, ~ ablat)
#' bcg$pred <- predict(fit, newdata = bcg)$.pred
#' heterogeneity_r2(bcg, .yi, pred, variance = .vi)
heterogeneity_r2 <- function(data, ...) {
  UseMethod("heterogeneity_r2")
}
heterogeneity_r2 <- yardstick::new_numeric_metric(
  heterogeneity_r2,
  direction = "maximize"
)

#' @rdname heterogeneity_r2
#' @export
heterogeneity_r2.data.frame <- function(data, truth, estimate, variance,
                                        na_rm = TRUE, case_weights = NULL,
                                        ...) {
  meta_metric_summarise(
    data, "heterogeneity_r2", heterogeneity_r2_vec,
    truth = enquo(truth), estimate = enquo(estimate),
    extra = list(variance = enquo(variance)), na_rm = na_rm,
    case_weights = enquo(case_weights)
  )
}

#' @rdname heterogeneity_r2
#' @export
heterogeneity_r2_vec <- function(truth, estimate, variance, na_rm = TRUE,
                                 case_weights = NULL, ...) {
  yardstick::check_numeric_metric(truth, estimate, case_weights)
  if (!is.null(case_weights)) {
    cli::cli_abort("{.fn heterogeneity_r2} does not support case weights.")
  }
  w <- metric_weights(variance, NULL, length(truth))
  keep <- !(is.na(truth) | is.na(estimate) | is.na(w))
  if (!all(keep)) {
    if (!na_rm) {
      return(NA_real_)
    }
    truth <- truth[keep]
    estimate <- estimate[keep]
    w <- w[keep]
  }
  k <- length(truth)
  if (k < 2L) {
    return(NA_real_)
  }
  mu <- sum(w * truth) / sum(w)
  q0 <- sum(w * (truth - mu)^2)
  tau2_0 <- max(0, (q0 - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
  if (tau2_0 <= 0) {
    cli::cli_warn(
      "There is no between-study heterogeneity to explain; returning NA."
    )
    return(NA_real_)
  }
  qr <- sum(w * (truth - estimate)^2)
  tau2_r <- max(0, (qr - (k - 1)) / (sum(w) - sum(w^2) / sum(w)))
  max(0, 1 - tau2_r / tau2_0)
}

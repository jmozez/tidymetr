#' Tidy, glance and augment meta-analytic fits
#'
#' `broom` style tidiers for [`<meta_fit>`][new_meta_fit()] objects.
#' `tidy()` returns the coefficient table, `glance()` a one row summary of
#' heterogeneity and fit statistics, and `augment()` the study level data
#' with fitted values, residuals and diagnostics.
#'
#' @param x A `<meta_fit>`.
#' @param exponentiate Exponentiate the estimates and confidence limits?
#'   Useful for log risk, odds and rate ratios.
#' @param data Optional data to augment. Defaults to the data used in the
#'   fit (with the filled studies for [meta_trimfill()]).
#' @param ... Not used.
#'
#' @return `tidy()` and `augment()` return tibbles. `glance()` returns a one
#'   row tibble with `nobs`, `method`, `test`, `tau2`, its Q-profile
#'   confidence limits (`tau2.low`, `tau2.high`), `tau`, `I2`, `H2`, `R2`,
#'   `QE`, `df.residual`, `p.QE`, `QM`, `p.QM`, the prediction interval
#'   (`pred.low`, `pred.high`), `logLik`, `AIC` and `BIC`, plus
#'   model specific columns (subgroup tests, variance components or the
#'   number of filled studies). `augment()` adds `.study`, `.yi`, `.vi`,
#'   `.fitted`, `.resid`, `.std_resid`, `.hat`, `.weight` (in percent) and
#'   `.blup` (the empirical Bayes estimate of each study's true effect).
#' @name meta_fit_tidiers
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' fit <- meta_pool(bcg)
#' tidy(fit, exponentiate = TRUE)
#' glance(fit)
#' augment(fit)
NULL

#' @rdname meta_fit_tidiers
#' @export
tidy.meta_fit <- function(x, exponentiate = FALSE, ...) {
  out <- as_bare_tibble(x)
  if (isTRUE(exponentiate)) {
    out$estimate <- exp(out$estimate)
    out$conf.low <- exp(out$conf.low)
    out$conf.high <- exp(out$conf.high)
  }
  out
}

#' @rdname meta_fit_tidiers
#' @export
glance.meta_fit <- function(x, ...) {
  info <- fit_info(x)
  ll <- info$logLik %||% NA_real_
  npar <- info$npar %||% NA_real_
  n_bic <- if (identical(info$method, "REML")) info$k - info$p else info$k
  out <- tibble::tibble(
    model_type = info$model_type,
    nobs = as.integer(info$k),
    method = info$method,
    test = info$test,
    tau2 = info$tau2 %||% NA_real_,
    tau2.low = (info$tau2_ci %||% c(NA_real_, NA_real_))[1],
    tau2.high = (info$tau2_ci %||% c(NA_real_, NA_real_))[2],
    tau = sqrt(info$tau2 %||% NA_real_),
    I2 = info$I2 %||% NA_real_,
    H2 = info$H2 %||% NA_real_,
    R2 = info$R2 %||% NA_real_,
    QE = info$QE %||% NA_real_,
    df.residual = as.integer(info$df_resid %||% NA),
    p.QE = info$QEp %||% NA_real_,
    QM = info$QM %||% NA_real_,
    p.QM = info$QMp %||% NA_real_,
    pred.low = unname(info$pi_low %||% NA_real_),
    pred.high = unname(info$pi_high %||% NA_real_),
    logLik = ll,
    AIC = -2 * ll + 2 * npar,
    BIC = -2 * ll + npar * log(n_bic)
  )
  if (info$model_type == "subgroup") {
    out$Q.between <- info$Q_between
    out$df.between <- as.integer(info$df_between)
    out$p.between <- info$p_between
    out$tau2_type <- info$tau2_type
  }
  if (info$model_type == "multilevel") {
    for (nm in names(info$sigma2)) {
      out[[paste0("sigma2_", nm)]] <- info$sigma2[[nm]]
      out[[paste0("I2_", nm)]] <- info$I2_levels[[nm]]
    }
  }
  if (info$model_type == "trimfill") {
    out$k0 <- info$k0
    out$se.k0 <- info$se_k0
    out$side <- info$side
    out$estimator <- info$estimator
  }
  out
}

#' @rdname meta_fit_tidiers
#' @export
augment.meta_fit <- function(x, data = NULL, ...) {
  info <- fit_info(x)
  base <- data %||% info$data
  base <- as_bare_tibble(base)
  if (nrow(base) != length(info$yi)) {
    cli::cli_abort(
      "{.arg data} must have {length(info$yi)} rows, one per study."
    )
  }
  resid <- info$yi - info$fitted
  if (info$model_type == "multilevel") {
    var_resid <- diag(info$V) - diag(info$X %*% info$vb %*% t(info$X))
  } else {
    var_resid <- (1 - info$hat) / info$weights
  }
  tau2 <- if (info$model_type == "subgroup" &&
                info$tau2_type == "separate") {
    fits <- info$subgroup_fits
    t2 <- numeric(length(info$yi))
    for (f in fits) {
      t2[f$idx] <- f$tau2
    }
    t2
  } else {
    info$tau2 %||% NA_real_
  }
  blup <- info$fitted + tau2 / (tau2 + info$vi) * resid
  base$.study <- info$study
  base$.yi <- info$yi
  base$.vi <- info$vi
  if (".sei" %in% names(base)) {
    base$.sei <- sqrt(info$vi)
  }
  base$.fitted <- info$fitted
  base$.resid <- resid
  base$.std_resid <- resid / sqrt(pmax(var_resid, 0))
  base$.hat <- info$hat
  base$.weight <- 100 * info$weights / sum(info$weights)
  base$.blup <- if (info$model_type == "multilevel") NA_real_ else blup
  if (info$model_type == "trimfill") {
    base$.filled <- info$filled
  }
  base
}

#' Predictions from meta-analytic models
#'
#' Predicted (average) effects with confidence or prediction intervals. For
#' models with moderators, `newdata` supplies the moderator values; for
#' models without moderators the pooled estimate is returned. Prediction
#' intervals add the between-study variance to the variance of the
#' prediction.
#'
#' @param object A [`<meta_fit>`][new_meta_fit()].
#' @param newdata Optional data frame of moderator values (or, for
#'   [meta_subgroup()] fits, of the grouping variable).
#' @param interval `"confidence"`, `"prediction"` or `"none"`.
#' @param level Confidence level. Defaults to the level of the fit.
#' @param ... Not used.
#'
#' @return A tibble with `.pred`, `.se` and, unless `interval = "none"`,
#'   `.pred_lower` and `.pred_upper`. Without `newdata`, models with
#'   moderators return one row per study and models without moderators a
#'   single row.
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' fit <- meta_regress(bcg, ~ ablat)
#' predict(fit, newdata = data.frame(ablat = c(10, 50)),
#'         interval = "prediction")
predict.meta_fit <- function(object, newdata = NULL,
                             interval = c("confidence", "prediction",
                                          "none"),
                             level = NULL, ...) {
  interval <- arg_match(interval)
  info <- fit_info(object)
  level <- level %||% info$level
  check_level(level)
  if (info$model_type == "subgroup") {
    return(predict_subgroup(object, info, newdata, interval, level))
  }
  X <- new_model_matrix(info, newdata)
  pred <- c(X %*% info$beta)
  se <- sqrt(rowSums((X %*% info$vb) * X))
  crit <- if (info$test %in% c("hksj", "t")) {
    qt(1 - (1 - level) / 2, info$ddf)
  } else {
    qnorm(1 - (1 - level) / 2)
  }
  out <- tibble::tibble(.pred = unname(c(pred)), .se = unname(c(se)))
  if (interval == "none") {
    return(out)
  }
  het <- if (info$model_type == "multilevel") sum(info$sigma2) else
    info$tau2
  width <- if (interval == "confidence") se else sqrt(se^2 + het)
  out$.pred_lower <- unname(c(pred - crit * width))
  out$.pred_upper <- unname(c(pred + crit * width))
  out
}

new_model_matrix <- function(info, newdata) {
  intercept_only <- identical(colnames(info$X), "overall")
  if (is.null(newdata)) {
    if (intercept_only) {
      return(matrix(1, nrow = 1, ncol = 1))
    }
    return(info$X)
  }
  if (is.null(info$terms) || identical(colnames(info$X), "overall")) {
    return(matrix(1, nrow = max(1L, nrow(newdata)), ncol = 1))
  }
  tt <- delete.response(info$terms)
  mf <- model.frame(tt, newdata, xlev = info$xlevels, na.action = na.pass)
  model.matrix(tt, mf, contrasts.arg = info$contrasts)
}

predict_subgroup <- function(object, info, newdata, interval, level) {
  tab <- as_bare_tibble(object)
  g <- if (is.null(newdata)) {
    as.character(info$group)
  } else {
    if (!info$group_name %in% names(newdata)) {
      cli::cli_abort(
        "{.arg newdata} must contain the grouping column \\
         {.field {info$group_name}}."
      )
    }
    as.character(newdata[[info$group_name]])
  }
  idx <- match(g, tab$term)
  out <- tibble::tibble(.pred = tab$estimate[idx], .se = tab$std.error[idx])
  if (interval == "none") {
    return(out)
  }
  crit <- qnorm(1 - (1 - level) / 2)
  het <- if (interval == "prediction") {
    if (info$tau2_type == "common") info$tau2 else tab$tau2[idx]
  } else {
    0
  }
  width <- sqrt(out$.se^2 + het)
  out$.pred_lower <- unname(out$.pred - crit * width)
  out$.pred_upper <- unname(out$.pred + crit * width)
  out
}

#' Tidy, glance and augment network meta-analyses
#'
#' `broom` style tidiers for [`<meta_nma>`][new_meta_nma()] objects.
#'
#' @param x A `<meta_nma>`.
#' @param type What to return: `"effects"` (each treatment against the
#'   reference, with P-scores), `"league"` (every pairwise comparison),
#'   `"split"` (direct and indirect evidence for each comparison with direct
#'   evidence), `"inconsistency"` (the decomposition of Q) or `"designs"`
#'   (the heterogeneity within each design).
#' @param exponentiate Exponentiate estimates and confidence limits?
#' @param ... Not used.
#'
#' @return `tidy()` returns a tibble whose columns depend on `type`.
#'   `glance()` returns a one row summary of the network. `augment()`
#'   returns the contrast level data with network estimates (`.fitted`) and
#'   residuals (`.resid`).
#' @name meta_nma_tidiers
#' @examples
#' pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
#' nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
#'   reference = "no_contact", small_values = "bad")
#' tidy(nma)
#' tidy(nma, type = "split")
#' glance(nma)
#' augment(nma)
NULL

#' @rdname meta_nma_tidiers
#' @export
tidy.meta_nma <- function(x, type = c("effects", "league", "split",
                                      "inconsistency", "designs"),
                          exponentiate = FALSE, ...) {
  type <- arg_match(type)
  info <- nma_info(x)
  out <- switch(type,
    effects = as_bare_tibble(x),
    league = info$league,
    split = info$split,
    inconsistency = tibble::tibble(
      source = c("total", "within designs", "between designs"),
      Q = c(info$Q, info$Q_heterogeneity, info$Q_inconsistency),
      df = as.integer(c(info$Q_df, info$df_heterogeneity,
                        info$df_inconsistency)),
      p.value = c(info$Q_p, info$p_heterogeneity, info$p_inconsistency)
    ),
    designs = info$designs
  )
  if (isTRUE(exponentiate) && type %in% c("effects", "league")) {
    for (col in c("estimate", "conf.low", "conf.high")) {
      out[[col]] <- exp(out[[col]])
    }
  }
  if (isTRUE(exponentiate) && type == "split") {
    for (col in c("network", "direct", "indirect")) {
      out[[col]] <- exp(out[[col]])
    }
  }
  out
}

#' @rdname meta_nma_tidiers
#' @export
glance.meta_nma <- function(x, ...) {
  info <- nma_info(x)
  tibble::tibble(
    n_studies = as.integer(info$n_studies),
    n_treatments = length(info$treatments),
    n_contrasts = as.integer(info$n_contrasts),
    n_designs = as.integer(info$n_designs),
    method = info$method,
    reference = info$reference,
    tau2 = info$tau2,
    tau = sqrt(info$tau2),
    Q = info$Q,
    df = as.integer(info$Q_df),
    p.value = info$Q_p,
    Q_heterogeneity = info$Q_heterogeneity,
    p_heterogeneity = info$p_heterogeneity,
    Q_inconsistency = info$Q_inconsistency,
    p_inconsistency = info$p_inconsistency
  )
}

#' @rdname meta_nma_tidiers
#' @export
augment.meta_nma <- function(x, ...) {
  info <- nma_info(x)
  out <- info$contrasts
  d <- info$d
  out$.fitted <- unname(d[out$treat1] - d[out$treat2])
  out$.resid <- out$yi - out$.fitted
  out
}

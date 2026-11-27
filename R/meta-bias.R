#' Egger's regression test for funnel plot asymmetry
#'
#' `meta_egger()` regresses effect sizes on their standard errors (or
#' sampling variances) to test for small-study effects. With
#' `model = "lm"` this is the classical weighted least squares test of
#' Egger et al. (1997), with a multiplicative dispersion term. With
#' `model = "rma"` the predictor is added to a mixed-effects
#' meta-regression with additive heterogeneity (Sterne and Egger, 2005).
#' The intercept is the limit estimate, the expected effect in a study
#' with infinite precision.
#'
#' @inheritParams meta_pool
#' @param .data A data frame, [`<meta_es>`][new_meta_es()] or
#'   [`<meta_fit>`][new_meta_fit()] from [meta_pool()].
#' @param predictor `"sei"` (standard error, Egger's test) or `"vi"`
#'   (sampling variance).
#' @param model `"lm"` or `"rma"`.
#' @param method Estimator of \eqn{\tau^2} for `model = "rma"`. Taken from
#'   the fit when `.data` is a `<meta_fit>`.
#'
#' @return A one row tibble with the slope test (`estimate`, `std.error`,
#'   `statistic`, `df`, `p.value`) and the limit estimate with its
#'   confidence interval.
#' @references
#' Egger, M., Davey Smith, G., Schneider, M. and Minder, C. (1997). Bias in
#' meta-analysis detected by a simple, graphical test. *BMJ*, 315(7109),
#' 629-634. \doi{10.1136/bmj.315.7109.629}
#'
#' Sterne, J. A. C. and Egger, M. (2005). Regression methods to detect
#' publication and other bias in meta-analysis. In H. R. Rothstein, A. J.
#' Sutton and M. Borenstein (Eds.), *Publication Bias in Meta-Analysis*
#' (pp. 99-110). Wiley.
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_egger(bcg)
#' meta_pool(bcg) |> meta_egger(model = "rma")
meta_egger <- function(.data, yi = .yi, vi = .vi,
                       predictor = c("sei", "vi"), model = c("lm", "rma"),
                       method = "REML", level = 0.95) {
  predictor <- arg_match(predictor)
  model <- arg_match(model)
  check_level(level)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  method <- match_method(input$method %||% method)
  k <- length(input$yi)
  check_min_k(k, 3L)
  pred <- if (predictor == "sei") sqrt(input$vi) else input$vi
  X <- cbind(intercept = 1, pred)
  colnames(X) <- c("intercept", predictor)
  if (model == "lm") {
    fit <- lm(input$yi ~ X - 1, weights = 1 / input$vi)
    cf <- summary(fit)$coefficients
    df <- k - 2L
    crit <- qt(1 - (1 - level) / 2, df)
    slope <- cf[2, ]
    limit <- cf[1, ]
    p_slope <- 2 * pt(abs(slope[3]), df, lower.tail = FALSE)
  } else {
    res <- rma_engine(input$yi, input$vi, X, method = method, test = "z",
                      level = level)
    df <- NA_integer_
    crit <- res$crit
    slope <- c(res$beta[2], res$se[2], res$zval[2])
    limit <- c(res$beta[1], res$se[1], res$zval[1])
    p_slope <- res$pval[2]
  }
  tibble::tibble(
    test = "Egger",
    predictor = predictor,
    model = model,
    estimate = unname(slope[1]),
    std.error = unname(slope[2]),
    statistic = unname(slope[3]),
    df = df,
    p.value = unname(p_slope),
    limit_estimate = unname(limit[1]),
    limit_conf.low = unname(limit[1] - crit * limit[2]),
    limit_conf.high = unname(limit[1] + crit * limit[2])
  )
}

#' Begg and Mazumdar rank correlation test
#'
#' `meta_begg()` tests for funnel plot asymmetry with Kendall's rank
#' correlation between the standardised effect sizes and their sampling
#' variances (Begg and Mazumdar, 1994).
#'
#' @inheritParams meta_egger
#' @param exact Use the exact null distribution of Kendall's tau when there
#'   are no ties? Passed to [stats::cor.test()].
#'
#' @return A one row tibble with Kendall's `tau` (`estimate`), the test
#'   `statistic` and `p.value`.
#' @references
#' Begg, C. B. and Mazumdar, M. (1994). Operating characteristics of a rank
#' correlation test for publication bias. *Biometrics*, 50(4), 1088-1101.
#' \doi{10.2307/2533446}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_begg(bcg)
meta_begg <- function(.data, yi = .yi, vi = .vi, exact = TRUE) {
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  k <- length(input$yi)
  check_min_k(k, 3L)
  wi <- 1 / input$vi
  theta <- sum(wi * input$yi) / sum(wi)
  vb <- 1 / sum(wi)
  y_star <- (input$yi - theta) / sqrt(input$vi - vb)
  ct <- suppressWarnings(
    cor.test(y_star, input$vi, method = "kendall", exact = exact)
  )
  tibble::tibble(
    test = "Begg",
    estimate = unname(ct$estimate),
    statistic = unname(ct$statistic),
    p.value = unname(ct$p.value)
  )
}

#' Trim-and-fill adjustment for funnel plot asymmetry
#'
#' `meta_trimfill()` implements the non-parametric trim-and-fill method of
#' Duval and Tweedie (2000). Studies on the more extreme side of the funnel
#' are iteratively trimmed until the remaining studies are symmetric; the
#' trimmed studies are then mirrored around the adjusted centre to impute
#' the studies that appear to be missing, and the meta-analysis is refitted.
#' The side of the funnel with missing studies is estimated from the sign
#' of Egger's slope unless `side` is given.
#'
#' Trim-and-fill is a sensitivity analysis: the filled studies are not real
#' and the adjusted estimate should be interpreted with caution.
#'
#' @inheritParams meta_egger
#' @param side `"left"` or `"right"`, the side with missing studies.
#'   Estimated when `NULL`.
#' @param estimator `"L0"` or `"R0"` estimator of the number of missing
#'   studies.
#' @param method Estimator of \eqn{\tau^2}, taken from the fit when `.data`
#'   is a `<meta_fit>`.
#'
#' @return A [`<meta_fit>`][new_meta_fit()] fitted to the observed and
#'   filled studies. [glance()] reports the number of filled studies
#'   (`k0`) and the side, and [augment()] flags the filled studies.
#' @references
#' Duval, S. and Tweedie, R. (2000). Trim and fill: a simple
#' funnel-plot-based method of testing and adjusting for publication bias
#' in meta-analysis. *Biometrics*, 56(2), 455-463.
#' \doi{10.1111/j.0006-341x.2000.00455.x}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_pool(bcg) |> meta_trimfill()
meta_trimfill <- function(.data, yi = .yi, vi = .vi, side = NULL,
                          estimator = c("L0", "R0"), method = "REML",
                          level = 0.95) {
  estimator <- arg_match(estimator)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  method <- match_method(input$method %||% method)
  test <- input$test %||% "z"
  level <- input$level %||% level
  check_level(level)
  yi <- input$yi
  vi <- input$vi
  k <- length(yi)
  check_min_k(k, 3L)
  one <- function(n) matrix(1, nrow = n, ncol = 1)
  if (is.null(side)) {
    res <- rma_engine(yi, vi, cbind(1, sqrt(vi)), method = method,
                      level = level)
    side <- if (res$beta[2] < 0) "right" else "left"
  } else {
    side <- arg_match(side, c("left", "right"))
  }
  flip <- if (side == "right") -1 else 1
  ys <- flip * yi
  ord <- order(ys)
  ys <- ys[ord]
  vs <- vi[ord]
  k0 <- 0
  k0_prev <- -1
  iter <- 0L
  while (k0 != k0_prev) {
    k0_prev <- k0
    iter <- iter + 1L
    if (iter > 100L) {
      cli::cli_warn("Trim-and-fill did not converge in 100 iterations.")
      break
    }
    keep <- seq_len(k - k0)
    beta <- rma_engine(ys[keep], vs[keep], one(length(keep)),
                       method = method, level = level)$beta[1]
    yc <- ys - beta
    ranks <- rank(abs(yc), ties.method = "first")
    signed <- sign(yc) * ranks
    if (estimator == "L0") {
      Sr <- sum(signed[signed > 0])
      k0 <- (4 * Sr - k * (k + 1)) / (2 * k - 1)
      var_sr <- (k * (k + 1) * (2 * k + 1) + 10 * k0^3 + 27 * k0^2 +
                   17 * k0 - 18 * k * k0^2 - 18 * k * k0 +
                   6 * k^2 * k0) / 24
      se_k0 <- 4 * sqrt(max(0, var_sr)) / (2 * k - 1)
    } else {
      neg <- -signed[signed < 0]
      k0 <- (k - if (length(neg)) max(neg) else 0) - 1
      se_k0 <- sqrt(2 * max(0, k0) + 2)
    }
    k0 <- max(0, round(k0))
  }
  filled <- rep(FALSE, k)
  y_all <- yi
  v_all <- vi
  study <- input$study
  data <- input$data
  if (k0 > 0) {
    idx <- (k - k0 + 1):k
    y_fill <- flip * (2 * beta - ys[idx])
    v_fill <- vs[idx]
    y_all <- c(yi, y_fill)
    v_all <- c(vi, v_fill)
    filled <- c(filled, rep(TRUE, k0))
    study <- c(study, paste("Filled", seq_len(k0)))
    data <- vctrs::vec_rbind(data, vctrs::vec_init(data, k0))
  }
  new_input <- list(yi = y_all, vi = v_all, study = study, data = data)
  X <- matrix(1, nrow = length(y_all), ncol = 1,
              dimnames = list(NULL, "overall"))
  fit_rma_model(
    new_input, X, method = method, test = test, level = level,
    model_type = "trimfill", measure = es_measure(.data),
    extra = list(k0 = as.integer(k0), se_k0 = se_k0, side = side,
                 estimator = estimator, filled = filled, k_observed = k)
  )
}

#' PET-PEESE bias adjusted estimates
#'
#' `meta_pet_peese()` fits the precision-effect test (PET, a weighted
#' regression of effect sizes on standard errors) and the precision-effect
#' estimate with standard error (PEESE, a regression on sampling variances)
#' of Stanley and Doucouliagos (2014). Following their conditional
#' procedure, the PEESE intercept is preferred when the PET intercept
#' differs from zero at level `alpha`, and the PET intercept otherwise.
#'
#' @inheritParams meta_egger
#' @param alpha Significance level of the PET test that selects between
#'   the PET and PEESE estimates (two-sided).
#'
#' @return A two row tibble (PET and PEESE) with the intercept (the bias
#'   adjusted effect), its standard error, test statistic, degrees of
#'   freedom, p-value and confidence interval, the slope, and a logical
#'   `selected` column marking the conditional estimate.
#' @references
#' Stanley, T. D. and Doucouliagos, H. (2014). Meta-regression
#' approximations to reduce publication selection bias. *Research Synthesis
#' Methods*, 5(1), 60-78. \doi{10.1002/jrsm.1095}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_pet_peese(bcg)
meta_pet_peese <- function(.data, yi = .yi, vi = .vi, alpha = 0.05,
                           level = 0.95) {
  check_level(level)
  check_level(alpha)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  k <- length(input$yi)
  check_min_k(k, 3L)
  fit_one <- function(pred) {
    fit <- lm(input$yi ~ pred, weights = 1 / input$vi)
    cf <- summary(fit)$coefficients
    df <- k - 2L
    crit <- qt(1 - (1 - level) / 2, df)
    list(est = cf[1, 1], se = cf[1, 2], t = cf[1, 3], df = df,
         p = 2 * pt(abs(cf[1, 3]), df, lower.tail = FALSE),
         lo = cf[1, 1] - crit * cf[1, 2], hi = cf[1, 1] + crit * cf[1, 2],
         slope = cf[2, 1])
  }
  pet <- fit_one(sqrt(input$vi))
  peese <- fit_one(input$vi)
  use_peese <- pet$p < alpha
  rows <- list(pet, peese)
  tibble::tibble(
    model = c("PET", "PEESE"),
    estimate = vapply(rows, `[[`, numeric(1), "est"),
    std.error = vapply(rows, `[[`, numeric(1), "se"),
    statistic = vapply(rows, `[[`, numeric(1), "t"),
    df = vapply(rows, function(r) as.integer(r$df), integer(1)),
    p.value = vapply(rows, `[[`, numeric(1), "p"),
    conf.low = vapply(rows, `[[`, numeric(1), "lo"),
    conf.high = vapply(rows, `[[`, numeric(1), "hi"),
    slope = vapply(rows, `[[`, numeric(1), "slope"),
    selected = c(!use_peese, use_peese)
  )
}

#' Fail-safe N
#'
#' `meta_failsafe()` computes the number of unpublished null studies needed
#' to overturn a conclusion. `type = "rosenthal"` uses Stouffer's method
#' (Rosenthal, 1979) with a one-sided level `alpha`; `"orwin"` finds the
#' number of studies with effect zero that would shrink the inverse
#' variance weighted mean to `target` (Orwin, 1983); `"rosenberg"` finds the
#' number that would make the common-effect estimate non-significant at
#' two-sided level `alpha` (Rosenberg, 2005).
#'
#' @inheritParams meta_egger
#' @param type `"rosenthal"`, `"orwin"` or `"rosenberg"`.
#' @param alpha Significance level.
#' @param target Target effect for `type = "orwin"`. Defaults to half the
#'   observed mean.
#'
#' @return A one row tibble with the method, the fail-safe number
#'   (`fail_safe_n`), the observed `estimate` (for Orwin and Rosenberg),
#'   `target`, `alpha` and the `p.value` of the observed evidence.
#' @references
#' Rosenthal, R. (1979). The file drawer problem and tolerance for null
#' results. *Psychological Bulletin*, 86(3), 638-641.
#' \doi{10.1037/0033-2909.86.3.638}
#'
#' Orwin, R. G. (1983). A fail-safe N for effect size in meta-analysis.
#' *Journal of Educational Statistics*, 8(2), 157-159.
#' \doi{10.3102/10769986008002157}
#'
#' Rosenberg, M. S. (2005). The file-drawer problem revisited: a general
#' weighted method for calculating fail-safe numbers in meta-analysis.
#' *Evolution*, 59(2), 464-468. \doi{10.1111/j.0014-3820.2005.tb01004.x}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_failsafe(bcg)
#' meta_failsafe(bcg, type = "orwin", target = log(0.9))
meta_failsafe <- function(.data, yi = .yi, vi = .vi,
                          type = c("rosenthal", "orwin", "rosenberg"),
                          alpha = 0.05, target = NULL) {
  type <- arg_match(type)
  check_level(alpha)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  yi <- input$yi
  vi <- input$vi
  k <- length(yi)
  check_min_k(k, 2L)
  round_fsn <- function(x) {
    if (is.finite(x) && abs(x - round(x)) >= sqrt(.Machine$double.eps)) {
      ceiling(x)
    } else {
      round(x)
    }
  }
  est <- NA_real_
  wi <- 1 / vi
  if (type == "rosenthal") {
    zi <- yi / sqrt(vi)
    z_avg <- abs(sum(zi) / sqrt(k))
    pval <- pnorm(z_avg, lower.tail = FALSE)
    fsn <- max(0, k * (z_avg / qnorm(alpha, lower.tail = FALSE))^2 - k)
    target <- NA_real_
  } else if (type == "orwin") {
    est <- sum(wi * yi) / sum(wi)
    if (is.null(target)) {
      target <- est / 2
    }
    if (sign(target) != sign(est)) {
      target <- -target
    }
    fsn <- if (target == 0) Inf else max(0, k * (est - target) / target)
    pval <- NA_real_
  } else {
    est <- sum(wi * yi) / sum(wi)
    zval <- est / sqrt(1 / sum(wi))
    pval <- 2 * pnorm(abs(zval), lower.tail = FALSE)
    vt <- 1 / mean(wi)
    fsn <- max(0, ((sum(wi * yi) / qnorm(alpha / 2, lower.tail = FALSE))^2 -
                     sum(wi)) * vt)
    target <- NA_real_
  }
  tibble::tibble(
    type = type,
    fail_safe_n = round_fsn(fsn),
    estimate = est,
    target = target,
    alpha = alpha,
    p.value = pval
  )
}

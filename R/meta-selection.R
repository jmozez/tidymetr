#' Step-function selection models for publication bias
#'
#' `meta_selection()` fits the Vevea and Hedges (1995) selection model, in
#' which the chance that a study is published depends on its one-sided
#' p-value through a step function. The p-value scale is cut at `steps`
#' and the relative publication probability (weight) of each interval is
#' estimated together with the mean effect and \eqn{\tau^2} by maximum
#' likelihood; the first interval has weight 1. With the default single
#' cut at 0.025 this is the three-parameter selection model (3PSM), which
#' performs well in comparisons of bias corrections (McShane, Bockenholt
#' and Hansen 2016; Carter et al. 2019). A likelihood-ratio test compares
#' the model with the unadjusted random-effects model fitted by maximum
#' likelihood. Results match `metafor::selmodel()` with
#' `type = "stepfun"`.
#'
#' Selection models need a reasonable number of studies in each p-value
#' interval; intervals with fewer than 3 studies give unstable weights and
#' a warning.
#'
#' @inheritParams meta_pool
#' @param .data A data frame, [`<meta_es>`][new_meta_es()] or
#'   [`<meta_fit>`][new_meta_fit()] from [meta_pool()].
#' @param steps Increasing cut points on the one-sided p-value scale,
#'   between 0 and 1.
#' @param alternative Direction of the one-sided p-values: `"greater"`
#'   (positive effects are favoured for publication) or `"less"`.
#' @param method `"ML"` for a random-effects model or `"FE"` for a common
#'   effect.
#'
#' @return A tibble with one row per parameter: `overall` (the adjusted
#'   mean), `tau2` and one weight per p-value interval after the first,
#'   with `estimate`, `std.error`, `statistic` and `p.value` (against 0 for
#'   the mean and 1 for the weights) and Wald intervals. Attributes hold
#'   the likelihood-ratio test (`"lrt"`), the unadjusted estimate
#'   (`"unadjusted"`) and the number of studies in each interval
#'   (`"k_per_interval"`).
#' @references
#' Vevea, J. L. and Hedges, L. V. (1995). A general linear model for
#' estimating effect size in the presence of publication bias.
#' *Psychometrika*, 60(3), 419-435. \doi{10.1007/BF02294384}
#'
#' McShane, B. B., Bockenholt, U. and Hansen, K. T. (2016). Adjusting for
#' publication bias in meta-analysis: an evaluation of selection methods
#' and some cautionary notes. *Perspectives on Psychological Science*,
#' 11(5), 730-749. \doi{10.1177/1745691616662243}
#'
#' Carter, E. C., Schonbrodt, F. D., Gervais, W. M. and Hilgard, J.
#' (2019). Correcting for bias in psychology: a comparison of
#' meta-analytic methods. *Advances in Methods and Practices in
#' Psychological Science*, 2(2), 115-144. \doi{10.1177/2515245919847196}
#' @export
#' @examples
#' adh <- meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni)
#' meta_selection(adh)
meta_selection <- function(.data, yi = .yi, vi = .vi, steps = 0.025,
                           alternative = c("greater", "less"),
                           method = c("ML", "FE"), level = 0.95) {
  alternative <- arg_match(alternative)
  method <- arg_match(method)
  check_level(level)
  if (!is.numeric(steps) || !length(steps) || anyNA(steps) ||
        any(steps <= 0 | steps >= 1) || is.unsorted(steps, strictly = TRUE)) {
    cli::cli_abort(
      "{.arg steps} must be increasing values strictly between 0 and 1."
    )
  }
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  yi <- input$yi
  vi <- input$vi
  k <- length(yi)
  n_w <- length(steps)
  check_min_k(k, n_w + 3L)
  sgn <- if (alternative == "greater") 1 else -1
  pv <- stats::pnorm(sgn * yi / sqrt(vi), lower.tail = FALSE)
  cuts <- c(0, steps, 1)
  interval <- findInterval(pv, cuts, left.open = TRUE, rightmost.closed = TRUE)
  interval[pv == 0] <- 1L
  k_int <- tabulate(interval, nbins = n_w + 1L)
  names(k_int) <- interval_labels(cuts)
  if (any(k_int < 3L)) {
    cli::cli_warn(
      "Some p-value intervals hold fewer than 3 studies; the weights are \\
       unstable."
    )
  }
  # Effect-size cut points for each study (rows) and p cut (columns).
  ycut <- outer(sqrt(vi), stats::qnorm(cuts, lower.tail = FALSE)) * sgn
  random <- method == "ML"
  unpack <- function(par) {
    list(mu = par[1], tau2 = if (random) par[2] else 0,
         delta = c(1, utils::tail(par, n_w)))
  }
  nll <- function(par) {
    q <- unpack(par)
    s <- sqrt(vi + q$tau2)
    z <- (ycut - q$mu) / s
    cdf <- stats::pnorm(z)
    probs <- if (sgn > 0) {
      cdf[, -ncol(cdf), drop = FALSE] - cdf[, -1, drop = FALSE]
    } else {
      cdf[, -1, drop = FALSE] - cdf[, -ncol(cdf), drop = FALSE]
    }
    denom <- c(probs %*% q$delta)
    ll <- log(q$delta[interval]) + stats::dnorm(yi, q$mu, s, log = TRUE) -
      log(denom)
    out <- -sum(ll)
    if (is.finite(out)) out else 1e100
  }
  w0 <- 1 / vi
  mu0 <- sum(w0 * yi) / sum(w0)
  t20 <- max(stats::var(yi) - mean(vi), 0.01 * stats::var(yi))
  start <- c(mu0, if (random) t20, rep(1, n_w))
  lower <- c(-Inf, if (random) 0, rep(1e-10, n_w))
  opt <- stats::nlminb(start, nll, lower = lower,
                       control = list(eval.max = 5000, iter.max = 2000,
                                      rel.tol = 1e-12))
  est <- opt$par
  # Unadjusted model: all weights fixed at 1.
  nll0 <- function(par) nll(c(par, rep(1, n_w)))
  opt0 <- stats::nlminb(start[seq_len(1 + random)], nll0,
                        lower = lower[seq_len(1 + random)],
                        control = list(rel.tol = 1e-12))
  se <- rep(NA_real_, length(est))
  free <- !(random & seq_along(est) == 2 & est[2] < 1e-8)
  hess <- tryCatch(stats::optimHess(est, nll)[free, free, drop = FALSE],
                   error = function(e) NULL)
  if (!is.null(hess)) {
    vc <- tryCatch(solve(hess), error = function(e) NULL)
    if (!is.null(vc)) se[free] <- sqrt(pmax(diag(vc), 0))
  }
  terms <- c("overall", if (random) "tau2",
             paste("weight", names(k_int)[-1]))
  null <- c(0, if (random) NA_real_, rep(1, n_w))
  stat <- (est - null) / se
  crit <- stats::qnorm(1 - (1 - level) / 2)
  out <- tibble::tibble(
    term = terms, estimate = est, std.error = se, statistic = stat,
    p.value = 2 * stats::pnorm(abs(stat), lower.tail = FALSE),
    conf.low = est - crit * se, conf.high = est + crit * se
  )
  # Variance and weights cannot be negative.
  out$conf.low[-1] <- pmax(out$conf.low[-1], 0)
  lrt <- max(2 * (opt0$objective - opt$objective), 0)
  attr(out, "lrt") <- tibble::tibble(
    statistic = lrt, df = n_w,
    p.value = stats::pchisq(lrt, n_w, lower.tail = FALSE)
  )
  attr(out, "unadjusted") <- opt0$par[1]
  attr(out, "k_per_interval") <- k_int
  out
}

interval_labels <- function(cuts) {
  n <- length(cuts)
  lab <- format(cuts, trim = TRUE, drop0trailing = TRUE)
  lo <- lab[-n]
  hi <- lab[-1]
  paste0(ifelse(seq_len(n - 1) == 1, "[", "("), lo, ", ", hi, "]")
}

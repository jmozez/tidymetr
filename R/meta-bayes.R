#' Bayesian random-effects meta-analysis
#'
#' `meta_bayes()` fits the normal-normal random-effects model in a
#' Bayesian framework, with a normal (or flat) prior for the mean effect
#' \eqn{\mu} and a weakly informative half-normal or half-Cauchy prior for
#' the heterogeneity \eqn{\tau}. The posterior is computed exactly by
#' numerical integration over \eqn{\tau}, with \eqn{\mu} integrated
#' analytically, as in the bayesmeta package (Rover 2020), so there is no
#' Markov chain Monte Carlo and no sampling error. This is particularly
#' useful with few studies, where \eqn{\tau} is poorly estimated and
#' frequentist intervals can be too narrow (Friede et al. 2017; Rover et
#' al. 2021).
#'
#' The scale of the heterogeneity prior must suit the effect measure: a
#' half-normal prior with scale 0.5 is a common weakly informative choice
#' for log odds ratios, log risk ratios and standardised mean differences
#' (Rover et al. 2021).
#'
#' @inheritParams meta_pool
#' @param .data A data frame, [`<meta_es>`][new_meta_es()] or
#'   [`<meta_fit>`][new_meta_fit()] from [meta_pool()].
#' @param mu_mean,mu_sd Mean and standard deviation of the normal prior for
#'   \eqn{\mu}. `mu_sd = Inf` (the default) gives a flat prior.
#' @param tau_prior `"half_normal"` or `"half_cauchy"`.
#' @param tau_scale Scale of the heterogeneity prior.
#' @param level Probability of the equal-tailed credible intervals.
#'
#' @return A tibble with rows `overall` (\eqn{\mu}), `tau` and `prediction`
#'   (the effect in a new study), giving the posterior `estimate` (median),
#'   `mean`, `sd`, `conf.low` and `conf.high`. The attribute
#'   `"prob_positive"` holds the posterior probability that \eqn{\mu > 0},
#'   and `"posterior"` the marginal posterior density of \eqn{\tau} on a
#'   grid.
#' @references
#' Rover, C. (2020). Bayesian random-effects meta-analysis using the
#' bayesmeta R package. *Journal of Statistical Software*, 93(6), 1-51.
#' \doi{10.18637/jss.v093.i06}
#'
#' Rover, C., Bender, R., Dias, S., Schmid, C. H., Schmidli, H., Sturtz, S.,
#' Weber, S. and Friede, T. (2021). On weakly informative prior
#' distributions for the heterogeneity parameter in Bayesian random-effects
#' meta-analysis. *Research Synthesis Methods*, 12(4), 448-474.
#' \doi{10.1002/jrsm.1475}
#'
#' Friede, T., Rover, C., Wandel, S. and Neuenschwander, B. (2017).
#' Meta-analysis of few small studies in orphan diseases. *Research
#' Synthesis Methods*, 8(1), 79-91. \doi{10.1002/jrsm.1217}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_bayes(bcg)
#' meta_bayes(bcg, mu_sd = 4, tau_prior = "half_cauchy", tau_scale = 0.5)
meta_bayes <- function(.data, yi = .yi, vi = .vi, mu_mean = 0, mu_sd = Inf,
                       tau_prior = c("half_normal", "half_cauchy"),
                       tau_scale = 0.5, level = 0.95) {
  tau_prior <- arg_match(tau_prior)
  check_level(level)
  check_number(mu_mean)
  if (!is.numeric(mu_sd) || length(mu_sd) != 1L || is.na(mu_sd) ||
        mu_sd <= 0) {
    cli::cli_abort("{.arg mu_sd} must be a positive number or {.code Inf}.")
  }
  if (!is.numeric(tau_scale) || length(tau_scale) != 1L ||
        !is.finite(tau_scale) || tau_scale <= 0) {
    cli::cli_abort("{.arg tau_scale} must be a positive number.")
  }
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  y <- input$yi
  v <- input$vi
  check_min_k(length(y), 1L)
  log_prior <- function(tau) {
    if (tau_prior == "half_normal") {
      stats::dnorm(tau, 0, tau_scale, log = TRUE) + log(2)
    } else {
      stats::dcauchy(tau, 0, tau_scale, log = TRUE) + log(2)
    }
  }
  cond <- function(tau) bayes_conditional(y, v, tau, mu_mean, mu_sd)
  log_post <- function(tau) {
    vapply(tau, function(t) cond(t)$loglik, numeric(1)) + log_prior(tau)
  }
  # Locate the bulk of the posterior, then integrate on a fine grid.
  s <- max(stats::sd(y), sqrt(mean(v)), tau_scale, na.rm = TRUE)
  coarse <- c(0, exp(seq(log(1e-4 * s), log(1e3 * s), length.out = 800)))
  lp <- log_post(coarse)
  upper <- max(coarse[lp > max(lp) - 30])
  grid <- seq(0, upper, length.out = 4001)
  lp <- log_post(grid)
  dens <- exp(lp - max(lp))
  h <- grid[2] - grid[1]
  wts <- dens * h * c(0.5, rep(1, length(grid) - 2), 0.5)
  dens <- dens / sum(wts)
  wts <- wts / sum(wts)
  cm <- vapply(grid, function(t) unlist(cond(t)[c("mean", "sd")]),
               numeric(2))
  m_g <- cm[1, ]
  s_g <- cm[2, ]
  probs <- c((1 - level) / 2, 0.5, 1 - (1 - level) / 2)
  mix_summary <- function(sd_g) {
    mn <- sum(wts * m_g)
    vr <- sum(wts * (sd_g^2 + m_g^2)) - mn^2
    q <- vapply(probs, function(p) mix_quantile(p, wts, m_g, sd_g),
                numeric(1))
    c(mean = mn, sd = sqrt(vr), q)
  }
  mu_s <- mix_summary(s_g)
  pred_s <- mix_summary(sqrt(s_g^2 + grid^2))
  cdf_tau <- cumsum(c(0, (dens[-1] + dens[-length(dens)]) / 2 * h))
  cdf_tau <- cdf_tau / cdf_tau[length(cdf_tau)]
  tau_q <- stats::approx(cdf_tau, grid, probs, ties = "ordered")$y
  tau_mean <- sum(wts * grid)
  tau_s <- c(mean = tau_mean, sd = sqrt(sum(wts * grid^2) - tau_mean^2),
             tau_q)
  tab <- unname(rbind(mu_s, tau_s, pred_s))
  out <- tibble::tibble(
    term = c("overall", "tau", "prediction"),
    estimate = tab[, 4], mean = tab[, 1], sd = tab[, 2],
    conf.low = tab[, 3], conf.high = tab[, 5]
  )
  attr(out, "prob_positive") <- sum(wts *
    stats::pnorm(0, m_g, s_g, lower.tail = FALSE))
  attr(out, "posterior") <- tibble::tibble(tau = grid, density = dens)
  out
}

# Conditional posterior of mu given tau, and the marginal likelihood of tau
# (up to a constant).
bayes_conditional <- function(y, v, tau, mu_mean, mu_sd) {
  w <- 1 / (v + tau^2)
  sw <- sum(w)
  if (is.finite(mu_sd)) {
    prec <- sw + 1 / mu_sd^2
    mean <- (sum(w * y) + mu_mean / mu_sd^2) / prec
    r <- y - mu_mean
    quad <- sum(w * r^2) - mu_sd^2 * sum(w * r)^2 / (1 + mu_sd^2 * sw)
    loglik <- -0.5 * (sum(log(v + tau^2)) + log(1 + mu_sd^2 * sw) + quad)
  } else {
    prec <- sw
    mean <- sum(w * y) / sw
    loglik <- -0.5 * (sum(log(v + tau^2)) + log(sw) +
                        sum(w * (y - mean)^2))
  }
  list(mean = mean, sd = sqrt(1 / prec), loglik = loglik)
}

mix_quantile <- function(p, w, m, s) {
  f <- function(x) sum(w * stats::pnorm(x, m, s)) - p
  lo <- min(m - 12 * s)
  hi <- max(m + 12 * s)
  stats::uniroot(f, c(lo, hi), tol = 1e-10)$root
}

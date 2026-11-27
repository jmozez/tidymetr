#' Pool effect sizes with common-effect or random-effects models
#'
#' `meta_pool()` combines study level effect sizes into an overall estimate
#' using inverse variance weights. The between-study variance
#' \eqn{\tau^2} can be estimated by restricted maximum likelihood
#' (`"REML"`, the default), maximum likelihood (`"ML"`), the
#' DerSimonian-Laird method of moments (`"DL"`), the Paule-Mandel
#' generalised Q estimator (`"PM"`) or the Sidik-Jonkman estimator
#' (`"SJ"`). `method = "FE"` fits a common-effect (fixed effect) model.
#'
#' With `test = "hksj"`, the standard error is rescaled by the
#' Hartung-Knapp-Sidik-Jonkman factor and inference uses a t distribution
#' with \eqn{k - 1} degrees of freedom. A prediction interval for the effect
#' in a new study, \eqn{\hat\mu \pm c \sqrt{SE^2 + \hat\tau^2}}, is always
#' reported, where \eqn{c} is the normal or t quantile that matches `test`.
#' A Q-profile confidence interval for \eqn{\tau^2} (Viechtbauer, 2007) is
#' stored and returned by [glance()].
#'
#' The estimators are implemented directly in base R and match the results
#' of `metafor::rma()` to numerical precision.
#'
#' @param .data A [`<meta_es>`][new_meta_es()] from [meta_effect_size()] or
#'   any data frame with effect sizes and sampling variances.
#' @param yi,vi <[`data-masking`][rlang::args_data_masking]> Columns holding
#'   the effect sizes and sampling variances. Default to `.yi` and `.vi`.
#' @param method Estimator of the between-study variance: `"REML"`, `"ML"`,
#'   `"DL"`, `"PM"`, `"SJ"` or `"FE"` (common effect).
#' @param test `"z"` for normal based inference or `"hksj"` for the
#'   Hartung-Knapp-Sidik-Jonkman adjustment.
#' @param level Confidence level for intervals.
#' @param study <[`data-masking`][rlang::args_data_masking]> Optional study
#'   labels. Taken from the `<meta_es>` when available.
#'
#' @return A [`<meta_fit>`][new_meta_fit()] with one row, `term = "overall"`.
#' @references
#' DerSimonian, R. and Laird, N. (1986). Meta-analysis in clinical trials.
#' *Controlled Clinical Trials*, 7(3), 177-188.
#' \doi{10.1016/0197-2456(86)90046-2}
#'
#' Paule, R. C. and Mandel, J. (1982). Consensus values and weighting
#' factors. *Journal of Research of the National Bureau of Standards*,
#' 87(5), 377-385. \doi{10.6028/jres.087.022}
#'
#' Sidik, K. and Jonkman, J. N. (2005). Simple heterogeneity variance
#' estimation for meta-analysis. *Journal of the Royal Statistical Society
#' Series C*, 54(2), 367-384. \doi{10.1111/j.1467-9876.2005.00489.x}
#'
#' Hartung, J. and Knapp, G. (2001). A refined method for the meta-analysis
#' of controlled clinical trials with binary outcome. *Statistics in
#' Medicine*, 20(24), 3875-3889. \doi{10.1002/sim.1009}
#'
#' Viechtbauer, W. (2007). Confidence intervals for the amount of
#' heterogeneity in meta-analysis. *Statistics in Medicine*, 26(1), 37-52.
#' \doi{10.1002/sim.2514}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg,
#'   event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' meta_pool(bcg)
#' meta_pool(bcg, method = "DL", test = "hksj")
#' meta_pool(bcg, method = "FE") |> glance()
meta_pool <- function(.data, yi = .yi, vi = .vi, method = "REML",
                      test = "z", level = 0.95, study = NULL) {
  method <- match_method(method)
  test <- match_test(test)
  check_level(level)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi), enquo(study))
  check_min_k(length(input$yi), 1L)
  X <- matrix(1, nrow = length(input$yi), ncol = 1,
              dimnames = list(NULL, "overall"))
  fit_rma_model(input, X, method = method, test = test, level = level,
                model_type = "pool", measure = es_measure(.data))
}

es_measure <- function(.data) {
  if (is_meta_es(.data)) {
    return(attr(.data, "measure"))
  }
  if (is_meta_fit(.data)) {
    return(fit_info(.data)$measure)
  }
  "GEN"
}

# Fit a univariate (mixed effects) model and wrap it as a <meta_fit>.
fit_rma_model <- function(input, X, method, test, level, model_type,
                          measure = "GEN", extra = list(),
                          call = caller_env()) {
  res <- rma_engine(input$yi, input$vi, X, method = method, test = test,
                    level = level, call = call)
  coefs <- coef_table(res)
  info <- c(
    res,
    list(
      model_type = model_type,
      measure = measure,
      study = input$study,
      data = input$data
    ),
    extra
  )
  if (res$p == 1L && all(X == 1)) {
    pint <- prediction_interval(res)
    info$pi_low <- pint$lower
    info$pi_high <- pint$upper
  } else {
    info$pi_low <- NA_real_
    info$pi_high <- NA_real_
  }
  if (res$p > 1L && method != "FE" && has_intercept(X)) {
    res0 <- rma_engine(input$yi, input$vi, X[, 1, drop = FALSE],
                       method = method, test = "z", level = level,
                       call = call)
    info$tau2_null <- res0$tau2
    info$R2 <- if (res0$tau2 > 0) {
      max(0, 100 * (res0$tau2 - res$tau2) / res0$tau2)
    } else {
      0
    }
  } else {
    info$R2 <- NA_real_
  }
  new_meta_fit(coefs, fit = info)
}

has_intercept <- function(X) {
  ncol(X) > 0L && all(X[, 1] == 1)
}

coef_table <- function(res) {
  tibble::tibble(
    term = colnames(res$X),
    estimate = unname(c(res$beta)),
    std.error = unname(res$se),
    statistic = unname(res$zval),
    p.value = unname(res$pval),
    conf.low = unname(res$ci_lb),
    conf.high = unname(res$ci_ub)
  )
}

prediction_interval <- function(res) {
  se_pred <- sqrt(res$se[1]^2 + res$tau2)
  list(lower = unname(res$beta[1] - res$crit * se_pred),
       upper = unname(res$beta[1] + res$crit * se_pred))
}

# Projection matrix P = W - W X (X'WX)^-1 X'W for weights w.
proj_matrix <- function(X, w) {
  W <- diag(w, nrow = length(w))
  stXWX <- inv_sym(crossprod(X, W %*% X))
  W - W %*% X %*% stXWX %*% crossprod(X, W)
}

# Between-study variance estimators for the univariate model.
tau2_estimate <- function(yi, vi, X, method, control = list(),
                          call = caller_env()) {
  k <- length(yi)
  p <- ncol(X)
  tol <- control$tol %||% 1e-10
  maxiter <- control$maxiter %||% 1000L
  if (method == "FE") {
    return(list(tau2 = 0, iterations = 0L))
  }
  if (k - p < 1L) {
    cli::cli_warn(
      "Too few studies to estimate {.code tau^2}; it was set to 0.",
      call = call
    )
    return(list(tau2 = 0, iterations = 0L))
  }
  y <- matrix(yi, ncol = 1)
  P_fe <- proj_matrix(X, 1 / vi)
  QE <- c(crossprod(y, P_fe %*% y))
  if (method == "DL") {
    tau2 <- max(0, (QE - (k - p)) / sum(diag(P_fe)))
    return(list(tau2 = tau2, iterations = 0L))
  }
  if (method == "SJ") {
    # Initial estimate: the (biased) variance of the effect sizes, as in
    # Sidik and Jonkman (2005); P removes the moderators afterwards.
    tau2_0 <- c(stats::var(yi) * (k - 1) / k)
    P <- proj_matrix(X, 1 / (vi + tau2_0))
    tau2 <- tau2_0 * c(crossprod(y, P %*% y)) / (k - p)
    return(list(tau2 = tau2, iterations = 0L))
  }
  if (method == "PM") {
    q_fun <- function(t2) {
      P <- proj_matrix(X, 1 / (vi + t2))
      c(crossprod(y, P %*% y)) - (k - p)
    }
    if (q_fun(0) <= 0) {
      return(list(tau2 = 0, iterations = 0L))
    }
    upper <- max(1, 10 * stats::var(yi))
    while (q_fun(upper) > 0) {
      upper <- upper * 10
    }
    root <- uniroot(q_fun, c(0, upper), tol = tol, maxiter = maxiter)
    return(list(tau2 = root$root, iterations = root$iter))
  }
  # REML and ML by Fisher scoring with step halving.
  score_info <- function(t2) {
    w <- 1 / (vi + t2)
    P <- proj_matrix(X, w)
    Py <- P %*% y
    if (method == "REML") {
      list(score = c(crossprod(Py)) - sum(diag(P)),
           info = sum(P * t(P)))
    } else {
      list(score = c(crossprod(Py)) - sum(w), info = sum(w^2))
    }
  }
  s0 <- score_info(0)
  if (s0$score <= 0) {
    return(list(tau2 = 0, iterations = 0L))
  }
  tau2 <- max((QE - (k - p)) / sum(diag(P_fe)), 0.01 * stats::var(yi), 1e-4)
  iter <- 0L
  repeat {
    iter <- iter + 1L
    si <- score_info(tau2)
    adj <- si$score / si$info
    while (tau2 + adj < 0) {
      adj <- adj / 2
    }
    tau2 <- tau2 + adj
    if (abs(adj) < tol) {
      break
    }
    if (iter >= maxiter) {
      cli::cli_warn(
        "Fisher scoring did not converge in {maxiter} iterations.",
        call = call
      )
      break
    }
  }
  list(tau2 = tau2, iterations = iter)
}

# Univariate (mixed effects) meta-analytic model engine.
rma_engine <- function(yi, vi, X, method = "REML", test = "z", level = 0.95,
                       tau2 = NULL, control = list(), call = caller_env()) {
  k <- length(yi)
  p <- ncol(X)
  if (k < p) {
    cli::cli_abort(
      "The model has more coefficients ({p}) than studies ({k}).",
      call = call
    )
  }
  if (qr(X)$rank < p) {
    cli::cli_abort("The model matrix is not of full rank.", call = call)
  }
  est <- if (is.null(tau2)) {
    tau2_estimate(yi, vi, X, method, control = control, call = call)
  } else {
    list(tau2 = tau2, iterations = 0L)
  }
  tau2 <- est$tau2
  y <- matrix(yi, ncol = 1)
  w <- 1 / (vi + tau2)
  W <- diag(w, nrow = k)
  stXWX <- inv_sym(crossprod(X, W %*% X))
  beta <- c(stXWX %*% crossprod(X, W %*% y))
  vb <- stXWX
  P <- W - W %*% X %*% stXWX %*% crossprod(X, W)
  RSS <- c(crossprod(y, P %*% y))
  df_resid <- k - p
  s2w <- 1
  if (test == "hksj") {
    if (df_resid < 1L) {
      cli::cli_abort(
        "The Hartung-Knapp-Sidik-Jonkman adjustment needs more studies \\
         than coefficients.",
        call = call
      )
    }
    s2w <- RSS / df_resid
    vb <- s2w * vb
  }
  se <- sqrt(diag(vb))
  zval <- beta / se
  alpha <- 1 - level
  if (test %in% c("hksj", "t")) {
    ddf <- max(df_resid, 1L)
    pval <- 2 * pt(abs(zval), df = ddf, lower.tail = FALSE)
    crit <- qt(1 - alpha / 2, df = ddf)
  } else {
    ddf <- NA_integer_
    pval <- 2 * pnorm(abs(zval), lower.tail = FALSE)
    crit <- qnorm(1 - alpha / 2)
  }
  # Residual heterogeneity (fixed effect weights)
  P_fe <- proj_matrix(X, 1 / vi)
  QE <- if (df_resid > 0) c(crossprod(y, P_fe %*% y)) else NA_real_
  QEp <- if (df_resid > 0) pchisq(QE, df_resid, lower.tail = FALSE) else NA
  if (method == "FE") {
    I2 <- if (isTRUE(QE > 0)) max(0, 100 * (QE - df_resid) / QE) else 0
    H2 <- if (df_resid > 0) QE / df_resid else NA_real_
  } else {
    vt <- df_resid / sum(diag(P_fe))
    I2 <- 100 * tau2 / (vt + tau2)
    H2 <- (vt + tau2) / vt
  }
  # Omnibus test of moderators (excluding the intercept)
  btt <- if (has_intercept(X)) seq_len(p)[-1] else seq_len(p)
  QM <- NA_real_
  QMp <- NA_real_
  QMdf <- c(length(btt), NA)
  if (length(btt) > 0L && !(p == 1L && has_intercept(X))) {
    b <- beta[btt]
    QM <- c(crossprod(b, inv_sym(vb[btt, btt, drop = FALSE]) %*% b))
    if (test %in% c("hksj", "t")) {
      QM <- QM / length(btt)
      QMdf <- c(length(btt), ddf)
      QMp <- pf(QM, length(btt), ddf, lower.tail = FALSE)
    } else {
      QMp <- pchisq(QM, length(btt), lower.tail = FALSE)
    }
  }
  # Log likelihood
  ll_ml <- -0.5 * k * log(2 * pi) - 0.5 * sum(log(vi + tau2)) - 0.5 * RSS
  ll_reml <- -0.5 * (k - p) * log(2 * pi) +
    0.5 * c(determinant(crossprod(X), logarithm = TRUE)$modulus) -
    0.5 * sum(log(vi + tau2)) -
    0.5 * c(determinant(crossprod(X, W %*% X), logarithm = TRUE)$modulus) -
    0.5 * RSS
  hat <- diag(X %*% stXWX %*% crossprod(X, W))
  fitted <- c(X %*% beta)
  tau2_ci <- if (method == "FE" || df_resid < 1L) {
    c(NA_real_, NA_real_)
  } else {
    tau2_qprofile(yi, vi, X, level)
  }
  se_tau2 <- if (method %in% c("REML", "ML") && df_resid > 0) {
    info <- if (method == "REML") sum(P * t(P)) else sum(w^2)
    sqrt(2 / info)
  } else {
    NA_real_
  }
  names(beta) <- colnames(X)
  list(
    beta = beta, vb = vb, se = se, zval = zval, pval = pval,
    ci_lb = beta - crit * se, ci_ub = beta + crit * se, crit = crit,
    tau2 = tau2, se_tau2 = se_tau2, tau2_ci = tau2_ci,
    iterations = est$iterations,
    QE = QE, QEp = QEp, QM = QM, QMp = QMp, QMdf = QMdf,
    I2 = I2, H2 = H2, s2w = s2w, df_resid = df_resid, ddf = ddf,
    k = k, p = p, X = X, yi = yi, vi = vi, weights = w,
    hat = hat, fitted = fitted, method = method, test = test,
    level = level,
    logLik = if (method == "REML") ll_reml else ll_ml,
    npar = p + as.integer(method != "FE")
  )
}

# Q-profile confidence interval for tau^2 (Viechtbauer, 2007).
tau2_qprofile <- function(yi, vi, X, level) {
  k <- length(yi)
  p <- ncol(X)
  df <- k - p
  y <- matrix(yi, ncol = 1)
  q_gen <- function(t2) {
    P <- proj_matrix(X, 1 / (vi + t2))
    c(crossprod(y, P %*% y))
  }
  alpha <- 1 - level
  crit_lo <- qchisq(1 - alpha / 2, df)
  crit_hi <- qchisq(alpha / 2, df)
  q0 <- q_gen(0)
  find_root <- function(crit) {
    if (q0 < crit) {
      return(0)
    }
    upper <- max(1, 10 * stats::var(yi))
    while (q_gen(upper) > crit) {
      upper <- upper * 10
      if (upper > 1e12) {
        return(NA_real_)
      }
    }
    uniroot(function(t2) q_gen(t2) - crit, c(0, upper),
            tol = 1e-10)$root
  }
  c(find_root(crit_lo), find_root(crit_hi))
}

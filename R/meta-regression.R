#' Meta-regression with study level moderators
#'
#' `meta_regress()` fits a mixed-effects meta-regression in which study level
#' covariates (moderators) explain part of the between-study heterogeneity.
#' The residual heterogeneity \eqn{\tau^2} is estimated with any of the
#' estimators available in [meta_pool()]. The omnibus test of moderators
#' (`QM`) is a Wald chi-squared test, or an F test when `test = "hksj"`.
#' The pseudo \eqn{R^2} compares \eqn{\tau^2} from the model with that of an
#' intercept only model fitted with the same estimator.
#'
#' @inheritParams meta_pool
#' @param mods A one-sided formula of moderators, for example `~ ablat` or
#'   `~ factor(alloc) + year`. Use `~ 0 + group` to drop the intercept.
#'
#' @return A [`<meta_fit>`][new_meta_fit()] with one row per coefficient.
#' @references
#' Thompson, S. G. and Higgins, J. P. T. (2002). How should
#' meta-regression analyses be undertaken and interpreted? *Statistics in
#' Medicine*, 21(11), 1559-1573. \doi{10.1002/sim.1187}
#'
#' Raudenbush, S. W. (2009). Analyzing effect sizes: random-effects models.
#' In H. Cooper, L. V. Hedges and J. C. Valentine (Eds.), *The Handbook of
#' Research Synthesis and Meta-Analysis* (2nd ed., pp. 295-315). Russell
#' Sage Foundation.
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' fit <- meta_regress(bcg, ~ ablat)
#' fit
#' glance(fit)
#' predict(fit, newdata = data.frame(ablat = c(10, 30, 50)))
meta_regress <- function(.data, mods, yi = .yi, vi = .vi, method = "REML",
                         test = "z", level = 0.95, study = NULL) {
  method <- match_method(method)
  test <- match_test(test)
  check_level(level)
  check_formula(mods)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi), enquo(study))
  design <- build_design(mods, input)
  input <- design$input
  fit_rma_model(
    input, design$X, method = method, test = test, level = level,
    model_type = "regression", measure = es_measure(.data),
    extra = list(terms = design$terms, xlevels = design$xlevels,
                 contrasts = design$contrasts, formula = mods)
  )
}

check_formula <- function(mods, call = caller_env()) {
  if (!inherits(mods, "formula") || length(mods) != 2L) {
    cli::cli_abort(
      c(
        "{.arg mods} must be a one-sided formula such as {.code ~ x}.",
        "x" = "You supplied an object of class {.cls {class(mods)}}."
      ),
      call = call
    )
  }
  invisible(mods)
}

build_design <- function(mods, input, call = caller_env()) {
  mf <- model.frame(mods, data = input$data, na.action = na.pass)
  keep <- stats::complete.cases(mf)
  if (any(!keep)) {
    cli::cli_warn(
      "Dropped {sum(!keep)} row{?s} with missing moderator values.",
      call = call
    )
    input <- subset_input(input, keep)
    mf <- mf[keep, , drop = FALSE]
  }
  tt <- terms(mf)
  X <- model.matrix(tt, mf)
  list(
    X = X, terms = tt, input = input,
    xlevels = stats::.getXlevels(tt, mf),
    contrasts = attr(X, "contrasts")
  )
}

subset_input <- function(input, keep) {
  input$yi <- input$yi[keep]
  input$vi <- input$vi[keep]
  input$study <- input$study[keep]
  input$data <- input$data[keep, , drop = FALSE]
  input
}

#' Subgroup meta-analysis
#'
#' `meta_subgroup()` pools effect sizes within the levels of a categorical
#' variable and tests whether the subgroup estimates differ.
#'
#' With `tau2 = "separate"` (the default) each subgroup is pooled on its own,
#' with its own \eqn{\tau^2}, and the test of subgroup differences is the
#' Q statistic of a common-effect meta-analysis of the subgroup estimates
#' (Borenstein et al., 2009). With `tau2 = "common"` a single \eqn{\tau^2} is
#' assumed and the subgroup means are estimated by a meta-regression without
#' an intercept; the test of differences is then a Wald test (or an F test
#' with `test = "hksj"`) that all subgroup means are equal.
#'
#' @inheritParams meta_pool
#' @param group <[`data-masking`][rlang::args_data_masking]> The grouping
#'   variable.
#' @param tau2 `"separate"` or `"common"` between-study variance.
#'
#' @return A [`<meta_fit>`][new_meta_fit()] with one row per subgroup,
#'   including the number of studies (`k`), `tau2` and `I2` of each
#'   subgroup. The test of subgroup differences is returned by [glance()].
#' @references
#' Borenstein, M., Hedges, L. V., Higgins, J. P. T. and Rothstein, H. R.
#' (2009). *Introduction to Meta-Analysis*, chapter 19. Wiley.
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_subgroup(bcg, alloc)
#' meta_subgroup(bcg, alloc, tau2 = "common") |> glance()
meta_subgroup <- function(.data, group, yi = .yi, vi = .vi,
                          method = "REML", test = "z", level = 0.95,
                          study = NULL, tau2 = c("separate", "common")) {
  method <- match_method(method)
  test <- match_test(test)
  check_level(level)
  tau2 <- arg_match(tau2)
  group_quo <- enquo(group)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi), enquo(study))
  g <- eval_tidy(group_quo, input$data)
  if (anyNA(g)) {
    cli::cli_warn("Dropped {sum(is.na(g))} row{?s} with a missing group.")
    input <- subset_input(input, !is.na(g))
    g <- g[!is.na(g)]
  }
  g <- factor(g)
  g <- droplevels(g)
  lev <- levels(g)
  if (length(lev) < 2L) {
    cli::cli_abort("{.arg group} must have at least two levels.")
  }
  measure <- es_measure(.data)
  if (tau2 == "common") {
    return(subgroup_common(input, g, method, test, level, measure,
                           as_label(group_quo)))
  }
  subgroup_separate(input, g, method, test, level, measure,
                    as_label(group_quo))
}

subgroup_separate <- function(input, g, method, test, level, measure,
                              group_name) {
  lev <- levels(g)
  fits <- lapply(lev, function(l) {
    idx <- which(g == l)
    k <- length(idx)
    m <- if (k < 2L) "FE" else method
    tt <- if (k < 2L) "z" else test
    if (k < 2L) {
      cli::cli_inform(
        "Subgroup {.val {l}} has one study; its estimate is that study."
      )
    }
    X <- matrix(1, nrow = k, ncol = 1, dimnames = list(NULL, l))
    res <- rma_engine(input$yi[idx], input$vi[idx], X, method = m,
                      test = tt, level = level)
    res$idx <- idx
    res
  })
  names(fits) <- lev
  est <- vapply(fits, function(f) f$beta[1], numeric(1))
  se <- vapply(fits, function(f) f$se[1], numeric(1))
  wb <- 1 / se^2
  Qb <- sum(wb * (est - sum(wb * est) / sum(wb))^2)
  dfb <- length(lev) - 1L
  coefs <- tibble::tibble(
    term = lev,
    estimate = unname(est),
    std.error = unname(se),
    statistic = unname(vapply(fits, function(f) f$zval[1], numeric(1))),
    p.value = unname(vapply(fits, function(f) f$pval[1], numeric(1))),
    conf.low = unname(vapply(fits, function(f) f$ci_lb[1], numeric(1))),
    conf.high = unname(vapply(fits, function(f) f$ci_ub[1], numeric(1))),
    k = unname(vapply(fits, function(f) f$k, integer(1))),
    tau2 = unname(vapply(fits, function(f) f$tau2, numeric(1))),
    I2 = unname(vapply(fits, function(f) f$I2, numeric(1)))
  )
  n <- length(input$yi)
  fitted <- weights <- hat <- numeric(n)
  for (f in fits) {
    fitted[f$idx] <- f$fitted
    weights[f$idx] <- f$weights
    hat[f$idx] <- f$hat
  }
  QE <- sum(vapply(fits, function(f) f$QE %|% 0, numeric(1)))
  df_resid <- sum(vapply(fits, function(f) f$df_resid, numeric(1)))
  info <- list(
    model_type = "subgroup", tau2_type = "separate", method = method,
    test = test, level = level, measure = measure, k = n,
    p = length(lev), yi = input$yi, vi = input$vi, study = input$study,
    data = input$data, group = g, group_name = group_name,
    fitted = fitted, weights = weights, hat = hat,
    QE = QE, QEp = pchisq(QE, df_resid, lower.tail = FALSE),
    df_resid = df_resid, ddf = NA_integer_,
    Q_between = Qb, df_between = dfb,
    p_between = pchisq(Qb, dfb, lower.tail = FALSE),
    test_between = "Q", subgroup_fits = fits, tau2 = NULL,
    pi_low = NA_real_, pi_high = NA_real_, R2 = NA_real_
  )
  new_meta_fit(coefs, fit = info)
}

subgroup_common <- function(input, g, method, test, level, measure,
                            group_name) {
  lev <- levels(g)
  X <- stats::model.matrix(~ 0 + g)
  colnames(X) <- lev
  res <- rma_engine(input$yi, input$vi, X, method = method, test = test,
                    level = level)
  G <- length(lev)
  L <- cbind(-1, diag(G - 1))
  Lb <- L %*% res$beta
  Qb <- c(crossprod(Lb, inv_sym(L %*% res$vb %*% t(L)) %*% Lb))
  if (test == "hksj") {
    Fb <- Qb / (G - 1)
    pb <- pf(Fb, G - 1, res$ddf, lower.tail = FALSE)
    Qb <- Fb
    test_between <- "F"
  } else {
    pb <- pchisq(Qb, G - 1, lower.tail = FALSE)
    test_between <- "Q"
  }
  coefs <- coef_table(res)
  coefs$k <- as.integer(table(g)[lev])
  info <- c(res, list(
    model_type = "subgroup", tau2_type = "common", measure = measure,
    study = input$study, data = input$data, group = g,
    group_name = group_name, Q_between = Qb, df_between = G - 1L,
    p_between = pb, test_between = test_between,
    pi_low = NA_real_, pi_high = NA_real_, R2 = NA_real_
  ))
  new_meta_fit(coefs, fit = info)
}

#' Multilevel and phylogenetic meta-analysis
#'
#' `meta_multilevel()` fits a three-level meta-analytic model for effect
#' sizes nested in clusters (for example several outcomes per study, or
#' several studies per research group). The marginal variance of the
#' effect sizes is
#' \deqn{V = \mathrm{diag}(v_i) + \sigma^2_{(3)} Z R Z^\top +
#'   \sigma^2_{(2)} I,}
#' where \eqn{Z} maps effect sizes to clusters and \eqn{R} is the identity,
#' or a phylogenetic (or any other known) correlation matrix supplied with
#' `cor_matrix`. The variance components are estimated by restricted or full
#' maximum likelihood using bounded quasi-Newton optimisation, and the fixed
#' effects by generalised least squares.
#'
#' The \eqn{I^2} statistics follow Nakagawa and Santos (2012): the share of
#' the total variance due to each random effect, using the typical sampling
#' variance of Higgins and Thompson (2002).
#'
#' @inheritParams meta_regress
#' @param cluster <[`data-masking`][rlang::args_data_masking]> The upper
#'   level grouping (level 3), such as study, district or species.
#' @param within <[`data-masking`][rlang::args_data_masking]> Optional
#'   identifier of the level 2 units nested in `cluster`. Defaults to one
#'   unit per row (per effect size).
#' @param mods An optional one-sided formula of moderators. Defaults to an
#'   intercept only model.
#' @param method `"REML"` or `"ML"`.
#' @param test `"z"` or `"t"` (t tests with \eqn{k - p} degrees of freedom).
#' @param cor_matrix An optional correlation matrix among clusters, with
#'   row and column names matching the values of `cluster`. Supply a
#'   phylogenetic correlation matrix (for example from
#'   `ape::vcv(tree, corr = TRUE)`) for a phylogenetic meta-analysis.
#'
#' @return A [`<meta_fit>`][new_meta_fit()] with one row per coefficient.
#'   The variance components are returned by [glance()].
#' @references
#' Konstantopoulos, S. (2011). Fixed effects and variance components
#' estimation in three-level meta-analysis. *Research Synthesis Methods*,
#' 2(1), 61-76. \doi{10.1002/jrsm.35}
#'
#' Nakagawa, S. and Santos, E. S. A. (2012). Methodological issues and
#' advances in biological meta-analysis. *Evolutionary Ecology*, 26(5),
#' 1253-1274. \doi{10.1007/s10682-012-9555-5}
#'
#' Hadfield, J. D. and Nakagawa, S. (2010). General quantitative genetic
#' methods for comparative biology: phylogenies, taxonomies and multi-trait
#' models for continuous and categorical characters. *Journal of
#' Evolutionary Biology*, 23(3), 494-508.
#' \doi{10.1111/j.1420-9101.2009.01915.x}
#' @export
#' @examples
#' fit <- meta_multilevel(school_calendar, yi = yi, vi = vi,
#'   cluster = district, within = school)
#' fit
#' glance(fit)
meta_multilevel <- function(.data, cluster, yi = .yi, vi = .vi,
                            within = NULL, mods = NULL, method = "REML",
                            test = "z", level = 0.95, study = NULL,
                            cor_matrix = NULL) {
  method <- match_method(method, choices = c("REML", "ML"))
  test <- match_test(test)
  if (test == "hksj") {
    test <- "t"
  }
  check_level(level)
  cluster_quo <- enquo(cluster)
  within_quo <- enquo(within)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi), enquo(study))
  if (is.null(mods)) {
    mods <- ~1
  }
  check_formula(mods)
  design <- build_design(mods, input)
  input <- design$input
  X <- design$X
  if (identical(colnames(X), "(Intercept)")) {
    colnames(X) <- "overall"
  }
  cl <- eval_tidy(cluster_quo, input$data)
  if (anyNA(cl)) {
    cli::cli_abort("{.arg cluster} must not contain missing values.")
  }
  cl <- as.character(cl)
  k <- length(input$yi)
  wi <- if (quo_is_null(within_quo)) {
    seq_len(k)
  } else {
    eval_tidy(within_quo, input$data)
  }
  cl_levels <- unique(cl)
  Z1 <- outer(cl, cl_levels, `==`) * 1
  if (!is.null(cor_matrix)) {
    R <- check_cor_matrix(cor_matrix, cl_levels)
    K1 <- Z1 %*% R %*% t(Z1)
  } else {
    K1 <- tcrossprod(Z1)
  }
  w_id <- paste(cl, wi, sep = "\r")
  K2 <- outer(w_id, w_id, `==`) * 1
  level_names <- c(as_label(cluster_quo),
                   if (quo_is_null(within_quo)) "effect" else
                     as_label(within_quo))
  res <- mv_engine(input$yi, input$vi, X, list(K1, K2), method = method,
                   test = test, level = level)
  names(res$sigma2) <- level_names
  names(res$I2_levels) <- level_names
  coefs <- coef_table(res)
  info <- c(res, list(
    model_type = "multilevel", measure = es_measure(.data),
    study = input$study, data = input$data, cluster = cl, within = wi,
    n_levels = c(length(cl_levels), length(unique(w_id))),
    phylogenetic = !is.null(cor_matrix), terms = design$terms,
    xlevels = design$xlevels, contrasts = design$contrasts,
    formula = mods, pi_low = NA_real_, pi_high = NA_real_, R2 = NA_real_
  ))
  if (res$p == 1L && all(X == 1)) {
    se_pred <- sqrt(res$se^2 + sum(res$sigma2))
    info$pi_low <- res$beta - res$crit * se_pred
    info$pi_high <- res$beta + res$crit * se_pred
  }
  new_meta_fit(coefs, fit = info)
}

check_cor_matrix <- function(cor_matrix, levels, call = caller_env()) {
  if (!is.matrix(cor_matrix) || nrow(cor_matrix) != ncol(cor_matrix)) {
    cli::cli_abort("{.arg cor_matrix} must be a square matrix.", call = call)
  }
  if (is.null(rownames(cor_matrix)) || is.null(colnames(cor_matrix))) {
    cli::cli_abort("{.arg cor_matrix} must have row and column names.",
                   call = call)
  }
  missing_lev <- setdiff(levels, rownames(cor_matrix))
  if (length(missing_lev) > 0L) {
    cli::cli_abort(
      c(
        "Every cluster must appear in {.arg cor_matrix}.",
        "x" = "Missing: {.val {missing_lev}}."
      ),
      call = call
    )
  }
  R <- cor_matrix[levels, levels, drop = FALSE]
  if (max(abs(R - t(R))) > 1e-8) {
    cli::cli_abort("{.arg cor_matrix} must be symmetric.", call = call)
  }
  if (any(abs(diag(R) - 1) > 1e-8)) {
    cli::cli_abort(
      c(
        "{.arg cor_matrix} must be a correlation matrix with a unit \\
         diagonal.",
        "i" = "Use {.fn stats::cov2cor} to convert a covariance matrix."
      ),
      call = call
    )
  }
  R
}

# Multivariate (multilevel) engine: V = diag(vi) + sum_l sigma2_l K_l.
mv_engine <- function(yi, vi, X, K, method = "REML", test = "z",
                      level = 0.95, call = caller_env()) {
  k <- length(yi)
  p <- ncol(X)
  if (qr(X)$rank < p) {
    cli::cli_abort("The model matrix is not of full rank.", call = call)
  }
  y <- matrix(yi, ncol = 1)
  S <- diag(vi, nrow = k)
  nll <- function(theta) {
    V <- S
    for (l in seq_along(K)) {
      V <- V + theta[l] * K[[l]]
    }
    L <- tryCatch(chol(V), error = function(e) NULL)
    if (is.null(L)) {
      return(1e10)
    }
    Vinv <- chol2inv(L)
    XtVX <- crossprod(X, Vinv %*% X)
    beta <- solve(XtVX, crossprod(X, Vinv %*% y))
    r <- y - X %*% beta
    out <- 2 * sum(log(diag(L))) + c(crossprod(r, Vinv %*% r))
    if (method == "REML") {
      out <- out + c(determinant(XtVX, logarithm = TRUE)$modulus)
    }
    0.5 * out
  }
  start_tau2 <- tau2_estimate(yi, vi, X, "DL", call = call)$tau2
  start <- rep(max(start_tau2, 0.01 * stats::var(yi), 1e-4) / length(K),
               length(K))
  opt <- stats::nlminb(start, nll, lower = rep(0, length(K)),
                       control = list(eval.max = 2000, iter.max = 1000,
                                      rel.tol = 1e-12))
  if (opt$convergence != 0 &&
        !grepl("singular|relative|X-convergence", opt$message)) {
    cli::cli_warn(
      "The optimiser reported a convergence problem: {opt$message}",
      call = call
    )
  }
  sigma2 <- pmax(opt$par, 0)
  V <- S
  for (l in seq_along(K)) {
    V <- V + sigma2[l] * K[[l]]
  }
  Vinv <- inv_sym(V)
  XtVX <- crossprod(X, Vinv %*% X)
  vb <- inv_sym(XtVX)
  beta <- c(vb %*% crossprod(X, Vinv %*% y))
  names(beta) <- colnames(X)
  se <- sqrt(diag(vb))
  zval <- beta / se
  alpha <- 1 - level
  df_resid <- k - p
  if (test == "t") {
    ddf <- df_resid
    pval <- 2 * pt(abs(zval), ddf, lower.tail = FALSE)
    crit <- qt(1 - alpha / 2, ddf)
  } else {
    ddf <- NA_integer_
    pval <- 2 * pnorm(abs(zval), lower.tail = FALSE)
    crit <- qnorm(1 - alpha / 2)
  }
  btt <- if (has_intercept(X)) seq_len(p)[-1] else seq_len(p)
  QM <- QMp <- NA_real_
  QMdf <- c(length(btt), NA)
  if (length(btt) > 0L && !(p == 1L && has_intercept(X))) {
    b <- beta[btt]
    QM <- c(crossprod(b, inv_sym(vb[btt, btt, drop = FALSE]) %*% b))
    if (test == "t") {
      QM <- QM / length(btt)
      QMdf <- c(length(btt), ddf)
      QMp <- pf(QM, length(btt), ddf, lower.tail = FALSE)
    } else {
      QMp <- pchisq(QM, length(btt), lower.tail = FALSE)
    }
  }
  P_fe <- proj_matrix(X, 1 / vi)
  QE <- c(crossprod(y, P_fe %*% y))
  w <- 1 / vi
  v_typical <- (k - 1) * sum(w) / (sum(w)^2 - sum(w^2))
  I2_levels <- 100 * sigma2 / (sum(sigma2) + v_typical)
  ll <- -opt$objective - 0.5 * (if (method == "REML") k - p else k) *
    log(2 * pi)
  if (method == "REML") {
    ll <- ll + 0.5 * c(determinant(crossprod(X), logarithm = TRUE)$modulus)
  }
  fitted <- c(X %*% beta)
  H <- X %*% vb %*% crossprod(X, Vinv)
  list(
    beta = beta, vb = vb, se = se, zval = zval, pval = pval,
    ci_lb = beta - crit * se, ci_ub = beta + crit * se, crit = crit,
    sigma2 = sigma2, tau2 = NULL, I2 = sum(I2_levels),
    I2_levels = I2_levels, H2 = NA_real_,
    QE = QE, QEp = pchisq(QE, df_resid, lower.tail = FALSE),
    QM = QM, QMp = QMp, QMdf = QMdf, df_resid = df_resid, ddf = ddf,
    k = k, p = p, X = X, yi = yi, vi = vi, V = V,
    weights = diag(Vinv), hat = diag(H), fitted = fitted,
    method = method, test = test, level = level, logLik = ll,
    npar = p + length(K), iterations = opt$iterations
  )
}

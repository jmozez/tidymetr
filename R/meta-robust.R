#' Cluster-robust inference with small-sample corrections
#'
#' `meta_robust()` replaces the model-based standard errors of a fitted
#' meta-analytic model with cluster-robust (sandwich) standard errors, so
#' that inference stays valid when effect sizes within a study or cluster
#' are dependent in ways the model does not capture (Hedges, Tipton and
#' Johnson 2010). It uses the bias-reduced linearisation estimator (CR2)
#' with Satterthwaite degrees of freedom, which keeps the type I error
#' close to nominal even with few clusters (Tipton 2015; Pustejovsky and
#' Tipton 2018). The model weights are kept as the working model, as in
#' `clubSandwich::coef_test()`, whose results this function reproduces.
#'
#' Satterthwaite degrees of freedom below about 4 mean the test is not
#' trustworthy, and are flagged in the output.
#'
#' @param fit A [`<meta_fit>`][new_meta_fit()] from [meta_pool()],
#'   [meta_regress()] or [meta_multilevel()] (without a phylogenetic
#'   correlation matrix).
#' @param cluster <[`data-masking`][rlang::args_data_masking]> Column of
#'   the data used for the fit that identifies the clusters, usually the
#'   study. For [meta_multilevel()] fits the outer level is used when
#'   `cluster` is not given.
#' @param level Confidence level for the intervals.
#'
#' @return A tibble with one row per coefficient: `term`, `estimate`,
#'   `std.error` (CR2), `statistic`, `df` (Satterthwaite), `p.value`,
#'   `conf.low`, `conf.high` and `df_ok` (`df` of at least 4). The number
#'   of clusters is in the `"n_clusters"` attribute.
#' @references
#' Hedges, L. V., Tipton, E. and Johnson, M. C. (2010). Robust variance
#' estimation in meta-regression with dependent effect size estimates.
#' *Research Synthesis Methods*, 1(1), 39-65. \doi{10.1002/jrsm.5}
#'
#' Tipton, E. (2015). Small sample adjustments for robust variance
#' estimation with meta-regression. *Psychological Methods*, 20(3),
#' 375-393. \doi{10.1037/met0000011}
#'
#' Pustejovsky, J. E. and Tipton, E. (2018). Small-sample methods for
#' cluster-robust variance estimation and hypothesis testing in fixed
#' effects models. *Journal of Business and Economic Statistics*, 36(4),
#' 672-683. \doi{10.1080/07350015.2016.1247004}
#' @export
#' @examples
#' fit <- meta_multilevel(school_calendar, yi = yi, vi = vi,
#'   cluster = district, within = school)
#' meta_robust(fit)
#'
#' # A univariate model that ignores the clustering, made robust
#' meta_pool(school_calendar, yi = yi, vi = vi) |>
#'   meta_robust(cluster = district)
meta_robust <- function(fit, cluster = NULL, level = 0.95) {
  if (!is_meta_fit(fit)) {
    cli::cli_abort("{.arg fit} must be a {.cls meta_fit}.")
  }
  check_level(level)
  info <- fit_info(fit)
  if (is.null(info$X) || isTRUE(info$phylogenetic)) {
    cli::cli_abort(
      "{.fn meta_robust} needs a fit from {.fn meta_pool}, \\
       {.fn meta_regress} or a non-phylogenetic {.fn meta_multilevel}."
    )
  }
  cl_quo <- enquo(cluster)
  cl <- if (quo_is_null(cl_quo)) info$cluster else
    eval_tidy(cl_quo, info$data)
  if (is.null(cl)) {
    cli::cli_abort("Give the {.arg cluster} column.")
  }
  if (length(cl) != length(info$yi) || anyNA(cl)) {
    cli::cli_abort(
      "{.arg cluster} must have one non-missing value per effect size."
    )
  }
  X <- info$X
  y <- info$yi
  phi <- if (!is.null(info$V)) info$V else diag(info$vi + info$tau2,
                                                 nrow = length(y))
  res <- cr2_test(X, y, phi, as.character(cl), level)
  res <- tibble::tibble(term = colnames(X), !!!res)
  attr(res, "n_clusters") <- length(unique(cl))
  res
}

# Symmetric (pseudo-)inverse square root.
inv_sqrt_sym <- function(m) {
  e <- eigen((m + t(m)) / 2, symmetric = TRUE)
  d <- ifelse(e$values > 1e-12 * max(e$values), 1 / sqrt(e$values), 0)
  e$vectors %*% (d * t(e$vectors))
}

cr2_test <- function(X, y, phi, cl, level) {
  W <- inv_sym(phi)
  M <- inv_sym(crossprod(X, W %*% X))
  beta <- c(M %*% crossprod(X, W %*% y))
  e <- c(y - X %*% beta)
  n <- length(y)
  IH <- diag(n) - X %*% M %*% crossprod(X, W)
  groups <- split(seq_len(n), factor(cl, levels = unique(cl)))
  # E_j maps the residuals to cluster j's contribution to X'W A e.
  E <- lapply(groups, function(j) {
    D <- chol(phi[j, j, drop = FALSE])
    B <- D %*% (phi[j, j, drop = FALSE] -
                  X[j, , drop = FALSE] %*% M %*% t(X[j, , drop = FALSE])) %*%
      t(D)
    A <- t(D) %*% inv_sqrt_sym(B) %*% D
    M %*% crossprod(X[j, , drop = FALSE], W[j, j, drop = FALSE] %*% A)
  })
  p <- ncol(X)
  vcr <- matrix(0, p, p)
  for (g in seq_along(groups)) {
    u <- E[[g]] %*% e[groups[[g]]]
    vcr <- vcr + tcrossprod(u)
  }
  se <- sqrt(diag(vcr))
  df <- vapply(seq_len(p), function(k) {
    # g_j = (I - H)_j' (E_j row k), a vector over all effect sizes
    G <- vapply(seq_along(groups), function(g) {
      c(crossprod(IH[groups[[g]], , drop = FALSE], E[[g]][k, ]))
    }, numeric(n))
    G <- matrix(G, nrow = n)
    S <- crossprod(G, phi %*% G)
    sum(diag(S))^2 / sum(S^2)
  }, numeric(1))
  stat <- beta / se
  crit <- stats::qt(1 - (1 - level) / 2, df)
  list(
    estimate = beta, std.error = se, statistic = stat, df = df,
    p.value = 2 * stats::pt(abs(stat), df, lower.tail = FALSE),
    conf.low = beta - crit * se, conf.high = beta + crit * se,
    df_ok = df >= 4
  )
}

#' Leave-one-out sensitivity analysis
#'
#' `meta_leave1out()` refits the meta-analysis `k` times, each time leaving
#' out one study, to show how much the pooled estimate and the
#' heterogeneity depend on any single study.
#'
#' @inheritParams meta_pool
#' @param .data A [`<meta_fit>`][new_meta_fit()] from [meta_pool()] (its
#'   estimator and test are reused), a [`<meta_es>`][new_meta_es()] or a
#'   data frame.
#' @param method,test Used only when `.data` is not a `<meta_fit>`.
#'
#' @return A tibble with one row per omitted study: `study`, `estimate`,
#'   `std.error`, `statistic`, `p.value`, `conf.low`, `conf.high`, `tau2`,
#'   `I2`, `H2`, `QE` and `p.QE`.
#' @references
#' Viechtbauer, W. and Cheung, M. W.-L. (2010). Outlier and influence
#' diagnostics for meta-analysis. *Research Synthesis Methods*, 1(2),
#' 112-125. \doi{10.1002/jrsm.11}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' meta_pool(bcg) |> meta_leave1out()
meta_leave1out <- function(.data, yi = .yi, vi = .vi, method = "REML",
                           test = "z", level = 0.95) {
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  method <- match_method(input$method %||% method)
  test <- match_test(input$test %||% test)
  level <- input$level %||% level
  check_level(level)
  k <- length(input$yi)
  check_min_k(k, 3L)
  rows <- lapply(seq_len(k), function(i) {
    res <- rma_engine(input$yi[-i], input$vi[-i],
                      matrix(1, nrow = k - 1, ncol = 1), method = method,
                      test = test, level = level)
    tibble::tibble(
      study = input$study[i],
      estimate = res$beta[1], std.error = res$se[1],
      statistic = res$zval[1], p.value = res$pval[1],
      conf.low = res$ci_lb[1], conf.high = res$ci_ub[1],
      tau2 = res$tau2, I2 = res$I2, H2 = res$H2,
      QE = res$QE, p.QE = res$QEp
    )
  })
  out <- vctrs::vec_rbind(!!!rows)
  out[] <- lapply(out, unname)
  out
}

check_pool_input <- function(input, call = caller_env()) {
  if (!is.null(input$fit) &&
        !fit_info(input$fit)$model_type %in% c("pool", "trimfill")) {
    cli::cli_abort(
      c(
        "This analysis needs a model without moderators.",
        "i" = "Supply a fit from {.fn meta_pool} or the effect sizes."
      ),
      call = call
    )
  }
  invisible(input)
}

#' Cumulative meta-analysis
#'
#' `meta_cumulative()` adds studies one at a time, in the order given by
#' `order` (for example publication year), and reports the pooled estimate
#' after each addition.
#'
#' @inheritParams meta_leave1out
#' @param order <[`data-masking`][rlang::args_data_masking]> A variable that
#'   defines the order in which studies are added. Evaluated in the data
#'   used to fit the model. Defaults to the row order.
#' @param decreasing Add studies in decreasing order of `order`?
#'
#' @return A tibble with one row per step: the study added, the number of
#'   studies so far (`k`), `estimate`, `std.error`, `statistic`, `p.value`,
#'   `conf.low`, `conf.high`, `tau2` and `I2`.
#' @references
#' Lau, J., Antman, E. M., Jimenez-Silva, J., Kupelnick, B., Mosteller, F.
#' and Chalmers, T. C. (1992). Cumulative meta-analysis of therapeutic
#' trials for myocardial infarction. *New England Journal of Medicine*,
#' 327(4), 248-254. \doi{10.1056/NEJM199207233270406}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' meta_pool(bcg) |> meta_cumulative(order = year)
meta_cumulative <- function(.data, order = NULL, yi = .yi, vi = .vi,
                            method = "REML", test = "z", level = 0.95,
                            decreasing = FALSE) {
  order_quo <- enquo(order)
  input <- resolve_meta_input(.data, enquo(yi), enquo(vi))
  check_pool_input(input)
  method <- match_method(input$method %||% method)
  test <- match_test(input$test %||% test)
  level <- input$level %||% level
  check_level(level)
  k <- length(input$yi)
  ord_val <- eval_optional(order_quo, input$data)
  if (!is.null(ord_val) && length(ord_val) != k) {
    cli::cli_abort(
      "{.arg order} must have one value per study ({k}), not {length(ord_val)}."
    )
  }
  ord <- if (is.null(ord_val)) seq_len(k) else
    base::order(ord_val, decreasing = decreasing)
  rows <- lapply(seq_len(k), function(j) {
    idx <- ord[seq_len(j)]
    m <- if (j < 2L) "FE" else method
    tt <- if (j < 3L && test == "hksj") "z" else test
    res <- rma_engine(input$yi[idx], input$vi[idx],
                      matrix(1, nrow = j, ncol = 1), method = m,
                      test = tt, level = level)
    tibble::tibble(
      study = input$study[ord[j]],
      k = j,
      estimate = res$beta[1], std.error = res$se[1],
      statistic = res$zval[1], p.value = res$pval[1],
      conf.low = res$ci_lb[1], conf.high = res$ci_ub[1],
      tau2 = res$tau2, I2 = if (j < 2L) NA_real_ else res$I2
    )
  })
  out <- vctrs::vec_rbind(!!!rows)
  out[] <- lapply(out, unname)
  out
}

#' Outlier and influence diagnostics
#'
#' `meta_influence()` computes the case deletion diagnostics of
#' Viechtbauer and Cheung (2010) for each study: externally studentised
#' residuals, DFFITS, Cook's distance, covariance ratios, the leave-one-out
#' \eqn{\tau^2} and Q, hat values, weights and DFBETAS. A study is flagged
#' as influential when \eqn{|DFFITS| > 3\sqrt{p/(k-p)}}, Cook's distance
#' exceeds the median of a \eqn{\chi^2_p} distribution, the hat value
#' exceeds \eqn{3p/k}, or any \eqn{|DFBETAS| > 1}.
#'
#' @param .data A [`<meta_fit>`][new_meta_fit()] from [meta_pool()] or
#'   [meta_regress()].
#'
#' @return A tibble with one row per study and the columns `study`,
#'   `rstudent`, `dffits`, `cooks_distance`, `cov_ratio`, `tau2_del`,
#'   `QE_del`, `hat`, `weight`, `dfbetas_<term>` and `influential`.
#' @references
#' Viechtbauer, W. and Cheung, M. W.-L. (2010). Outlier and influence
#' diagnostics for meta-analysis. *Research Synthesis Methods*, 1(2),
#' 112-125. \doi{10.1002/jrsm.11}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' meta_pool(bcg) |> meta_influence()
meta_influence <- function(.data) {
  check_data_frame(.data)
  if (!is_meta_fit(.data) ||
        !fit_info(.data)$model_type %in% c("pool", "regression")) {
    cli::cli_abort(
      "{.arg .data} must be a fit from {.fn meta_pool} or \\
       {.fn meta_regress}."
    )
  }
  x <- fit_info(.data)
  k <- x$k
  p <- x$p
  check_min_k(k, p + 2L)
  beta <- x$beta
  X <- x$X
  pred_full <- c(X %*% beta)
  svb <- inv_sym(x$vb)
  out <- matrix(NA_real_, k, 7,
                dimnames = list(NULL, c("delpred", "vdelpred", "s2w",
                                        "dffits", "cook", "covr",
                                        "tau2")))
  qe_del <- rep(NA_real_, k)
  dfbs <- matrix(NA_real_, k, p, dimnames = list(NULL, colnames(X)))
  for (i in seq_len(k)) {
    res <- tryCatch(
      rma_engine(x$yi[-i], x$vi[-i], X[-i, , drop = FALSE],
                 method = x$method, test = x$test, level = x$level),
      error = function(e) NULL
    )
    if (is.null(res)) {
      next
    }
    Xi <- X[i, , drop = FALSE]
    delpred <- c(Xi %*% res$beta)
    vdelpred <- c(Xi %*% res$vb %*% t(Xi))
    dffits <- (pred_full[i] - delpred) /
      sqrt(res$s2w * x$hat[i] * (res$tau2 + x$vi[i]))
    vb_del <- inv_sym(crossprod(X, X / (x$vi + res$tau2)))
    dfb <- beta - res$beta
    dfbs[i, ] <- dfb / sqrt(res$s2w * diag(vb_del))
    out[i, ] <- c(delpred, vdelpred, res$s2w, dffits,
                  c(crossprod(dfb, svb %*% dfb)),
                  det(res$vb) / det(x$vb), res$tau2)
    qe_del[i] <- res$QE
  }
  resid <- x$yi - out[, "delpred"]
  se_resid <- sqrt(x$vi * out[, "s2w"] + out[, "vdelpred"] +
                     out[, "tau2"] * out[, "s2w"])
  weight <- 100 * x$weights / sum(x$weights)
  infl <- abs(out[, "dffits"]) > 3 * sqrt(p / (k - p)) |
    pchisq(out[, "cook"], df = p) > 0.5 |
    x$hat > 3 * p / k |
    apply(abs(dfbs) > 1, 1, any)
  res <- tibble::tibble(
    study = x$study,
    rstudent = resid / se_resid,
    dffits = out[, "dffits"],
    cooks_distance = out[, "cook"],
    cov_ratio = out[, "covr"],
    tau2_del = out[, "tau2"],
    QE_del = qe_del,
    hat = x$hat,
    weight = weight
  )
  dfb_tbl <- tibble::as_tibble(dfbs, .name_repair = "minimal")
  terms <- colnames(X)
  terms[terms %in% c("(Intercept)", "overall")] <- "intercept"
  names(dfb_tbl) <- paste0("dfbetas_", make.names(terms))
  res <- vctrs::vec_cbind(res, dfb_tbl)
  res$influential <- !is.na(infl) & infl
  res
}

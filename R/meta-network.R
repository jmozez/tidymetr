#' Arm level data to pairwise contrasts
#'
#' `meta_pairwise()` turns arm level data (one row per treatment arm) into
#' contrast level data (one row per pair of arms within a study), computing
#' the effect size of `treat1` relative to `treat2` with
#' [meta_effect_size()]. Studies with more than two arms contribute every
#' pairwise contrast, which is what [meta_network()] expects.
#'
#' @param .data A data frame with one row per study arm.
#' @param study,treatment <[`data-masking`][rlang::args_data_masking]>
#'   Columns identifying the study and the treatment of each arm.
#' @param measure An effect size measure for two groups: `"OR"`, `"RR"`,
#'   `"MD"`, `"SMD"` or `"IRR"`.
#' @param event,n,mean,sd,time <[`data-masking`][rlang::args_data_masking]>
#'   Arm level summaries: events and sample sizes for `"OR"` and `"RR"`;
#'   means, standard deviations and sample sizes for `"MD"` and `"SMD"`;
#'   events and person time for `"IRR"`.
#' @param add,to Zero cell correction, see [meta_effect_size()].
#'
#' @return A [`<meta_es>`][new_meta_es()] with columns `study`, `treat1`,
#'   `treat2`, the arm summaries suffixed with `1` and `2`, and `.yi`, `.vi`
#'   and `.sei`.
#' @export
#' @examples
#' meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
meta_pairwise <- function(.data, study, treatment, measure = "OR",
                          event = NULL, n = NULL, mean = NULL, sd = NULL,
                          time = NULL, add = 0.5,
                          to = c("only0", "all", "none")) {
  check_data_frame(.data)
  measure <- match_measure(measure)
  to <- arg_match(to)
  if (!measure %in% c("OR", "RR", "MD", "SMD", "IRR")) {
    cli::cli_abort(
      "{.arg measure} must compare two groups, not {.val {measure}}."
    )
  }
  st <- eval_tidy(enquo(study), .data)
  tr <- as.character(eval_tidy(enquo(treatment), .data))
  arm <- list(
    event = eval_optional(enquo(event), .data),
    n = eval_optional(enquo(n), .data),
    mean = eval_optional(enquo(mean), .data),
    sd = eval_optional(enquo(sd), .data),
    time = eval_optional(enquo(time), .data)
  )
  needed <- switch(measure,
    OR = c("event", "n"), RR = c("event", "n"),
    MD = c("mean", "sd", "n"), SMD = c("mean", "sd", "n"),
    IRR = c("event", "time")
  )
  absent <- needed[vapply(arm[needed], is.null, logical(1))]
  if (length(absent) > 0L) {
    cli::cli_abort("Measure {.val {measure}} needs {.arg {absent}}.")
  }
  arm <- arm[needed]
  rows <- list()
  for (s in unique(st)) {
    idx <- which(st == s)
    if (length(idx) < 2L) {
      cli::cli_warn("Study {.val {s}} has a single arm and was skipped.")
      next
    }
    if (anyDuplicated(tr[idx])) {
      cli::cli_abort("Study {.val {s}} has duplicated treatment arms.")
    }
    pairs <- utils::combn(idx, 2)
    for (j in seq_len(ncol(pairs))) {
      a <- pairs[1, j]
      b <- pairs[2, j]
      row <- list(study = s, treat1 = tr[a], treat2 = tr[b])
      for (nm in needed) {
        row[[paste0(nm, "1")]] <- arm[[nm]][a]
        row[[paste0(nm, "2")]] <- arm[[nm]][b]
      }
      rows[[length(rows) + 1L]] <- tibble::as_tibble(row)
    }
  }
  pw <- vctrs::vec_rbind(!!!rows)
  values <- switch(measure,
    OR = , RR = list(event1 = pw$event1, n1 = pw$n1,
                     event2 = pw$event2, n2 = pw$n2),
    MD = , SMD = list(m1 = pw$mean1, sd1 = pw$sd1, n1 = pw$n1,
                      m2 = pw$mean2, sd2 = pw$sd2, n2 = pw$n2),
    IRR = list(event1 = pw$event1, time1 = pw$time1,
               event2 = pw$event2, time2 = pw$time2)
  )
  es <- es_compute(measure, values, add = add, to = to)
  pw$.yi <- es$yi
  pw$.vi <- es$vi
  pw$.sei <- sqrt(es$vi)
  new_meta_es(pw, measure = measure, study = "study")
}

#' Network meta-analysis
#'
#' `meta_network()` fits a frequentist, contrast-based network meta-analysis
#' by generalised least squares (Lu and Ades, 2006; Rucker, 2012). Each
#' study contributes the contrasts of its arms against a study baseline.
#' For studies with more than two arms, the arm level variances are
#' reconstructed from the pairwise variances (Rucker and Schwarzer, 2014),
#' so the within-study covariance is respected. Random effects share one
#' between-study variance \eqn{\tau^2} under the consistency assumption,
#' with covariance \eqn{\tau^2/2} between contrasts of the same multi-arm
#' study, and \eqn{\tau^2} is estimated by restricted maximum likelihood.
#'
#' Treatments are ranked by P-scores (Rucker and Schwarzer, 2015), the
#' frequentist analogue of the surface under the cumulative ranking curve.
#' Global inconsistency is assessed by decomposing the common-effect Q
#' statistic into within-design heterogeneity and between-design
#' inconsistency (Krahn, Binder and Konig, 2013). Local inconsistency is
#' assessed for each comparison with direct evidence by contrasting the
#' direct estimate with the indirect estimate obtained by back-calculation
#' (Dias et al., 2010). The direct estimates pool every contrast that
#' compares the pair, so for multi-arm studies the split is approximate.
#'
#' @param .data Contrast level data with one row per pairwise comparison,
#'   such as the output of [meta_pairwise()].
#' @param study,treat1,treat2 <[`data-masking`][rlang::args_data_masking]>
#'   Columns identifying the study and the two treatments compared. The
#'   effect size is that of `treat1` relative to `treat2`.
#' @param yi,vi <[`data-masking`][rlang::args_data_masking]> Effect sizes and
#'   sampling variances. Default to `.yi` and `.vi`.
#' @param reference The reference treatment. Defaults to the most connected
#'   treatment.
#' @param method `"REML"` (random effects) or `"FE"` (common effect).
#' @param level Confidence level.
#' @param small_values Are small (negative) effect sizes `"good"` (for
#'   example fewer adverse events) or `"bad"` (for example fewer people who
#'   quit smoking)? Used for the P-scores.
#'
#' @return A [`<meta_nma>`][new_meta_nma()] with one row per treatment:
#'   the effect relative to the reference, its confidence interval and the
#'   P-score. Use [tidy()][tidy.meta_nma()] for the league table,
#'   inconsistency decomposition and direct and indirect split.
#' @references
#' Lu, G. and Ades, A. E. (2006). Assessing evidence inconsistency in mixed
#' treatment comparisons. *Journal of the American Statistical
#' Association*, 101(474), 447-459. \doi{10.1198/016214505000001302}
#'
#' Rucker, G. (2012). Network meta-analysis, electrical networks and graph
#' theory. *Research Synthesis Methods*, 3(4), 312-324.
#' \doi{10.1002/jrsm.1058}
#'
#' Rucker, G. and Schwarzer, G. (2014). Reduce dimension or reduce weights?
#' Comparing two approaches to multi-arm studies in network meta-analysis.
#' *Statistics in Medicine*, 33(25), 4353-4369. \doi{10.1002/sim.6236}
#'
#' Rucker, G. and Schwarzer, G. (2015). Ranking treatments in frequentist
#' network meta-analysis works without resampling methods. *BMC Medical
#' Research Methodology*, 15, 58. \doi{10.1186/s12874-015-0060-8}
#'
#' Krahn, U., Binder, H. and Konig, J. (2013). A graphical tool for locating
#' inconsistency in network meta-analyses. *BMC Medical Research
#' Methodology*, 13, 35. \doi{10.1186/1471-2288-13-35}
#'
#' Dias, S., Welton, N. J., Caldwell, D. M. and Ades, A. E. (2010). Checking
#' consistency in mixed treatment comparison meta-analysis. *Statistics in
#' Medicine*, 29(7-8), 932-944. \doi{10.1002/sim.3767}
#' @export
#' @examples
#' pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
#' nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
#'   reference = "no_contact", small_values = "bad")
#' nma
#' tidy(nma, type = "league")
#' tidy(nma, type = "inconsistency")
meta_network <- function(.data, study, treat1, treat2, yi = .yi, vi = .vi,
                         reference = NULL, method = "REML", level = 0.95,
                         small_values = c("good", "bad")) {
  check_data_frame(.data)
  method <- match_method(method, choices = c("REML", "FE"))
  check_level(level)
  small_values <- arg_match(small_values)
  st <- as.character(eval_tidy(enquo(study), .data))
  t1 <- as.character(eval_tidy(enquo(treat1), .data))
  t2 <- as.character(eval_tidy(enquo(treat2), .data))
  y <- eval_tidy(enquo(yi), .data)
  v <- eval_tidy(enquo(vi), .data)
  check_numeric_column(y, "yi")
  check_numeric_column(v, "vi")
  keep <- !(is.na(y) | is.na(v) | is.na(st) | is.na(t1) | is.na(t2))
  if (any(!keep)) {
    cli::cli_warn("Dropped {sum(!keep)} contrast{?s} with missing values.")
  }
  st <- st[keep]
  t1 <- t1[keep]
  t2 <- t2[keep]
  y <- y[keep]
  v <- v[keep]
  check_variances(v)
  if (any(t1 == t2)) {
    cli::cli_abort("A contrast cannot compare a treatment with itself.")
  }
  treatments <- sort(unique(c(t1, t2)))
  if (length(treatments) < 3L) {
    cli::cli_abort(
      c(
        "A network needs at least three treatments.",
        "i" = "Use {.fn meta_pool} for a pairwise meta-analysis."
      )
    )
  }
  edges <- edge_table(t1, t2, st)
  check_connected(treatments, edges)
  if (is.null(reference)) {
    deg <- table(factor(c(t1, t2), levels = treatments))
    reference <- names(which.max(deg))
  }
  if (!reference %in% treatments) {
    cli::cli_abort("Reference {.val {reference}} is not in the network.")
  }
  trt_order <- c(reference, setdiff(treatments, reference))
  basic <- basic_contrasts(st, t1, t2, y, v, trt_order)
  params <- setdiff(trt_order, reference)
  X <- basic$X[, params, drop = FALSE]
  S <- basic$S
  M <- basic$M
  fe <- gls_fit(basic$y, S, X)
  tau2 <- 0
  if (method == "REML") {
    tau2 <- nma_reml_tau2(basic$y, S, M, X)
  }
  fit <- if (tau2 > 0) gls_fit(basic$y, S + tau2 * M, X) else fe
  d <- c(0, fit$beta)
  names(d) <- trt_order
  vb_full <- matrix(0, length(trt_order), length(trt_order),
                    dimnames = list(trt_order, trt_order))
  vb_full[params, params] <- fit$vb
  crit <- qnorm(1 - (1 - level) / 2)
  league <- league_table(d, vb_full, crit)
  pscore <- p_scores(d, vb_full, small_values)
  Q <- fe$Q
  Q_df <- length(basic$y) - length(params)
  decomp <- design_decomposition(basic, Q, Q_df)
  split <- direct_indirect_split(t1, t2, y, v, tau2, league, crit)
  effects <- tibble::tibble(
    treatment = trt_order,
    estimate = unname(d),
    std.error = unname(sqrt(diag(vb_full))),
    conf.low = unname(d) - crit * sqrt(diag(vb_full)),
    conf.high = unname(d) + crit * sqrt(diag(vb_full)),
    pscore = unname(pscore[trt_order])
  )
  effects$std.error[1] <- NA_real_
  effects$conf.low[1] <- NA_real_
  effects$conf.high[1] <- NA_real_
  nma <- list(
    method = method, level = level, measure = es_measure(.data),
    reference = reference, treatments = trt_order, d = d, vb = vb_full,
    tau2 = tau2, Q = Q, Q_df = Q_df,
    Q_p = if (Q_df > 0) pchisq(Q, Q_df, lower.tail = FALSE) else NA_real_,
    Q_heterogeneity = decomp$Q_het, df_heterogeneity = decomp$df_het,
    p_heterogeneity = decomp$p_het,
    Q_inconsistency = decomp$Q_inc, df_inconsistency = decomp$df_inc,
    p_inconsistency = decomp$p_inc, designs = decomp$designs,
    n_designs = nrow(decomp$designs),
    league = league, split = split, edges = edges,
    n_studies = length(unique(st)), n_contrasts = length(y),
    small_values = small_values,
    contrasts = tibble::tibble(study = st, treat1 = t1, treat2 = t2,
                               yi = y, vi = v),
    basic = basic
  )
  new_meta_nma(effects, nma = nma)
}

edge_table <- function(t1, t2, st) {
  a <- pmin(t1, t2)
  b <- pmax(t1, t2)
  key <- paste(a, b, sep = "\r")
  ukey <- unique(key)
  tibble::tibble(
    treat1 = a[match(ukey, key)],
    treat2 = b[match(ukey, key)],
    n_studies = vapply(ukey, function(kk) length(unique(st[key == kk])),
                       integer(1), USE.NAMES = FALSE)
  )
}

check_connected <- function(treatments, edges, call = caller_env()) {
  reached <- treatments[1]
  repeat {
    nxt <- unique(c(
      edges$treat2[edges$treat1 %in% reached],
      edges$treat1[edges$treat2 %in% reached]
    ))
    new <- setdiff(nxt, reached)
    if (length(new) == 0L) {
      break
    }
    reached <- c(reached, new)
  }
  if (length(reached) < length(treatments)) {
    cli::cli_abort(
      c(
        "The network is not connected.",
        "x" = "Not linked to {.val {treatments[1]}}: \\
               {.val {setdiff(treatments, reached)}}."
      ),
      call = call
    )
  }
  invisible(TRUE)
}

# Build basic contrasts (each arm against the study baseline) with their
# within-study covariance matrix S and the random effects structure M.
basic_contrasts <- function(st, t1, t2, y, v, trt_order,
                            call = caller_env()) {
  studies <- unique(st)
  rows_y <- numeric()
  rows_X <- list()
  S_blocks <- list()
  M_blocks <- list()
  row_study <- character()
  row_design <- character()
  row_arm <- character()
  row_base <- character()
  for (s in studies) {
    idx <- which(st == s)
    arms <- intersect(trt_order, unique(c(t1[idx], t2[idx])))
    m <- length(arms)
    n_expected <- m * (m - 1) / 2
    if (length(idx) != n_expected) {
      cli::cli_abort(
        c(
          "Study {.val {s}} has {m} arms but {length(idx)} contrast{?s}.",
          "i" = "Multi-arm studies must supply every pairwise contrast \\
                 (see {.fn meta_pairwise})."
        ),
        call = call
      )
    }
    # Effect of a vs b within the study
    eff <- function(a, b) {
      j <- which(t1[idx] == a & t2[idx] == b)
      if (length(j) == 1L) {
        return(c(y[idx][j], v[idx][j]))
      }
      j <- which(t1[idx] == b & t2[idx] == a)
      c(-y[idx][j], v[idx][j])
    }
    base <- arms[1]
    others <- arms[-1]
    if (m == 2L) {
      e <- eff(others, base)
      yy <- e[1]
      Sb <- matrix(e[2], 1, 1)
    } else {
      pair_mat <- utils::combn(m, 2)
      B <- matrix(0, ncol(pair_mat), m)
      vv <- numeric(ncol(pair_mat))
      for (j in seq_len(ncol(pair_mat))) {
        B[j, pair_mat[, j]] <- 1
        vv[j] <- eff(arms[pair_mat[1, j]], arms[pair_mat[2, j]])[2]
      }
      s_arm <- c(solve(crossprod(B), crossprod(B, vv)))
      if (any(s_arm <= 0)) {
        cli::cli_warn(
          "Reconstructed arm variances for study {.val {s}} were not \\
           all positive; they were truncated at a small positive value.",
          call = call
        )
        s_arm <- pmax(s_arm, 1e-8)
      }
      yy <- vapply(others, function(a) eff(a, base)[1], numeric(1))
      Sb <- matrix(s_arm[1], m - 1, m - 1)
      diag(Sb) <- s_arm[-1] + s_arm[1]
    }
    Mb <- matrix(0.5, m - 1, m - 1)
    diag(Mb) <- 1
    Xb <- matrix(0, m - 1, length(trt_order),
                 dimnames = list(NULL, trt_order))
    for (j in seq_along(others)) {
      Xb[j, others[j]] <- 1
      Xb[j, base] <- -1
    }
    rows_y <- c(rows_y, yy)
    rows_X[[length(rows_X) + 1L]] <- Xb
    S_blocks[[length(S_blocks) + 1L]] <- Sb
    M_blocks[[length(M_blocks) + 1L]] <- Mb
    row_study <- c(row_study, rep(s, m - 1))
    row_design <- c(row_design, rep(paste(arms, collapse = ":"), m - 1))
    row_arm <- c(row_arm, others)
    row_base <- c(row_base, rep(base, m - 1))
  }
  list(
    y = rows_y, X = do.call(rbind, rows_X),
    S = block_diag(S_blocks), M = block_diag(M_blocks),
    study = row_study, design = row_design, arm = row_arm, base = row_base
  )
}

block_diag <- function(blocks) {
  sizes <- vapply(blocks, nrow, integer(1))
  n <- sum(sizes)
  out <- matrix(0, n, n)
  pos <- 0L
  for (b in blocks) {
    i <- pos + seq_len(nrow(b))
    out[i, i] <- b
    pos <- pos + nrow(b)
  }
  out
}

gls_fit <- function(y, V, X) {
  Vinv <- inv_sym(V)
  vb <- inv_sym(crossprod(X, Vinv %*% X))
  beta <- c(vb %*% crossprod(X, Vinv %*% y))
  r <- y - c(X %*% beta)
  list(beta = beta, vb = vb, Q = c(crossprod(r, Vinv %*% r)), Vinv = Vinv)
}

nma_reml_tau2 <- function(y, S, M, X) {
  nll <- function(t2) {
    V <- S + t2 * M
    L <- chol(V)
    Vinv <- chol2inv(L)
    XtVX <- crossprod(X, Vinv %*% X)
    beta <- solve(XtVX, crossprod(X, Vinv %*% y))
    r <- y - X %*% beta
    0.5 * (2 * sum(log(diag(L))) +
             c(determinant(XtVX, logarithm = TRUE)$modulus) +
             c(crossprod(r, Vinv %*% r)))
  }
  opt <- stats::nlminb(0.05, nll, lower = 0,
                       control = list(rel.tol = 1e-12, x.tol = 1e-12))
  max(0, opt$par)
}

league_table <- function(d, vb, crit) {
  trt <- names(d)
  grid <- expand.grid(i = seq_along(trt), j = seq_along(trt))
  grid <- grid[grid$i != grid$j, , drop = FALSE]
  est <- d[grid$i] - d[grid$j]
  se <- sqrt(vb[cbind(grid$i, grid$i)] + vb[cbind(grid$j, grid$j)] -
               2 * vb[cbind(grid$i, grid$j)])
  z <- est / se
  tibble::tibble(
    treat1 = trt[grid$i],
    treat2 = trt[grid$j],
    estimate = unname(est),
    std.error = unname(se),
    statistic = unname(z),
    p.value = 2 * pnorm(abs(unname(z)), lower.tail = FALSE),
    conf.low = unname(est) - crit * unname(se),
    conf.high = unname(est) + crit * unname(se)
  )
}

p_scores <- function(d, vb, small_values) {
  trt <- names(d)
  n <- length(trt)
  out <- numeric(n)
  names(out) <- trt
  for (i in seq_len(n)) {
    total <- 0
    for (j in seq_len(n)[-i]) {
      se <- sqrt(vb[i, i] + vb[j, j] - 2 * vb[i, j])
      diff <- d[i] - d[j]
      total <- total + if (small_values == "good") {
        pnorm(-diff / se)
      } else {
        pnorm(diff / se)
      }
    }
    out[i] <- total / (n - 1)
  }
  out
}

design_decomposition <- function(basic, Q, Q_df) {
  designs <- unique(basic$design)
  q_d <- df_d <- numeric(length(designs))
  n_st <- integer(length(designs))
  for (i in seq_along(designs)) {
    rows <- which(basic$design == designs[i])
    n_st[i] <- length(unique(basic$study[rows]))
    arm <- basic$arm[rows]
    Xd <- outer(arm, unique(arm), `==`) * 1
    Sd <- basic$S[rows, rows, drop = FALSE]
    if (n_st[i] > 1L) {
      q_d[i] <- gls_fit(basic$y[rows], Sd, Xd)$Q
      df_d[i] <- length(rows) - ncol(Xd)
    }
  }
  Q_het <- sum(q_d)
  df_het <- sum(df_d)
  Q_inc <- Q - Q_het
  df_inc <- Q_df - df_het
  list(
    designs = tibble::tibble(design = designs, n_studies = n_st,
                             Q = q_d, df = df_d,
                             p.value = ifelse(df_d > 0,
                                              pchisq(q_d, df_d,
                                                     lower.tail = FALSE),
                                              NA_real_)),
    Q_het = Q_het, df_het = df_het,
    p_het = if (df_het > 0) pchisq(Q_het, df_het, lower.tail = FALSE) else
      NA_real_,
    Q_inc = if (df_inc > 0) max(0, Q_inc) else NA_real_,
    df_inc = df_inc,
    p_inc = if (df_inc > 0) pchisq(max(0, Q_inc), df_inc,
                                   lower.tail = FALSE) else NA_real_
  )
}

direct_indirect_split <- function(t1, t2, y, v, tau2, league, crit) {
  a <- pmin(t1, t2)
  b <- pmax(t1, t2)
  yy <- ifelse(t1 == a, y, -y)
  pairs <- unique(data.frame(a = a, b = b, stringsAsFactors = FALSE))
  out <- lapply(seq_len(nrow(pairs)), function(i) {
    sel <- a == pairs$a[i] & b == pairs$b[i]
    w <- 1 / (v[sel] + tau2)
    dir <- sum(w * yy[sel]) / sum(w)
    v_dir <- 1 / sum(w)
    net_row <- league$treat1 == pairs$a[i] & league$treat2 == pairs$b[i]
    net <- league$estimate[net_row]
    v_net <- league$std.error[net_row]^2
    if (v_dir - v_net > 1e-12) {
      v_ind <- 1 / (1 / v_net - 1 / v_dir)
      ind <- v_ind * (net / v_net - dir / v_dir)
      diff <- dir - ind
      se_diff <- sqrt(v_dir + v_ind)
      p <- 2 * pnorm(abs(diff / se_diff), lower.tail = FALSE)
    } else {
      v_ind <- ind <- diff <- se_diff <- p <- NA_real_
    }
    tibble::tibble(
      treat1 = pairs$a[i], treat2 = pairs$b[i],
      n_contrasts = sum(sel),
      network = net, direct = dir, direct_se = sqrt(v_dir),
      indirect = ind, indirect_se = sqrt(v_ind),
      difference = diff, difference_se = se_diff, p.value = p
    )
  })
  vctrs::vec_rbind(!!!out)
}

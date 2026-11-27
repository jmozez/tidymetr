#' Compute study level effect sizes
#'
#' `meta_effect_size()` adds an effect size (`.yi`), its sampling variance
#' (`.vi`) and standard error (`.sei`) to every row of a data frame and
#' returns a [`<meta_es>`][new_meta_es()] tibble that the rest of the
#' package understands.
#'
#' @section Measures:
#' \describe{
#'   \item{`"SMD"`}{Standardised mean difference with Hedges' exact small
#'     sample correction (Hedges' g). Needs `m1`, `sd1`, `n1`, `m2`, `sd2`,
#'     `n2`. The variance is \eqn{1/n_1 + 1/n_2 + g^2 / (2(n_1 + n_2))}.}
#'   \item{`"MD"`}{Raw mean difference, with variance
#'     \eqn{sd_1^2/n_1 + sd_2^2/n_2}. Needs the same columns as `"SMD"`.}
#'   \item{`"RR"`}{Log risk ratio. Needs `event1`, `n1`, `event2`, `n2`.}
#'   \item{`"OR"`}{Log odds ratio. Needs `event1`, `n1`, `event2`, `n2`.}
#'   \item{`"IRR"`}{Log incidence rate ratio. Needs `event1`, `time1`,
#'     `event2`, `time2` (person time).}
#'   \item{`"ZCOR"`}{Fisher's z transformed correlation, with variance
#'     \eqn{1/(n - 3)}. Needs `r` and `n`.}
#'   \item{`"PLO"`}{Logit transformed proportion. Needs `event` and `n`.}
#'   \item{`"GEN"`}{Generic, precomputed effect sizes. Needs `yi` and either
#'     `vi` or `sei`.}
#' }
#'
#' Group 1 is the treatment or exposed group and group 2 the comparison
#' group, so positive values favour group 1 having the larger mean, risk,
#' odds or rate. The aliases `"g"`, `"logRR"`, `"logOR"`, `"logIRR"`,
#' `"fisher_z"` and `"logit"` are also accepted.
#'
#' For the count based measures (`"RR"`, `"OR"`, `"IRR"`, `"PLO"`) the value
#' of `add` is added to the cells of studies with a zero cell when
#' `to = "only0"` (the default), to every study when `to = "all"`, or never
#' when `to = "none"`.
#'
#' @param .data A data frame or tibble with one row per study (or per
#'   effect size).
#' @param measure The effect size metric. See the Measures section.
#' @param ... These dots are for future extensions and must be empty.
#' @param m1,sd1,n1,m2,sd2,n2 <[`data-masking`][rlang::args_data_masking]>
#'   Means, standard deviations and sample sizes of groups 1 and 2. `n1` and
#'   `n2` are also the group sizes for `"RR"` and `"OR"`.
#' @param event1,event2 <[`data-masking`][rlang::args_data_masking]> Number
#'   of events in groups 1 and 2.
#' @param time1,time2 <[`data-masking`][rlang::args_data_masking]> Person
#'   time at risk in groups 1 and 2.
#' @param r,n <[`data-masking`][rlang::args_data_masking]> Correlation
#'   coefficients and sample sizes (`n` is also the total for `"PLO"`).
#' @param event <[`data-masking`][rlang::args_data_masking]> Number of
#'   events for `"PLO"`.
#' @param yi,vi,sei <[`data-masking`][rlang::args_data_masking]>
#'   Precomputed effect sizes with their variances or standard errors for
#'   `"GEN"`.
#' @param study <[`tidy-select`][dplyr::dplyr_tidy_select]> Optional column
#'   holding study labels, used in plots and tables.
#' @param add Value added to cells for zero cell corrections.
#' @param to Which studies receive the correction: `"only0"`, `"all"` or
#'   `"none"`.
#'
#' @return A [`<meta_es>`][new_meta_es()] tibble: `.data` plus the columns
#'   `.yi`, `.vi` and `.sei`.
#' @references
#' Hedges, L. V. (1981). Distribution theory for Glass's estimator of effect
#' size and related estimators. *Journal of Educational Statistics*, 6(2),
#' 107-128. \doi{10.3102/10769986006002107}
#'
#' Borenstein, M., Hedges, L. V., Higgins, J. P. T. and Rothstein, H. R.
#' (2009). *Introduction to Meta-Analysis*. Wiley.
#' @export
#' @examples
#' # Log risk ratios for the BCG vaccine trials
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg,
#'   event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' bcg
#'
#' # Hedges' g for length of hospital stay
#' meta_effect_size(stroke_los, "SMD",
#'   m1 = m1, sd1 = sd1, n1 = n1, m2 = m2, sd2 = sd2, n2 = n2
#' )
#'
#' # Fisher's z for correlations
#' meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni)
meta_effect_size <- function(.data, measure = "SMD", ...,
                             m1 = NULL, sd1 = NULL, n1 = NULL,
                             m2 = NULL, sd2 = NULL, n2 = NULL,
                             event1 = NULL, event2 = NULL,
                             time1 = NULL, time2 = NULL,
                             r = NULL, n = NULL, event = NULL,
                             yi = NULL, vi = NULL, sei = NULL,
                             study = NULL, add = 0.5,
                             to = c("only0", "all", "none")) {
  check_dots_empty()
  check_data_frame(.data)
  measure <- match_measure(measure)
  to <- arg_match(to)
  check_number(add, min = 0)
  quos <- list(
    m1 = enquo(m1), sd1 = enquo(sd1), n1 = enquo(n1),
    m2 = enquo(m2), sd2 = enquo(sd2), n2 = enquo(n2),
    event1 = enquo(event1), event2 = enquo(event2),
    time1 = enquo(time1), time2 = enquo(time2),
    r = enquo(r), n = enquo(n), event = enquo(event),
    yi = enquo(yi), vi = enquo(vi), sei = enquo(sei)
  )
  needed <- measure_inputs(measure)
  if (measure == "GEN") {
    has_vi <- !quo_is_null(quos$vi)
    needed <- c("yi", if (has_vi) "vi" else "sei")
  }
  missing_args <- needed[vapply(quos[needed], quo_is_null, logical(1))]
  if (length(missing_args) > 0L) {
    cli::cli_abort(
      c(
        "Measure {.val {measure}} needs {.arg {needed}}.",
        "x" = "Missing: {.arg {missing_args}}."
      )
    )
  }
  values <- lapply(needed, function(nm) {
    val <- eval_tidy(quos[[nm]], .data)
    check_numeric_column(val, nm)
    if (length(val) == 1L) {
      val <- rep(val, nrow(.data))
    }
    as.double(val)
  })
  names(values) <- needed
  es <- es_compute(measure, values, add = add, to = to)
  study_col <- select_one_col(enquo(study), .data)
  out <- as_bare_tibble(.data)
  out$.yi <- es$yi
  out$.vi <- es$vi
  out$.sei <- sqrt(es$vi)
  new_meta_es(out, measure = measure, study = study_col)
}

measure_aliases <- c(
  SMD = "SMD", G = "SMD", HEDGES_G = "SMD", MD = "MD",
  RR = "RR", LOGRR = "RR", OR = "OR", LOGOR = "OR",
  IRR = "IRR", LOGIRR = "IRR", ZCOR = "ZCOR", FISHER_Z = "ZCOR",
  PLO = "PLO", LOGIT = "PLO", GEN = "GEN"
)

match_measure <- function(measure, call = caller_env()) {
  if (!is.character(measure) || length(measure) != 1L) {
    cli::cli_abort("{.arg measure} must be a single string.", call = call)
  }
  key <- toupper(measure)
  if (!key %in% names(measure_aliases)) {
    cli::cli_abort(
      c(
        "Unknown effect size measure {.val {measure}}.",
        "i" = "Use one of {.or {.val {unique(measure_aliases)}}}."
      ),
      call = call
    )
  }
  unname(measure_aliases[key])
}

measure_inputs <- function(measure) {
  switch(measure,
    SMD = c("m1", "sd1", "n1", "m2", "sd2", "n2"),
    MD = c("m1", "sd1", "n1", "m2", "sd2", "n2"),
    RR = c("event1", "n1", "event2", "n2"),
    OR = c("event1", "n1", "event2", "n2"),
    IRR = c("event1", "time1", "event2", "time2"),
    ZCOR = c("r", "n"),
    PLO = c("event", "n"),
    GEN = c("yi", "vi")
  )
}

# Core effect size engine shared by meta_effect_size(), meta_pairwise() and
# step_meta_effect_size(). `values` is a named list of numeric vectors.
es_compute <- function(measure, values, add = 0.5, to = "only0",
                       call = caller_env()) {
  v <- values
  out <- switch(measure,
    SMD = es_smd(v$m1, v$sd1, v$n1, v$m2, v$sd2, v$n2, call = call),
    MD = list(
      yi = v$m1 - v$m2,
      vi = v$sd1^2 / v$n1 + v$sd2^2 / v$n2
    ),
    RR = es_binary(v$event1, v$n1, v$event2, v$n2, "RR", add, to, call),
    OR = es_binary(v$event1, v$n1, v$event2, v$n2, "OR", add, to, call),
    IRR = es_irr(v$event1, v$time1, v$event2, v$time2, add, to, call),
    ZCOR = es_zcor(v$r, v$n, call),
    PLO = es_plo(v$event, v$n, add, to, call),
    GEN = list(yi = v$yi, vi = if (is.null(v$vi)) v$sei^2 else v$vi)
  )
  bad <- !is.na(out$vi) & (out$vi <= 0 | !is.finite(out$vi))
  if (any(bad)) {
    cli::cli_warn(
      c(
        "{sum(bad)} effect size{?s} had a non-positive or infinite \\
         sampling variance and {?was/were} set to {.val NA}.",
        "i" = "Check the input columns for rows {which(bad)}."
      ),
      call = call
    )
    out$yi[bad] <- NA_real_
    out$vi[bad] <- NA_real_
  }
  out
}

hedges_j <- function(m) {
  exp(lgamma(m / 2) - log(sqrt(m / 2)) - lgamma((m - 1) / 2))
}

es_smd <- function(m1, sd1, n1, m2, sd2, n2, call = caller_env()) {
  if (any(n1 < 2 | n2 < 2, na.rm = TRUE)) {
    cli::cli_abort("Group sizes must be at least 2 for {.val SMD}.",
                   call = call)
  }
  df <- n1 + n2 - 2
  sdp <- sqrt(((n1 - 1) * sd1^2 + (n2 - 1) * sd2^2) / df)
  d <- (m1 - m2) / sdp
  g <- hedges_j(df) * d
  list(yi = g, vi = 1 / n1 + 1 / n2 + g^2 / (2 * (n1 + n2)))
}

zero_rows <- function(cells, to) {
  any_zero <- Reduce(`|`, lapply(cells, function(x) !is.na(x) & x == 0))
  switch(to,
    only0 = any_zero,
    all = rep(TRUE, length(cells[[1]])),
    none = rep(FALSE, length(cells[[1]]))
  )
}

es_binary <- function(e1, n1, e2, n2, measure, add, to, call) {
  if (any(e1 > n1 | e2 > n2 | e1 < 0 | e2 < 0, na.rm = TRUE)) {
    cli::cli_abort(
      "Event counts must lie between 0 and the group size.",
      call = call
    )
  }
  a <- e1
  b <- n1 - e1
  c <- e2
  d <- n2 - e2
  fix <- zero_rows(list(a, b, c, d), to)
  a[fix] <- a[fix] + add
  b[fix] <- b[fix] + add
  c[fix] <- c[fix] + add
  d[fix] <- d[fix] + add
  if (measure == "RR") {
    yi <- log((a / (a + b)) / (c / (c + d)))
    vi <- 1 / a - 1 / (a + b) + 1 / c - 1 / (c + d)
  } else {
    yi <- log((a * d) / (b * c))
    vi <- 1 / a + 1 / b + 1 / c + 1 / d
  }
  list(yi = yi, vi = vi)
}

es_irr <- function(x1, t1, x2, t2, add, to, call) {
  if (any(t1 <= 0 | t2 <= 0, na.rm = TRUE)) {
    cli::cli_abort("Person time must be positive.", call = call)
  }
  fix <- zero_rows(list(x1, x2), to)
  x1[fix] <- x1[fix] + add
  x2[fix] <- x2[fix] + add
  list(yi = log((x1 / t1) / (x2 / t2)), vi = 1 / x1 + 1 / x2)
}

es_zcor <- function(r, n, call) {
  if (any(abs(r) >= 1, na.rm = TRUE)) {
    cli::cli_abort("Correlations must lie strictly between -1 and 1.",
                   call = call)
  }
  if (any(n <= 3, na.rm = TRUE)) {
    cli::cli_abort("Sample sizes must exceed 3 for {.val ZCOR}.",
                   call = call)
  }
  list(yi = atanh(r), vi = 1 / (n - 3))
}

es_plo <- function(x, n, add, to, call) {
  if (any(x < 0 | x > n, na.rm = TRUE)) {
    cli::cli_abort("Event counts must lie between 0 and {.arg n}.",
                   call = call)
  }
  m <- n - x
  fix <- zero_rows(list(x, m), to)
  x[fix] <- x[fix] + add
  m[fix] <- m[fix] + add
  list(yi = log(x / m), vi = 1 / x + 1 / m)
}

#' Back-transform effect sizes
#'
#' Converts pooled or study level estimates back to their natural scale:
#' exponentiation for log ratios, the inverse Fisher transformation for
#' `"ZCOR"` and the inverse logit for `"PLO"`. Other measures are returned
#' unchanged.
#'
#' @param .data A [`<meta_fit>`][new_meta_fit()] or a data frame.
#' @param measure The effect size measure. Taken from the fit when `.data`
#'   is a `<meta_fit>`.
#' @param cols <[`tidy-select`][dplyr::dplyr_tidy_select]> Columns to
#'   transform. Defaults to `estimate`, `conf.low` and `conf.high`.
#'
#' @return `.data` with the selected columns back-transformed, as a plain
#'   tibble.
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' meta_pool(bcg) |> meta_transform()
meta_transform <- function(.data, measure = NULL,
                           cols = c("estimate", "conf.low", "conf.high")) {
  check_data_frame(.data)
  if (is.null(measure)) {
    measure <- if (is_meta_fit(.data)) fit_info(.data)$measure else "GEN"
  }
  measure <- match_measure(measure)
  loc <- tidyselect::eval_select(enquo(cols), .data, allow_rename = FALSE)
  fun <- switch(measure,
    RR = exp, OR = exp, IRR = exp,
    ZCOR = tanh,
    PLO = stats::plogis,
    identity
  )
  out <- as_bare_tibble(.data)
  for (nm in names(loc)) {
    out[[nm]] <- fun(out[[nm]])
  }
  out
}

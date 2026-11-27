# Tibble subclasses -----------------------------------------------------------
#
# <meta_es>  : a data frame of studies with effect sizes in `.yi`, sampling
#              variances in `.vi` and standard errors in `.sei`.
# <meta_fit> : a coefficient table from a fitted meta-analytic model, with the
#              model internals stored in the "fit" attribute.
# <meta_nma> : the treatment effect table from a network meta-analysis, with
#              the network internals stored in the "nma" attribute.

# meta_es ---------------------------------------------------------------------

#' Effect size tibbles
#'
#' `new_meta_es()` is the low-level constructor for the `<meta_es>` class, a
#' tibble subclass that stores study level effect sizes (`.yi`), sampling
#' variances (`.vi`) and standard errors (`.sei`) together with the effect
#' size metric. `as_meta_es()` turns a data frame that already holds effect
#' sizes into a `<meta_es>`. `is_meta_es()` tests for the class.
#'
#' The class survives `dplyr` verbs such as [dplyr::filter()],
#' [dplyr::mutate()] and [dplyr::arrange()]. If an operation removes `.yi` or
#' `.vi`, the result falls back to a plain tibble.
#'
#' @param x A list or data frame of columns that includes `.yi`, `.vi` and
#'   `.sei`.
#' @param measure A string naming the effect size metric, for example
#'   `"SMD"` or `"OR"`.
#' @param study For `new_meta_es()`, the name of the column holding study
#'   labels, or `NULL`. For `as_meta_es()`, a
#'   <[`tidy-select`][dplyr::dplyr_tidy_select]> expression selecting that
#'   column.
#' @param .data A data frame.
#' @param yi,vi,sei <[`data-masking`][rlang::args_data_masking]> Columns
#'   holding effect sizes and either sampling variances (`vi`) or standard
#'   errors (`sei`).
#'
#' @return `new_meta_es()` and `as_meta_es()` return a `<meta_es>` tibble.
#'   `is_meta_es()` returns a single logical value.
#' @export
#' @examples
#' dat <- data.frame(id = 1:3, g = c(0.2, 0.5, 0.1), v = c(0.04, 0.02, 0.05))
#' es <- as_meta_es(dat, yi = g, vi = v, study = id)
#' es
#' is_meta_es(es)
new_meta_es <- function(x = list(.yi = double(), .vi = double(),
                                 .sei = double()),
                        measure = "GEN", study = NULL) {
  if (is.data.frame(x)) {
    x <- as_bare_tibble(x)
  }
  n <- if (length(x) == 0L) 0L else vctrs::vec_size(x[[1]])
  tibble::new_tibble(x, nrow = n, measure = measure, study = study,
                    class = "meta_es")
}

#' @rdname new_meta_es
#' @export
as_meta_es <- function(.data, yi, vi = NULL, sei = NULL, measure = "GEN",
                       study = NULL) {
  check_data_frame(.data)
  yi_val <- eval_tidy(enquo(yi), .data)
  vi_val <- eval_optional(enquo(vi), .data)
  sei_val <- eval_optional(enquo(sei), .data)
  if (is.null(vi_val) && is.null(sei_val)) {
    cli::cli_abort("Supply either {.arg vi} or {.arg sei}.")
  }
  if (is.null(vi_val)) {
    vi_val <- sei_val^2
  }
  check_numeric_column(yi_val, "yi")
  check_numeric_column(vi_val, "vi")
  check_variances(vi_val)
  study <- select_one_col(enquo(study), .data)
  out <- as_bare_tibble(.data)
  out$.yi <- as.double(yi_val)
  out$.vi <- as.double(vi_val)
  out$.sei <- sqrt(out$.vi)
  new_meta_es(out, measure = measure, study = study)
}

#' @rdname new_meta_es
#' @export
is_meta_es <- function(x) {
  inherits(x, "meta_es")
}

meta_es_restore <- function(x, to) {
  if (is.data.frame(x) && all(c(".yi", ".vi") %in% names(x))) {
    new_meta_es(as_bare_tibble(x), measure = attr(to, "measure"),
                study = attr(to, "study"))
  } else if (is.data.frame(x)) {
    as_bare_tibble(x)
  } else {
    x
  }
}

#' @export
vec_restore.meta_es <- function(x, to, ...) {
  meta_es_restore(x, to)
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.meta_es <- function(data, template) {
  meta_es_restore(data, template)
}

#' @export
`[.meta_es` <- function(x, ...) {
  out <- NextMethod()
  meta_es_restore(out, x)
}

#' @export
#' @method vec_ptype2 meta_es.meta_es
vec_ptype2.meta_es.meta_es <- function(x, y, ...) {
  out <- vctrs::tib_ptype2(x, y, ...)
  if (!identical(attr(x, "measure"), attr(y, "measure"))) {
    return(as_bare_tibble(out))
  }
  new_meta_es(as_bare_tibble(out), measure = attr(x, "measure"),
              study = attr(x, "study"))
}

#' @export
#' @method vec_ptype2 meta_es.tbl_df
vec_ptype2.meta_es.tbl_df <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_ptype2 tbl_df.meta_es
vec_ptype2.tbl_df.meta_es <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_ptype2 meta_es.data.frame
vec_ptype2.meta_es.data.frame <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_ptype2 data.frame.meta_es
vec_ptype2.data.frame.meta_es <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_cast meta_es.meta_es
vec_cast.meta_es.meta_es <- function(x, to, ...) {
  out <- vctrs::tib_cast(x, to, ...)
  new_meta_es(as_bare_tibble(out), measure = attr(to, "measure"),
              study = attr(to, "study"))
}

#' @export
#' @method vec_cast meta_es.tbl_df
vec_cast.meta_es.tbl_df <- function(x, to, ...) {
  out <- vctrs::tib_cast(x, to, ...)
  new_meta_es(as_bare_tibble(out), measure = attr(to, "measure"),
              study = attr(to, "study"))
}

#' @export
#' @method vec_cast tbl_df.meta_es
vec_cast.tbl_df.meta_es <- function(x, to, ...) {
  vctrs::tib_cast(x, to, ...)
}

#' @export
#' @method vec_cast meta_es.data.frame
vec_cast.meta_es.data.frame <- function(x, to, ...) {
  out <- vctrs::tib_cast(x, to, ...)
  new_meta_es(as_bare_tibble(out), measure = attr(to, "measure"),
              study = attr(to, "study"))
}

#' @export
#' @method vec_cast data.frame.meta_es
vec_cast.data.frame.meta_es <- function(x, to, ...) {
  vctrs::df_cast(x, to, ...)
}

#' @export
tbl_sum.meta_es <- function(x, ...) {
  c(
    "A meta_es" = paste(nrow(x), "rows x", ncol(x), "columns"),
    "Measure" = measure_label(attr(x, "measure"))
  )
}

# meta_fit --------------------------------------------------------------------

#' Fitted meta-analysis tibbles
#'
#' `new_meta_fit()` is the low-level constructor for `<meta_fit>`, the class
#' returned by [meta_pool()], [meta_regress()], [meta_subgroup()],
#' [meta_multilevel()] and [meta_trimfill()]. It is a tibble subclass whose
#' rows are model coefficients (`term`, `estimate`, `std.error`,
#' `statistic`, `p.value`, `conf.low`, `conf.high`). The model internals,
#' including the heterogeneity estimates and the study level inputs, are
#' kept in the `"fit"` attribute and are read by [glance()], [augment()],
#' [predict()][predict.meta_fit()] and [ggplot2::autoplot()].
#'
#' @param x A data frame of coefficients.
#' @param fit A named list of model internals.
#'
#' @return `new_meta_fit()` returns a `<meta_fit>`. `is_meta_fit()` returns
#'   a single logical value.
#' @export
#' @examples
#' fit <- meta_pool(meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' ))
#' is_meta_fit(fit)
new_meta_fit <- function(x, fit = list()) {
  x <- as_bare_tibble(x)
  tibble::new_tibble(x, nrow = nrow(x), fit = fit, class = "meta_fit")
}

#' @rdname new_meta_fit
#' @export
is_meta_fit <- function(x) {
  inherits(x, "meta_fit")
}

fit_info <- function(x) {
  attr(x, "fit", exact = TRUE)
}

meta_fit_restore <- function(x, to) {
  if (is.data.frame(x) && all(c("term", "estimate") %in% names(x))) {
    new_meta_fit(x, fit = fit_info(to))
  } else if (is.data.frame(x)) {
    as_bare_tibble(x)
  } else {
    x
  }
}

#' @export
vec_restore.meta_fit <- function(x, to, ...) {
  meta_fit_restore(x, to)
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.meta_fit <- function(data, template) {
  meta_fit_restore(data, template)
}

#' @export
`[.meta_fit` <- function(x, ...) {
  out <- NextMethod()
  meta_fit_restore(out, x)
}

#' @export
#' @method vec_ptype2 meta_fit.meta_fit
vec_ptype2.meta_fit.meta_fit <- function(x, y, ...) {
  as_bare_tibble(vctrs::tib_ptype2(x, y, ...))
}

#' @export
#' @method vec_ptype2 meta_fit.tbl_df
vec_ptype2.meta_fit.tbl_df <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_ptype2 tbl_df.meta_fit
vec_ptype2.tbl_df.meta_fit <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_cast meta_fit.meta_fit
vec_cast.meta_fit.meta_fit <- function(x, to, ...) {
  new_meta_fit(vctrs::tib_cast(x, to, ...), fit = fit_info(to))
}

#' @export
#' @method vec_cast tbl_df.meta_fit
vec_cast.tbl_df.meta_fit <- function(x, to, ...) {
  vctrs::tib_cast(x, to, ...)
}

# meta_nma --------------------------------------------------------------------

#' Network meta-analysis tibbles
#'
#' `new_meta_nma()` is the low-level constructor for `<meta_nma>`, the class
#' returned by [meta_network()]. Each row is a treatment, with its effect
#' relative to the reference treatment and its P-score. The full network
#' (all pairwise comparisons, heterogeneity, inconsistency and the
#' direct and indirect evidence split) is kept in the `"nma"` attribute and
#' is returned by [tidy()][tidy.meta_nma()] and [glance()][glance.meta_nma()].
#'
#' @param x A data frame of treatment effects.
#' @param nma A named list of network internals.
#'
#' @return `new_meta_nma()` returns a `<meta_nma>`. `is_meta_nma()` returns
#'   a single logical value.
#' @export
#' @examples
#' pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
#' nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2)
#' is_meta_nma(nma)
new_meta_nma <- function(x, nma = list()) {
  x <- as_bare_tibble(x)
  tibble::new_tibble(x, nrow = nrow(x), nma = nma, class = "meta_nma")
}

#' @rdname new_meta_nma
#' @export
is_meta_nma <- function(x) {
  inherits(x, "meta_nma")
}

nma_info <- function(x) {
  attr(x, "nma", exact = TRUE)
}

meta_nma_restore <- function(x, to) {
  if (is.data.frame(x) && all(c("treatment", "estimate") %in% names(x))) {
    new_meta_nma(x, nma = nma_info(to))
  } else if (is.data.frame(x)) {
    as_bare_tibble(x)
  } else {
    x
  }
}

#' @export
vec_restore.meta_nma <- function(x, to, ...) {
  meta_nma_restore(x, to)
}

#' @exportS3Method dplyr::dplyr_reconstruct
dplyr_reconstruct.meta_nma <- function(data, template) {
  meta_nma_restore(data, template)
}

#' @export
`[.meta_nma` <- function(x, ...) {
  out <- NextMethod()
  meta_nma_restore(out, x)
}

#' @export
#' @method vec_ptype2 meta_nma.meta_nma
vec_ptype2.meta_nma.meta_nma <- function(x, y, ...) {
  as_bare_tibble(vctrs::tib_ptype2(x, y, ...))
}

#' @export
#' @method vec_ptype2 meta_nma.tbl_df
vec_ptype2.meta_nma.tbl_df <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_ptype2 tbl_df.meta_nma
vec_ptype2.tbl_df.meta_nma <- function(x, y, ...) {
  vctrs::tib_ptype2(x, y, ...)
}

#' @export
#' @method vec_cast meta_nma.meta_nma
vec_cast.meta_nma.meta_nma <- function(x, to, ...) {
  new_meta_nma(vctrs::tib_cast(x, to, ...), nma = nma_info(to))
}

#' @export
#' @method vec_cast tbl_df.meta_nma
vec_cast.tbl_df.meta_nma <- function(x, to, ...) {
  vctrs::tib_cast(x, to, ...)
}

# Printing --------------------------------------------------------------------

measure_label <- function(measure) {
  labels <- c(
    SMD = "standardised mean difference (Hedges' g)",
    MD = "mean difference",
    RR = "log risk ratio",
    OR = "log odds ratio",
    IRR = "log incidence rate ratio",
    ZCOR = "Fisher's z transformed correlation",
    PLO = "logit transformed proportion",
    GEN = "generic effect size"
  )
  if (is.null(measure) || !measure %in% names(labels)) {
    return("generic effect size")
  }
  unname(labels[measure])
}

method_label <- function(method) {
  labels <- c(
    FE = "common effect (fixed effect)",
    REML = "random effects, restricted maximum likelihood",
    ML = "random effects, maximum likelihood",
    DL = "random effects, DerSimonian-Laird",
    PM = "random effects, Paule-Mandel",
    SJ = "random effects, Sidik-Jonkman"
  )
  unname(labels[method])
}

#' @export
print.meta_fit <- function(x, ...) {
  info <- fit_info(x)
  type_label <- c(
    pool = "Meta-analysis",
    regression = "Meta-regression",
    subgroup = "Subgroup meta-analysis",
    multilevel = "Multilevel meta-analysis",
    trimfill = "Trim-and-fill adjusted meta-analysis"
  )
  cli::cat_line("# ", type_label[[info$model_type]], " <meta_fit>")
  if (info$model_type == "multilevel") {
    cli::cat_line("# Model: ", info$method, " with ",
                  length(info$sigma2), " random effect levels")
  } else {
    cli::cat_line("# Model: ", method_label(info$method))
  }
  cli::cat_line("# Measure: ", measure_label(info$measure),
                "; k = ", info$k)
  if (info$model_type == "multilevel") {
    for (nm in names(info$sigma2)) {
      cli::cat_line("# sigma^2 (", nm, ") = ", fmt_num(info$sigma2[[nm]]))
    }
  } else if (!is.null(info$tau2)) {
    cli::cat_line(
      "# tau^2 = ", fmt_num(info$tau2),
      "; I^2 = ", formatC(info$I2, digits = 2, format = "f"), "%",
      "; H^2 = ", formatC(info$H2, digits = 2, format = "f")
    )
  }
  if (!is.null(info$QE) && !is.na(info$QE)) {
    cli::cat_line("# Q(", info$df_resid, ") = ", fmt_num(info$QE, 2),
                  ", p ", fmt_p(info$QEp))
  }
  if (info$model_type == "subgroup") {
    cli::cat_line("# Test of subgroup differences: Q(", info$df_between,
                  ") = ", fmt_num(info$Q_between, 2), ", p ",
                  fmt_p(info$p_between))
  }
  if (info$model_type == "trimfill") {
    cli::cat_line("# Studies filled on the ", info$side, " side: ", info$k0)
  }
  if (!is.null(info$pi_low) && !is.na(info$pi_low)) {
    cli::cat_line("# ", info$level * 100, "% prediction interval: [",
                  fmt_num(info$pi_low), ", ", fmt_num(info$pi_high), "]")
  }
  if (info$test == "hksj") {
    cli::cat_line("# Inference: Hartung-Knapp-Sidik-Jonkman t tests (df = ",
                  info$ddf, ")")
  }
  print(as_bare_tibble(x), ...)
  invisible(x)
}

#' @export
print.meta_nma <- function(x, ...) {
  info <- nma_info(x)
  cli::cat_line("# Network meta-analysis <meta_nma>")
  cli::cat_line("# Model: ", method_label(info$method),
                "; reference: ", info$reference)
  cli::cat_line("# Measure: ", measure_label(info$measure), "; ",
                info$n_studies, " studies, ", length(info$treatments),
                " treatments, ", info$n_designs, " designs")
  cli::cat_line("# tau^2 = ", fmt_num(info$tau2), "; Q(", info$Q_df,
                ") = ", fmt_num(info$Q, 2), ", p ", fmt_p(info$Q_p))
  if (!is.na(info$Q_inconsistency)) {
    cli::cat_line("# Inconsistency between designs: Q(", info$df_inconsistency,
                  ") = ", fmt_num(info$Q_inconsistency, 2), ", p ",
                  fmt_p(info$p_inconsistency))
  }
  print(as_bare_tibble(x), ...)
  invisible(x)
}

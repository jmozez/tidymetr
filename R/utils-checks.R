# Internal validation and helper functions. None of these are exported.

check_data_frame <- function(x, arg = caller_arg(x), call = caller_env()) {
  if (!is.data.frame(x)) {
    cli::cli_abort(
      c(
        "{.arg {arg}} must be a data frame or tibble.",
        "x" = "You supplied an object of class {.cls {class(x)}}."
      ),
      call = call
    )
  }
  invisible(x)
}

check_level <- function(level, arg = caller_arg(level), call = caller_env()) {
  if (!is.numeric(level) || length(level) != 1L || is.na(level) ||
        level <= 0 || level >= 1) {
    cli::cli_abort(
      "{.arg {arg}} must be a single number strictly between 0 and 1.",
      call = call
    )
  }
  invisible(level)
}

check_number <- function(x, arg = caller_arg(x), call = caller_env(),
                         min = -Inf, allow_null = FALSE) {
  if (allow_null && is.null(x)) {
    return(invisible(x))
  }
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < min) {
    cli::cli_abort(
      "{.arg {arg}} must be a single number of at least {min}.",
      call = call
    )
  }
  invisible(x)
}

check_numeric_column <- function(x, name, call = caller_env()) {
  if (!is.numeric(x)) {
    cli::cli_abort(
      c(
        "Column {.field {name}} must be numeric.",
        "x" = "It is of class {.cls {class(x)}}."
      ),
      call = call
    )
  }
  invisible(x)
}

check_variances <- function(vi, call = caller_env()) {
  bad <- !is.na(vi) & vi <= 0
  if (any(bad)) {
    cli::cli_abort(
      c(
        "Sampling variances must be strictly positive.",
        "x" = "{sum(bad)} value{?s} {?is/are} zero or negative \\
               (row{?s} {which(bad)})."
      ),
      call = call
    )
  }
  invisible(vi)
}

check_min_k <- function(k, min = 2L, what = "studies", call = caller_env()) {
  if (k < min) {
    cli::cli_abort(
      c(
        "At least {min} {what} are needed for this analysis.",
        "x" = "Only {k} usable {cli::qty(k)}row{?s} {?was/were} found."
      ),
      call = call
    )
  }
  invisible(k)
}

# Evaluate an optional data-masked argument. Returns NULL when the quosure
# is NULL or missing.
eval_optional <- function(quo, data) {
  if (quo_is_missing(quo) || quo_is_null(quo)) {
    return(NULL)
  }
  eval_tidy(quo, data)
}

# Label a quosure for messages.
quo_label <- function(quo) {
  as_label(quo)
}

# Default study labels.
make_study_labels <- function(study, n) {
  if (is.null(study)) {
    return(paste("Study", seq_len(n)))
  }
  as.character(study)
}

# Drop a tibble subclass and return a bare tibble without extra
# attributes.
as_bare_tibble <- function(x) {
  n <- vctrs::vec_size(x)
  cols <- lapply(seq_along(x), function(i) x[[i]])
  names(cols) <- names(x)
  tibble::new_tibble(cols, nrow = n)
}

# Resolve the yi, vi and study inputs used by most analysis functions.
# `.data` may be a data frame (columns are evaluated with data masking) or
# a <meta_fit> (the stored inputs are reused).
resolve_meta_input <- function(.data, yi, vi, study = quo(NULL),
                               call = caller_env()) {
  check_data_frame(.data, arg = ".data", call = call)
  if (inherits(.data, "meta_fit")) {
    info <- fit_info(.data)
    return(list(
      yi = info$yi,
      vi = info$vi,
      study = info$study,
      data = info$data,
      method = info$method,
      test = info$test,
      level = info$level,
      fit = .data
    ))
  }
  yi_val <- eval_tidy(yi, .data)
  vi_val <- eval_tidy(vi, .data)
  check_numeric_column(yi_val, quo_label(yi), call = call)
  check_numeric_column(vi_val, quo_label(vi), call = call)
  if (length(yi_val) != nrow(.data) || length(vi_val) != nrow(.data)) {
    cli::cli_abort(
      "{.arg yi} and {.arg vi} must have one value per row of {.arg .data}.",
      call = call
    )
  }
  study_val <- eval_optional(study, .data)
  if (is.null(study_val) && inherits(.data, "meta_es")) {
    study_col <- attr(.data, "study")
    if (!is.null(study_col) && study_col %in% names(.data)) {
      study_val <- .data[[study_col]]
    }
  }
  data <- as_bare_tibble(.data)
  keep <- !is.na(yi_val) & !is.na(vi_val)
  if (any(!keep)) {
    cli::cli_warn(
      "Dropped {sum(!keep)} row{?s} with a missing effect size or variance.",
      call = call
    )
  }
  check_variances(vi_val[keep], call = call)
  list(
    yi = yi_val[keep],
    vi = vi_val[keep],
    study = make_study_labels(study_val, nrow(.data))[keep],
    data = data[keep, , drop = FALSE],
    method = NULL,
    test = NULL,
    level = NULL,
    fit = NULL
  )
}

match_method <- function(method, choices = c("REML", "DL", "PM", "SJ",
                                               "ML", "FE"),
                         call = caller_env()) {
  method <- toupper(method[1])
  if (method == "COMMON") {
    method <- "FE"
  }
  if (!method %in% choices) {
    cli::cli_abort(
      c(
        "{.arg method} must be one of {.or {.val {choices}}}.",
        "x" = "You supplied {.val {method}}."
      ),
      call = call
    )
  }
  method
}

match_test <- function(test, call = caller_env()) {
  test <- tolower(test[1])
  if (test %in% c("knha", "hk", "hartung-knapp")) {
    test <- "hksj"
  }
  if (!test %in% c("z", "hksj", "t")) {
    cli::cli_abort(
      "{.arg test} must be one of {.or {.val {c('z', 'hksj', 't')}}}.",
      call = call
    )
  }
  test
}

# Wald confidence interval helper.
wald_ci <- function(est, se, crit) {
  list(lower = est - crit * se, upper = est + crit * se)
}

# Safe matrix inverse for symmetric positive definite matrices.
inv_sym <- function(m) {
  out <- tryCatch(chol2inv(chol(m)), error = function(e) NULL)
  if (is.null(out)) {
    out <- solve(m)
  }
  out
}

fmt_num <- function(x, digits = 4) {
  formatC(x, digits = digits, format = "f")
}

fmt_p <- function(p) {
  ifelse(is.na(p), "= NA",
         ifelse(p < 1e-4, "< 0.0001",
                paste("=", formatC(p, digits = 4, format = "f"))))
}

# Resolve an optional single-column tidyselect argument to a column name.
select_one_col <- function(quo, data, arg = "study", call = caller_env()) {
  if (quo_is_missing(quo) || quo_is_null(quo)) {
    return(NULL)
  }
  loc <- tidyselect::eval_select(quo, data, allow_rename = FALSE,
                                 error_call = call)
  if (length(loc) != 1L) {
    cli::cli_abort("{.arg {arg}} must select exactly one column.",
                   call = call)
  }
  names(loc)
}

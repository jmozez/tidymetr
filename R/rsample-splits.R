#' Leave-one-study-out cross-validation
#'
#' `meta_leave_study_out_cv()` creates an `rsample` resampling object in
#' which each study in turn forms the assessment set and the remaining
#' studies form the analysis set. Every effect size from the same study is
#' held out together, which avoids leakage when studies report several
#' correlated effect sizes. It is the natural way to estimate how well a
#' meta-regression predicts the result of a new study.
#'
#' @param .data A data frame, usually a [`<meta_es>`][new_meta_es()].
#' @param study <[`data-masking`][rlang::args_data_masking]> The study
#'   identifier.
#'
#' @return An `rset` tibble of class `meta_leave_study_out_cv` with columns
#'   `splits` and `id` (the study label).
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
#' )
#' folds <- meta_leave_study_out_cv(bcg, study = author)
#' folds
#' rsample::assessment(folds$splits[[1]])
meta_leave_study_out_cv <- function(.data, study) {
  check_data_frame(.data)
  st <- eval_tidy(enquo(study), .data)
  if (length(st) != nrow(.data)) {
    cli::cli_abort("{.arg study} must have one value per row.")
  }
  if (anyNA(st)) {
    cli::cli_abort("{.arg study} must not contain missing values.")
  }
  studies <- unique(st)
  if (length(studies) < 2L) {
    cli::cli_abort("At least two studies are needed for resampling.")
  }
  splits <- lapply(studies, function(s) {
    out <- which(st == s)
    rsample::make_splits(
      list(analysis = which(st != s), assessment = out),
      data = .data
    )
  })
  ids <- tibble::tibble(id = as.character(studies))
  rsample::new_rset(
    splits = splits, ids = ids,
    attrib = list(group = as_label(enquo(study))),
    subclass = c("meta_leave_study_out_cv", "rset")
  )
}

#' Cluster cross-validation for meta-analytic data
#'
#' `meta_cluster_cv()` splits clusters (for example research groups,
#' laboratories, countries or species) into `v` folds so that all effect
#' sizes from a cluster are in the same fold. Folds are balanced by the
#' number of effect sizes: clusters are shuffled and then assigned, largest
#' first, to the fold that currently holds the fewest rows.
#'
#' @param .data A data frame, usually a [`<meta_es>`][new_meta_es()].
#' @param cluster <[`data-masking`][rlang::args_data_masking]> The cluster
#'   identifier.
#' @param v The number of folds. Must not exceed the number of clusters.
#' @param repeats The number of times to repeat the partitioning.
#'
#' @return An `rset` tibble of class `meta_cluster_cv` with columns
#'   `splits` and `id` (and `id2` when `repeats > 1`).
#' @export
#' @examples
#' set.seed(1)
#' folds <- meta_cluster_cv(school_calendar, cluster = district, v = 4)
#' folds
meta_cluster_cv <- function(.data, cluster, v = 5, repeats = 1) {
  check_data_frame(.data)
  check_number(v, min = 2)
  check_number(repeats, min = 1)
  cl <- eval_tidy(enquo(cluster), .data)
  if (length(cl) != nrow(.data) || anyNA(cl)) {
    cli::cli_abort(
      "{.arg cluster} must have one non-missing value per row."
    )
  }
  clusters <- unique(cl)
  if (v > length(clusters)) {
    cli::cli_abort(
      c(
        "{.arg v} cannot exceed the number of clusters.",
        "x" = "{.arg v} is {v} but there are {length(clusters)} clusters."
      )
    )
  }
  sizes <- table(factor(cl, levels = clusters))
  one_partition <- function() {
    shuffled <- clusters[sample.int(length(clusters))]
    ord <- shuffled[order(-as.integer(sizes[as.character(shuffled)]))]
    load <- numeric(v)
    fold_of <- stats::setNames(integer(length(clusters)), clusters)
    for (cc in ord) {
      f <- which.min(load)
      fold_of[as.character(cc)] <- f
      load[f] <- load[f] + sizes[[as.character(cc)]]
    }
    fold_of[as.character(cl)]
  }
  splits <- list()
  ids <- list()
  for (r in seq_len(repeats)) {
    folds <- one_partition()
    for (f in seq_len(v)) {
      splits[[length(splits) + 1L]] <- rsample::make_splits(
        list(analysis = which(folds != f), assessment = which(folds == f)),
        data = .data
      )
      ids[[length(ids) + 1L]] <- c(
        if (repeats > 1) sprintf("Repeat%d", r),
        sprintf("Fold%d", f)
      )
    }
  }
  id_mat <- do.call(rbind, ids)
  ids <- if (repeats > 1) {
    tibble::tibble(id = id_mat[, 1], id2 = id_mat[, 2])
  } else {
    tibble::tibble(id = id_mat[, 1])
  }
  rsample::new_rset(
    splits = splits, ids = ids,
    attrib = list(v = v, repeats = repeats,
                  group = as_label(enquo(cluster))),
    subclass = c("meta_cluster_cv", "rset")
  )
}

#' @export
pretty.meta_leave_study_out_cv <- function(x, ...) {
  "Leave-one-study-out cross-validation"
}

#' @export
pretty.meta_cluster_cv <- function(x, ...) {
  details <- attributes(x)
  paste0(details$v, "-fold cluster cross-validation",
         if (details$repeats > 1) paste0(" repeated ", details$repeats,
                                         " times"))
}

#' @export
print.meta_leave_study_out_cv <- function(x, ...) {
  print_meta_rset(x, ...)
}

#' @export
print.meta_cluster_cv <- function(x, ...) {
  print_meta_rset(x, ...)
}

print_meta_rset <- function(x, ...) {
  cli::cat_line("#  ", pretty(x))
  y <- x
  class(y) <- setdiff(class(y), c("meta_leave_study_out_cv",
                                  "meta_cluster_cv", "rset"))
  print(y, ...)
  invisible(x)
}

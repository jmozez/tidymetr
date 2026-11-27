#' Plot meta-analytic fits
#'
#' `autoplot()` methods that draw the standard displays of a meta-analysis
#' with `ggplot2`:
#'
#' * `"forest"`: study estimates with confidence intervals (squares sized by
#'   weight) and the pooled estimate as a diamond, with the prediction
#'   interval as a line through it. Subgroup fits show one diamond per
#'   subgroup.
#' * `"funnel"`: effect sizes (or residuals, for models with moderators)
#'   against standard errors with pseudo confidence limits. Studies imputed
#'   by [meta_trimfill()] are drawn as open circles.
#' * `"baujat"`: each study's contribution to the heterogeneity Q statistic
#'   against its influence on the pooled estimate (Baujat et al., 2002).
#' * `"radial"`: the Galbraith (radial) plot of standardised effects
#'   against precision, with the pooled estimate as the slope.
#'
#' @param object A [`<meta_fit>`][new_meta_fit()].
#' @param type The type of plot.
#' @param ... Not used.
#'
#' @return A `ggplot` object.
#' @references
#' Baujat, B., Mahe, C., Pignon, J.-P. and Hill, C. (2002). A graphical
#' method for exploring heterogeneity in meta-analyses: application to a
#' meta-analysis of 65 trials. *Statistics in Medicine*, 21(18), 2641-2652.
#' \doi{10.1002/sim.1221}
#'
#' Galbraith, R. F. (1988). A note on graphical presentation of estimated
#' odds ratios from several clinical trials. *Statistics in Medicine*,
#' 7(8), 889-894. \doi{10.1002/sim.4780070807}
#' @export
#' @examples
#' bcg <- meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg,
#'   study = author
#' )
#' fit <- meta_pool(bcg)
#' autoplot(fit)
#' autoplot(fit, type = "funnel")
#' autoplot(meta_trimfill(fit), type = "funnel")
#' autoplot(fit, type = "baujat")
#' autoplot(fit, type = "radial")
autoplot.meta_fit <- function(object, type = c("forest", "funnel", "baujat",
                                               "radial"), ...) {
  type <- arg_match(type)
  info <- fit_info(object)
  switch(type,
    forest = plot_forest(object, info),
    funnel = plot_funnel(object, info),
    baujat = plot_baujat(info),
    radial = plot_radial(object, info)
  )
}

diamond <- function(est, lo, hi, y, label, h = 0.35) {
  tibble::tibble(
    polygon_x = c(lo, est, hi, est),
    polygon_y = c(y, y + h, y, y - h),
    group = label
  )
}

plot_forest <- function(object, info) {
  z <- qnorm(1 - (1 - info$level) / 2)
  k <- length(info$yi)
  studies <- tibble::tibble(
    label = info$study,
    estimate = info$yi,
    lower = info$yi - z * sqrt(info$vi),
    upper = info$yi + z * sqrt(info$vi),
    weight = 100 * info$weights / sum(info$weights),
    filled = if (is.null(info$filled)) FALSE else info$filled
  )
  coefs <- as_bare_tibble(object)
  if (info$model_type == "subgroup") {
    ord <- order(info$group)
    studies <- studies[ord, , drop = FALSE]
    grp <- as.character(info$group)[ord]
    pos <- numeric(k)
    y <- 0
    diamonds <- list()
    label_pos <- c()
    labels <- c()
    for (l in rev(levels(info$group))) {
      y <- y + 1
      row <- coefs[coefs$term == l, ]
      diamonds[[l]] <- diamond(row$estimate, row$conf.low, row$conf.high,
                               y, l)
      label_pos <- c(label_pos, y)
      labels <- c(labels, paste0(l, " (pooled)"))
      idx <- rev(which(grp == l))
      pos[idx] <- y + seq_along(idx)
      y <- y + length(idx)
    }
    studies$position <- pos
    dia <- vctrs::vec_rbind(!!!diamonds)
    breaks <- c(studies$position, label_pos)
    blabels <- c(studies$label, labels)
  } else {
    studies$position <- rev(seq_len(k)) + 1
    breaks <- studies$position
    blabels <- studies$label
    dia <- NULL
    if (info$p == 1L && colnames(info$X)[1] %in% c("overall")) {
      dia <- diamond(coefs$estimate[1], coefs$conf.low[1],
                     coefs$conf.high[1], 0, "overall")
      breaks <- c(breaks, 0)
      blabels <- c(blabels, "Pooled estimate")
    }
  }
  p <- ggplot2::ggplot(studies) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed",
                        colour = "grey50") +
    ggplot2::geom_segment(
      ggplot2::aes(x = lower, xend = upper, y = position, yend = position)
    ) +
    ggplot2::geom_point(
      ggplot2::aes(x = estimate, y = position, size = weight,
                   shape = filled),
      fill = "white"
    ) +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 15, `TRUE` = 22),
                                guide = "none") +
    ggplot2::scale_size_area(max_size = 5, guide = "none")
  if (!is.null(dia)) {
    if (!is.null(info$pi_low) && !is.na(info$pi_low)) {
      p <- p + ggplot2::annotate("segment", x = info$pi_low,
                                 xend = info$pi_high, y = 0, yend = 0,
                                 colour = "grey40", linewidth = 0.8)
    }
    p <- p + ggplot2::geom_polygon(
      data = dia,
      ggplot2::aes(x = polygon_x, y = polygon_y, group = group),
      fill = "grey20"
    )
  }
  p +
    ggplot2::scale_y_continuous(breaks = breaks, labels = blabels) +
    ggplot2::labs(x = measure_label(info$measure), y = NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.grid.major.y = ggplot2::element_blank())
}

plot_funnel <- function(object, info) {
  has_mods <- info$model_type %in% c("regression", "multilevel") &&
    info$p > 1L
  if (info$model_type == "subgroup") {
    has_mods <- TRUE
  }
  sei <- sqrt(info$vi)
  centre <- if (has_mods) 0 else as_bare_tibble(object)$estimate[1]
  x <- if (has_mods) info$yi - info$fitted else info$yi
  df <- tibble::tibble(
    x = x, y = sei,
    filled = if (is.null(info$filled)) FALSE else info$filled
  )
  z <- qnorm(1 - (1 - info$level) / 2)
  se_max <- max(sei) * 1.05
  funnel <- tibble::tibble(
    x = c(centre - z * se_max, centre, centre + z * se_max),
    y = c(se_max, 0, se_max)
  )
  ggplot2::ggplot(df, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_path(data = funnel, linetype = "dashed",
                       colour = "grey40") +
    ggplot2::geom_vline(xintercept = centre, colour = "grey40") +
    ggplot2::geom_point(ggplot2::aes(shape = filled), size = 2.5,
                        fill = "white") +
    ggplot2::scale_shape_manual(values = c(`FALSE` = 19, `TRUE` = 21),
                                labels = c(`FALSE` = "Observed",
                                           `TRUE` = "Filled"),
                                name = NULL) +
    ggplot2::scale_y_reverse() +
    ggplot2::labs(
      x = if (has_mods) "Residual" else measure_label(info$measure),
      y = "Standard error"
    ) +
    ggplot2::theme_minimal()
}

plot_baujat <- function(info) {
  if (!info$model_type %in% c("pool", "regression", "trimfill")) {
    cli::cli_abort(
      "Baujat plots are available for fits from {.fn meta_pool} and \\
       {.fn meta_regress}."
    )
  }
  k <- length(info$yi)
  pred_full <- c(info$X %*% info$beta)
  xh <- yh <- numeric(k)
  for (i in seq_len(k)) {
    res <- rma_engine(info$yi[-i], info$vi[-i],
                      info$X[-i, , drop = FALSE], method = info$method,
                      test = info$test, level = info$level)
    Xi <- info$X[i, , drop = FALSE]
    delpred <- c(Xi %*% res$beta)
    vdel <- c(Xi %*% res$vb %*% t(Xi))
    xh[i] <- (info$yi[i] - delpred)^2 / (info$tau2 + info$vi[i])
    yh[i] <- (delpred - pred_full[i])^2 / vdel
  }
  df <- tibble::tibble(x = xh, y = yh, label = info$study)
  ggplot2::ggplot(df, ggplot2::aes(x = x, y = y, label = label)) +
    ggplot2::geom_point(colour = "grey30") +
    ggplot2::geom_text(vjust = -0.7, size = 3) +
    ggplot2::labs(x = "Contribution to overall heterogeneity",
                  y = "Influence on overall result") +
    ggplot2::theme_minimal()
}

plot_radial <- function(object, info) {
  if (!info$model_type %in% c("pool", "trimfill")) {
    cli::cli_abort(
      "Radial plots are available for models without moderators."
    )
  }
  tau2 <- info$tau2
  prec <- 1 / sqrt(info$vi + tau2)
  zi <- info$yi * prec
  est <- as_bare_tibble(object)$estimate[1]
  z <- qnorm(1 - (1 - info$level) / 2)
  xmax <- max(prec) * 1.05
  lines <- tibble::tibble(
    x = 0, xend = xmax,
    y = c(0, z, -z), yend = c(est * xmax, est * xmax + z, est * xmax - z),
    type = c("estimate", "limit", "limit")
  )
  df <- tibble::tibble(x = prec, y = zi, label = info$study)
  ggplot2::ggplot(df, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
    ggplot2::geom_segment(
      data = lines,
      ggplot2::aes(x = x, xend = xend, y = y, yend = yend,
                   linetype = type),
      colour = "grey30"
    ) +
    ggplot2::scale_linetype_manual(values = c(estimate = "solid",
                                              limit = "dashed"),
                                   guide = "none") +
    ggplot2::geom_point(size = 2.5) +
    ggplot2::labs(x = expression(1 / sqrt(v[i] + tau^2)),
                  y = expression(y[i] / sqrt(v[i] + tau^2))) +
    ggplot2::theme_minimal()
}

#' Plot network meta-analyses
#'
#' `autoplot()` method for [`<meta_nma>`][new_meta_nma()] objects.
#' `type = "netgraph"` draws the network with treatments on a circle and
#' edge widths proportional to the number of studies making each direct
#' comparison. `type = "forest"` shows every treatment against the
#' reference, ordered by P-score.
#'
#' @param object A `<meta_nma>`.
#' @param type `"netgraph"` or `"forest"`.
#' @param ... Not used.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
#' nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
#'   reference = "no_contact", small_values = "bad")
#' autoplot(nma)
#' autoplot(nma, type = "forest")
autoplot.meta_nma <- function(object, type = c("netgraph", "forest"), ...) {
  type <- arg_match(type)
  info <- nma_info(object)
  if (type == "netgraph") {
    trt <- sort(info$treatments)
    n <- length(trt)
    angle <- pi / 2 - 2 * pi * (seq_len(n) - 1) / n
    nodes <- tibble::tibble(label = trt, x = cos(angle), y = sin(angle))
    nodes$hjust <- ifelse(nodes$x > 0.1, 0, ifelse(nodes$x < -0.1, 1, 0.5))
    nodes$vjust <- ifelse(nodes$y > 0.1, 0, ifelse(nodes$y < -0.1, 1, 0.5))
    e <- info$edges
    i1 <- match(e$treat1, trt)
    i2 <- match(e$treat2, trt)
    edges <- tibble::tibble(
      x = nodes$x[i1], y = nodes$y[i1],
      xend = nodes$x[i2], yend = nodes$y[i2],
      n_studies = e$n_studies
    )
    return(
      ggplot2::ggplot() +
        ggplot2::geom_segment(
          data = edges,
          ggplot2::aes(x = x, y = y, xend = xend, yend = yend,
                       linewidth = n_studies),
          colour = "grey50", lineend = "round"
        ) +
        ggplot2::geom_point(data = nodes, ggplot2::aes(x = x, y = y),
                            size = 6, colour = "grey20") +
        ggplot2::geom_text(
          data = nodes,
          ggplot2::aes(x = x * 1.12, y = y * 1.12, label = label,
                       hjust = hjust, vjust = vjust),
          size = 3.5
        ) +
        ggplot2::scale_linewidth(range = c(0.5, 4),
                                 name = "Studies") +
        ggplot2::coord_equal(clip = "off") +
        ggplot2::scale_x_continuous(expand = ggplot2::expansion(0.3)) +
        ggplot2::scale_y_continuous(expand = ggplot2::expansion(0.2)) +
        ggplot2::theme_void()
    )
  }
  eff <- as_bare_tibble(object)
  eff <- eff[eff$treatment != info$reference, , drop = FALSE]
  eff$treatment <- factor(eff$treatment,
                          levels = eff$treatment[order(eff$pscore)])
  ggplot2::ggplot(eff, ggplot2::aes(x = estimate, y = treatment)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed",
                        colour = "grey50") +
    ggplot2::geom_segment(
      ggplot2::aes(x = conf.low, xend = conf.high, yend = treatment)
    ) +
    ggplot2::geom_point(shape = 15, size = 3) +
    ggplot2::labs(
      x = paste0(measure_label(info$measure), " versus ", info$reference),
      y = NULL
    ) +
    ggplot2::theme_minimal()
}

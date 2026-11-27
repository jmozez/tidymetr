#' tidymetr: tidy meta-analysis and evidence synthesis
#'
#' @description
#' tidymetr provides a pipe-friendly grammar for meta-analysis. Effect
#' sizes are computed with [meta_effect_size()], pooled with [meta_pool()],
#' explained with [meta_regress()], [meta_subgroup()] and
#' [meta_multilevel()], compared across treatments with [meta_network()],
#' checked for small-study effects with [meta_egger()], [meta_begg()],
#' [meta_trimfill()], [meta_pet_peese()] and [meta_failsafe()], and stress
#' tested with [meta_leave1out()], [meta_cumulative()] and
#' [meta_influence()]. Every estimator is written in base R and
#' validated against published reference results.
#'
#' Results are `tibble` subclasses that work with `dplyr`, `broom` style
#' tidiers ([tidy()], [glance()], [augment()]) and [ggplot2::autoplot()].
#' The `tidymodels` integration includes `recipes` steps
#' ([step_meta_effect_size()], [step_meta_precision()],
#' [step_meta_impute_sd()]), `rsample` resampling schemes
#' ([meta_leave_study_out_cv()], [meta_cluster_cv()]), `yardstick` metrics
#' ([inverse_var_rmse()], [coverage_prob()], [heterogeneity_r2()]) and a
#' `parsnip` model specification ([meta_linear()]).
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import rlang
#' @importFrom stats pnorm qnorm pt qt pchisq qchisq pf setNames median
#'   model.matrix model.frame model.response terms delete.response
#'   uniroot optimize optim weighted.mean cor.test lm coef vcov
#'   na.pass as.formula reformulate var predict
#' @importFrom generics tidy glance augment
#' @importFrom ggplot2 autoplot
#' @importFrom recipes prep bake required_pkgs
#' @importFrom pillar tbl_sum
#' @importFrom vctrs vec_restore vec_ptype2 vec_cast
#' @importFrom utils globalVariables
## usethis namespace: end
NULL

#' @export
generics::tidy

#' @export
generics::glance

#' @export
generics::augment

#' @export
ggplot2::autoplot

#' @export
recipes::prep

#' @export
recipes::bake

#' @export
recipes::required_pkgs

utils::globalVariables(c(
  ".yi", ".vi", ".sei", "estimate", "conf.low", "conf.high",
  "study", "position", "weight", "x", "y", "xend", "yend", "label",
  "type", "filled", "lower", "upper", "n_studies", "treatment", "group",
  "xmin", "xmax", "polygon_x", "polygon_y", "id", "hjust", "vjust"
))

# nocov start
.onLoad <- function(libname, pkgname) {
  register_meta_linear()
  invisible()
}
# nocov end

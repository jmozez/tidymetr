# tidymetr: tidy meta-analysis and evidence synthesis

tidymetr provides a pipe-friendly grammar for meta-analysis. Effect
sizes are computed with
[`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md),
pooled with
[`meta_pool()`](https://tidymetr.in4metrix.dev/reference/meta_pool.md),
explained with
[`meta_regress()`](https://tidymetr.in4metrix.dev/reference/meta_regress.md),
[`meta_subgroup()`](https://tidymetr.in4metrix.dev/reference/meta_subgroup.md)
and
[`meta_multilevel()`](https://tidymetr.in4metrix.dev/reference/meta_multilevel.md),
compared across treatments with
[`meta_network()`](https://tidymetr.in4metrix.dev/reference/meta_network.md),
checked for small-study effects with
[`meta_egger()`](https://tidymetr.in4metrix.dev/reference/meta_egger.md),
[`meta_begg()`](https://tidymetr.in4metrix.dev/reference/meta_begg.md),
[`meta_trimfill()`](https://tidymetr.in4metrix.dev/reference/meta_trimfill.md),
[`meta_pet_peese()`](https://tidymetr.in4metrix.dev/reference/meta_pet_peese.md)
and
[`meta_failsafe()`](https://tidymetr.in4metrix.dev/reference/meta_failsafe.md),
and stress tested with
[`meta_leave1out()`](https://tidymetr.in4metrix.dev/reference/meta_leave1out.md),
[`meta_cumulative()`](https://tidymetr.in4metrix.dev/reference/meta_cumulative.md)
and
[`meta_influence()`](https://tidymetr.in4metrix.dev/reference/meta_influence.md).
Every estimator is written in base R and validated against published
reference results.

Results are `tibble` subclasses that work with `dplyr`, `broom` style
tidiers ([`tidy()`](https://generics.r-lib.org/reference/tidy.html),
[`glance()`](https://generics.r-lib.org/reference/glance.html),
[`augment()`](https://generics.r-lib.org/reference/augment.html)) and
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html).
The `tidymodels` integration includes `recipes` steps
([`step_meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/step_meta_effect_size.md),
[`step_meta_precision()`](https://tidymetr.in4metrix.dev/reference/step_meta_precision.md),
[`step_meta_impute_sd()`](https://tidymetr.in4metrix.dev/reference/step_meta_impute_sd.md)),
`rsample` resampling schemes
([`meta_leave_study_out_cv()`](https://tidymetr.in4metrix.dev/reference/meta_leave_study_out_cv.md),
[`meta_cluster_cv()`](https://tidymetr.in4metrix.dev/reference/meta_cluster_cv.md)),
`yardstick` metrics
([`inverse_var_rmse()`](https://tidymetr.in4metrix.dev/reference/inverse_var_rmse.md),
[`coverage_prob()`](https://tidymetr.in4metrix.dev/reference/coverage_prob.md),
[`heterogeneity_r2()`](https://tidymetr.in4metrix.dev/reference/heterogeneity_r2.md))
and a `parsnip` model specification
([`meta_linear()`](https://tidymetr.in4metrix.dev/reference/meta_linear.md)).

## See also

Useful links:

- <https://tidymetr.in4metrix.dev/>

- <https://github.com/jmozez/tidymetr>

- Report bugs at <https://github.com/jmozez/tidymetr/issues>

## Author

**Maintainer**: Jimmy Moses <jimmy.moses@pnguot.ac.pg>
([ORCID](https://orcid.org/0000-0003-3342-2384)) \[copyright holder\]

Authors:

- Jimmy Moses <jimmy.moses@pnguot.ac.pg>
  ([ORCID](https://orcid.org/0000-0003-3342-2384)) \[copyright holder\]

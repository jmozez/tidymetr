# tidymetr (development version)

* New `meta_robust()` gives cluster-robust standard errors with the CR2
  small-sample correction and Satterthwaite degrees of freedom (Tipton
  2015; Pustejovsky and Tipton 2018) for pooled, meta-regression and
  multilevel fits. Results match `clubSandwich::coef_test()`.
* New `meta_selection()` fits step-function selection models for
  publication bias (Vevea and Hedges 1995), including the three-parameter
  selection model, with a likelihood-ratio test. Results match
  `metafor::selmodel()`.
* New `meta_bayes()` fits Bayesian random-effects meta-analysis with
  half-normal or half-Cauchy heterogeneity priors by exact numerical
  integration (Rover 2020), giving posterior summaries for the mean, the
  heterogeneity and the effect in a new study.

# tidymetr 0.1.0

* Initial version: effect sizes, pooled models (FE, REML, ML, DL, PM and SJ)
  with HKSJ tests and prediction intervals, meta-regression, subgroup and
  multilevel models, contrast-based network meta-analysis, small-study
  effect diagnostics, sensitivity analyses and tidymodels integration.
* The package was renamed from tidysynthesis to tidymetr before its first
  release, because the original name is already used on CRAN.

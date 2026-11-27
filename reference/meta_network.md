# Network meta-analysis

`meta_network()` fits a frequentist, contrast-based network
meta-analysis by generalised least squares (Lu and Ades, 2006; Rucker,
2012). Each study contributes the contrasts of its arms against a study
baseline. For studies with more than two arms, the arm level variances
are reconstructed from the pairwise variances (Rucker and Schwarzer,
2014), so the within-study covariance is respected. Random effects share
one between-study variance \\\tau^2\\ under the consistency assumption,
with covariance \\\tau^2/2\\ between contrasts of the same multi-arm
study, and \\\tau^2\\ is estimated by restricted maximum likelihood.

## Usage

``` r
meta_network(
  .data,
  study,
  treat1,
  treat2,
  yi = .yi,
  vi = .vi,
  reference = NULL,
  method = "REML",
  level = 0.95,
  small_values = c("good", "bad")
)
```

## Arguments

- .data:

  Contrast level data with one row per pairwise comparison, such as the
  output of
  [`meta_pairwise()`](https://tidymetr.in4metrix.dev/reference/meta_pairwise.md).

- study, treat1, treat2:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns identifying the study and the two treatments compared. The
  effect size is that of `treat1` relative to `treat2`.

- yi, vi:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Effect sizes and sampling variances. Default to `.yi` and `.vi`.

- reference:

  The reference treatment. Defaults to the most connected treatment.

- method:

  `"REML"` (random effects) or `"FE"` (common effect).

- level:

  Confidence level.

- small_values:

  Are small (negative) effect sizes `"good"` (for example fewer adverse
  events) or `"bad"` (for example fewer people who quit smoking)? Used
  for the P-scores.

## Value

A
[`<meta_nma>`](https://tidymetr.in4metrix.dev/reference/new_meta_nma.md)
with one row per treatment: the effect relative to the reference, its
confidence interval and the P-score. Use
[tidy()](https://tidymetr.in4metrix.dev/reference/meta_nma_tidiers.md)
for the league table, inconsistency decomposition and direct and
indirect split.

## Details

Treatments are ranked by P-scores (Rucker and Schwarzer, 2015), the
frequentist analogue of the surface under the cumulative ranking curve.
Global inconsistency is assessed by decomposing the common-effect Q
statistic into within-design heterogeneity and between-design
inconsistency (Krahn, Binder and Konig, 2013). Local inconsistency is
assessed for each comparison with direct evidence by contrasting the
direct estimate with the indirect estimate obtained by back-calculation
(Dias et al., 2010). The direct estimates pool every contrast that
compares the pair, so for multi-arm studies the split is approximate.

## References

Lu, G. and Ades, A. E. (2006). Assessing evidence inconsistency in mixed
treatment comparisons. *Journal of the American Statistical
Association*, 101(474), 447-459.
[doi:10.1198/016214505000001302](https://doi.org/10.1198/016214505000001302)

Rucker, G. (2012). Network meta-analysis, electrical networks and graph
theory. *Research Synthesis Methods*, 3(4), 312-324.
[doi:10.1002/jrsm.1058](https://doi.org/10.1002/jrsm.1058)

Rucker, G. and Schwarzer, G. (2014). Reduce dimension or reduce weights?
Comparing two approaches to multi-arm studies in network meta-analysis.
*Statistics in Medicine*, 33(25), 4353-4369.
[doi:10.1002/sim.6236](https://doi.org/10.1002/sim.6236)

Rucker, G. and Schwarzer, G. (2015). Ranking treatments in frequentist
network meta-analysis works without resampling methods. *BMC Medical
Research Methodology*, 15, 58.
[doi:10.1186/s12874-015-0060-8](https://doi.org/10.1186/s12874-015-0060-8)

Krahn, U., Binder, H. and Konig, J. (2013). A graphical tool for
locating inconsistency in network meta-analyses. *BMC Medical Research
Methodology*, 13, 35.
[doi:10.1186/1471-2288-13-35](https://doi.org/10.1186/1471-2288-13-35)

Dias, S., Welton, N. J., Caldwell, D. M. and Ades, A. E. (2010).
Checking consistency in mixed treatment comparison meta-analysis.
*Statistics in Medicine*, 29(7-8), 932-944.
[doi:10.1002/sim.3767](https://doi.org/10.1002/sim.3767)

## Examples

``` r
pw <- meta_pairwise(smoking_cessation, study = study, treatment = trt,
  measure = "OR", event = xi, n = ni)
nma <- meta_network(pw, study = study, treat1 = treat1, treat2 = treat2,
  reference = "no_contact", small_values = "bad")
nma
#> # Network meta-analysis <meta_nma>
#> # Model: random effects, restricted maximum likelihood; reference: no_contact
#> # Measure: log odds ratio; 24 studies, 4 treatments, 8 designs
#> # tau^2 = 0.4502; Q(23) = 202.62, p < 0.0001
#> # Inconsistency between designs: Q(7) = 15.22, p = 0.0333
#> # A tibble: 4 × 6
#>   treatment      estimate std.error conf.low conf.high pscore
#>   <chr>             <dbl>     <dbl>    <dbl>     <dbl>  <dbl>
#> 1 no_contact        0        NA       NA         NA    0.0411
#> 2 grp_counseling    0.869     0.372    0.139      1.60 0.847 
#> 3 ind_counseling    0.709     0.195    0.326      1.09 0.716 
#> 4 self_help         0.397     0.329   -0.247      1.04 0.396 
tidy(nma, type = "league")
#> # A tibble: 12 × 8
#>    treat1         treat2 estimate std.error statistic p.value conf.low conf.high
#>    <chr>          <chr>     <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
#>  1 grp_counseling no_co…    0.869     0.372     2.33  1.96e-2    0.139     1.60 
#>  2 ind_counseling no_co…    0.709     0.195     3.63  2.82e-4    0.326     1.09 
#>  3 self_help      no_co…    0.397     0.329     1.21  2.27e-1   -0.247     1.04 
#>  4 no_contact     grp_c…   -0.869     0.372    -2.33  1.96e-2   -1.60     -0.139
#>  5 ind_counseling grp_c…   -0.160     0.353    -0.452 6.51e-1   -0.852     0.533
#>  6 self_help      grp_c…   -0.472     0.405    -1.16  2.45e-1   -1.27      0.323
#>  7 no_contact     ind_c…   -0.709     0.195    -3.63  2.82e-4   -1.09     -0.326
#>  8 grp_counseling ind_c…    0.160     0.353     0.452 6.51e-1   -0.533     0.852
#>  9 self_help      ind_c…   -0.312     0.339    -0.920 3.58e-1   -0.976     0.353
#> 10 no_contact     self_…   -0.397     0.329    -1.21  2.27e-1   -1.04      0.247
#> 11 grp_counseling self_…    0.472     0.405     1.16  2.45e-1   -0.323     1.27 
#> 12 ind_counseling self_…    0.312     0.339     0.920 3.58e-1   -0.353     0.976
tidy(nma, type = "inconsistency")
#> # A tibble: 3 × 4
#>   source              Q    df  p.value
#>   <chr>           <dbl> <int>    <dbl>
#> 1 total           203.     23 1.08e-30
#> 2 within designs  187.     16 2.75e-31
#> 3 between designs  15.2     7 3.33e- 2
```

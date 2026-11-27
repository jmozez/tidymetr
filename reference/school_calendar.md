# Modified school calendars and student achievement

Standardised mean differences in achievement between schools on a
modified (year-round) calendar and schools on a traditional calendar.
The 56 effect sizes come from schools nested in 11 school districts, the
standard example for three-level meta-analysis.

## Usage

``` r
school_calendar
```

## Format

A tibble with 56 rows and 6 columns:

- district:

  School district identifier (level 3).

- school:

  School within district (level 2).

- study:

  Effect size identifier.

- year:

  Year of the study.

- yi:

  Standardised mean difference (positive values favour the modified
  calendar).

- vi:

  Sampling variance of `yi`.

## Source

Konstantopoulos, S. (2011). Fixed effects and variance components
estimation in three-level meta-analysis. *Research Synthesis Methods*,
2(1), 61-76. [doi:10.1002/jrsm.35](https://doi.org/10.1002/jrsm.35)

The effect sizes were collected by Cooper, H., Valentine, J. C.,
Charlton, K. and Melson, A. (2003). The effects of modified school
calendars on student achievement and on school and community attitudes.
*Review of Educational Research*, 73(1), 1-52.
[doi:10.3102/00346543073001001](https://doi.org/10.3102/00346543073001001)

Values cross-checked against `dat.konstantopoulos2011` in the 'metadat'
package.

## Examples

``` r
meta_multilevel(school_calendar, yi = yi, vi = vi,
  cluster = district, within = school)
#> # Multilevel meta-analysis <meta_fit>
#> # Model: REML with 2 random effect levels
#> # Measure: generic effect size; k = 56
#> # sigma^2 (district) = 0.0651
#> # sigma^2 (school) = 0.0327
#> # Q(55) = 578.86, p < 0.0001
#> # 95% prediction interval: [-0.4502, 0.8197]
#> # A tibble: 1 × 7
#>   term    estimate std.error statistic p.value conf.low conf.high
#>   <chr>      <dbl>     <dbl>     <dbl>   <dbl>    <dbl>     <dbl>
#> 1 overall    0.185    0.0846      2.18  0.0289   0.0190     0.350
```

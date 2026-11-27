# Interventions for smoking cessation (a treatment network)

Arm level results of 24 trials comparing four interventions for helping
people stop smoking: no contact, self-help, individual counselling and
group counselling. Two trials have three arms. A standard example for
network meta-analysis. Larger cessation counts are better, so use
`small_values = "bad"` in
[`meta_network()`](https://tidymetr.in4metrix.dev/reference/meta_network.md).

## Usage

``` r
smoking_cessation
```

## Format

A tibble with 50 rows (arms) and 7 columns:

- id:

  Arm identifier.

- study:

  Study identifier.

- authors:

  Study authors.

- year:

  Publication year.

- trt:

  Intervention: `"no_contact"`, `"self_help"`, `"ind_counseling"`
  (individual counselling) or `"grp_counseling"` (group counselling).

- xi:

  Number of people who stopped smoking.

- ni:

  Number of people in the arm.

## Source

Hasselblad, V. (1998). Meta-analysis of multitreatment studies. *Medical
Decision Making*, 18(1), 37-43.
[doi:10.1177/0272989X9801800110](https://doi.org/10.1177/0272989X9801800110)

Values cross-checked against `dat.hasselblad1998` in the 'metadat'
package.

## Examples

``` r
meta_pairwise(smoking_cessation, study = study, treatment = trt,
  measure = "OR", event = xi, n = ni)
#> # A meta_es: 28 rows x 10 columns
#> # Measure:   log odds ratio
#>    study treat1         treat2     event1 event2    n1    n2    .yi    .vi  .sei
#>    <int> <chr>          <chr>       <int>  <int> <int> <int>  <dbl>  <dbl> <dbl>
#>  1     1 no_contact     ind_couns…     75    363   731   714 -2.20  0.0205 0.143
#>  2     2 no_contact     ind_couns…      9     23   140   140 -1.05  0.171  0.413
#>  3     2 no_contact     grp_couns…      9     10   140   138 -0.129 0.227  0.476
#>  4     2 ind_counseling grp_couns…     23     10   140   138  0.923 0.160  0.400
#>  5     3 no_contact     ind_couns…      2      9   106   205 -0.870 0.626  0.791
#>  6     4 no_contact     ind_couns…     58    237   549  1561 -0.416 0.0243 0.156
#>  7     5 no_contact     ind_couns…      0      9    33    48 -2.78  2.16   1.47 
#>  8     6 self_help      ind_couns…     20     16    49    43  0.152 0.184  0.429
#>  9     7 no_contact     ind_couns…      3     31   100    98 -2.71  0.391  0.625
#> 10     8 no_contact     ind_couns…      1     26    31    95 -2.43  1.09   1.04 
#> # ℹ 18 more rows
```

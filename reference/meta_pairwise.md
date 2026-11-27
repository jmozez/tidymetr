# Arm level data to pairwise contrasts

`meta_pairwise()` turns arm level data (one row per treatment arm) into
contrast level data (one row per pair of arms within a study), computing
the effect size of `treat1` relative to `treat2` with
[`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md).
Studies with more than two arms contribute every pairwise contrast,
which is what
[`meta_network()`](https://tidymetr.in4metrix.dev/reference/meta_network.md)
expects.

## Usage

``` r
meta_pairwise(
  .data,
  study,
  treatment,
  measure = "OR",
  event = NULL,
  n = NULL,
  mean = NULL,
  sd = NULL,
  time = NULL,
  add = 0.5,
  to = c("only0", "all", "none")
)
```

## Arguments

- .data:

  A data frame with one row per study arm.

- study, treatment:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Columns identifying the study and the treatment of each arm.

- measure:

  An effect size measure for two groups: `"OR"`, `"RR"`, `"MD"`, `"SMD"`
  or `"IRR"`.

- event, n, mean, sd, time:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Arm level summaries: events and sample sizes for `"OR"` and `"RR"`;
  means, standard deviations and sample sizes for `"MD"` and `"SMD"`;
  events and person time for `"IRR"`.

- add, to:

  Zero cell correction, see
  [`meta_effect_size()`](https://tidymetr.in4metrix.dev/reference/meta_effect_size.md).

## Value

A [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
with columns `study`, `treat1`, `treat2`, the arm summaries suffixed
with `1` and `2`, and `.yi`, `.vi` and `.sei`.

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

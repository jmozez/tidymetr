# Compute study level effect sizes

`meta_effect_size()` adds an effect size (`.yi`), its sampling variance
(`.vi`) and standard error (`.sei`) to every row of a data frame and
returns a
[`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
tibble that the rest of the package understands.

## Usage

``` r
meta_effect_size(
  .data,
  measure = "SMD",
  ...,
  m1 = NULL,
  sd1 = NULL,
  n1 = NULL,
  m2 = NULL,
  sd2 = NULL,
  n2 = NULL,
  event1 = NULL,
  event2 = NULL,
  time1 = NULL,
  time2 = NULL,
  r = NULL,
  n = NULL,
  event = NULL,
  yi = NULL,
  vi = NULL,
  sei = NULL,
  study = NULL,
  add = 0.5,
  to = c("only0", "all", "none")
)
```

## Arguments

- .data:

  A data frame or tibble with one row per study (or per effect size).

- measure:

  The effect size metric. See the Measures section.

- ...:

  These dots are for future extensions and must be empty.

- m1, sd1, n1, m2, sd2, n2:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Means, standard deviations and sample sizes of groups 1 and 2. `n1`
  and `n2` are also the group sizes for `"RR"` and `"OR"`.

- event1, event2:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Number of events in groups 1 and 2.

- time1, time2:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Person time at risk in groups 1 and 2.

- r, n:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Correlation coefficients and sample sizes (`n` is also the total for
  `"PLO"`).

- event:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Number of events for `"PLO"`.

- yi, vi, sei:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  Precomputed effect sizes with their variances or standard errors for
  `"GEN"`.

- study:

  \<[`tidy-select`](https://dplyr.tidyverse.org/reference/dplyr_tidy_select.html)\>
  Optional column holding study labels, used in plots and tables.

- add:

  Value added to cells for zero cell corrections.

- to:

  Which studies receive the correction: `"only0"`, `"all"` or `"none"`.

## Value

A [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md)
tibble: `.data` plus the columns `.yi`, `.vi` and `.sei`.

## Measures

- `"SMD"`:

  Standardised mean difference with Hedges' exact small sample
  correction (Hedges' g). Needs `m1`, `sd1`, `n1`, `m2`, `sd2`, `n2`.
  The variance is \\1/n_1 + 1/n_2 + g^2 / (2(n_1 + n_2))\\.

- `"MD"`:

  Raw mean difference, with variance \\sd_1^2/n_1 + sd_2^2/n_2\\. Needs
  the same columns as `"SMD"`.

- `"RR"`:

  Log risk ratio. Needs `event1`, `n1`, `event2`, `n2`.

- `"OR"`:

  Log odds ratio. Needs `event1`, `n1`, `event2`, `n2`.

- `"IRR"`:

  Log incidence rate ratio. Needs `event1`, `time1`, `event2`, `time2`
  (person time).

- `"ZCOR"`:

  Fisher's z transformed correlation, with variance \\1/(n - 3)\\. Needs
  `r` and `n`.

- `"PLO"`:

  Logit transformed proportion. Needs `event` and `n`.

- `"GEN"`:

  Generic, precomputed effect sizes. Needs `yi` and either `vi` or
  `sei`.

Group 1 is the treatment or exposed group and group 2 the comparison
group, so positive values favour group 1 having the larger mean, risk,
odds or rate. The aliases `"g"`, `"logRR"`, `"logOR"`, `"logIRR"`,
`"fisher_z"` and `"logit"` are also accepted.

For the count based measures (`"RR"`, `"OR"`, `"IRR"`, `"PLO"`) the
value of `add` is added to the cells of studies with a zero cell when
`to = "only0"` (the default), to every study when `to = "all"`, or never
when `to = "none"`.

## References

Hedges, L. V. (1981). Distribution theory for Glass's estimator of
effect size and related estimators. *Journal of Educational Statistics*,
6(2), 107-128.
[doi:10.3102/10769986006002107](https://doi.org/10.3102/10769986006002107)

Borenstein, M., Hedges, L. V., Higgins, J. P. T. and Rothstein, H. R.
(2009). *Introduction to Meta-Analysis*. Wiley.

## Examples

``` r
# Log risk ratios for the BCG vaccine trials
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg,
  event2 = cpos, n2 = cpos + cneg,
  study = author
)
bcg
#> # A meta_es: 13 rows x 12 columns
#> # Measure:   log risk ratio
#>    trial author  year  tpos  tneg  cpos  cneg ablat alloc     .yi     .vi   .sei
#>    <int> <chr>  <int> <int> <int> <int> <int> <int> <chr>   <dbl>   <dbl>  <dbl>
#>  1     1 Arons…  1948     4   119    11   128    44 rand… -0.889  0.326   0.571 
#>  2     2 Fergu…  1949     6   300    29   274    55 rand… -1.59   0.195   0.441 
#>  3     3 Rosen…  1960     3   228    11   209    42 rand… -1.35   0.415   0.644 
#>  4     4 Hart …  1977    62 13536   248 12619    52 rand… -1.44   0.0200  0.141 
#>  5     5 Frimo…  1973    33  5036    47  5761    13 alte… -0.218  0.0512  0.226 
#>  6     6 Stein…  1953   180  1361   372  1079    44 alte… -0.786  0.00691 0.0831
#>  7     7 Vandi…  1973     8  2537    10   619    19 rand… -1.62   0.223   0.472 
#>  8     8 TPT M…  1980   505 87886   499 87892    13 rand…  0.0120 0.00396 0.0629
#>  9     9 Coetz…  1968    29  7470    45  7232    27 rand… -0.469  0.0564  0.238 
#> 10    10 Rosen…  1961    17  1699    65  1600    42 syst… -1.37   0.0730  0.270 
#> 11    11 Comst…  1974   186 50448   141 27197    18 syst… -0.339  0.0124  0.111 
#> 12    12 Comst…  1969     5  2493     3  2338    33 syst…  0.446  0.533   0.730 
#> 13    13 Comst…  1976    27 16886    29 17825    33 syst… -0.0173 0.0714  0.267 

# Hedges' g for length of hospital stay
meta_effect_size(stroke_los, "SMD",
  m1 = m1, sd1 = sd1, n1 = n1, m2 = m2, sd2 = sd2, n2 = n2
)
#> # A meta_es: 9 rows x 11 columns
#> # Measure:   standardised mean difference (Hedges' g)
#>   study source              n1    m1   sd1    n2    m2   sd2    .yi    .vi  .sei
#>   <int> <chr>            <int> <dbl> <dbl> <int> <dbl> <dbl>  <dbl>  <dbl> <dbl>
#> 1     1 Edinburgh          155    55    47   156    75    64 -0.355 0.0131 0.114
#> 2     2 Orpington-Mild      31    27     7    32    29     4 -0.348 0.0645 0.254
#> 3     3 Orpington-Moder…    75    64    17    71   119    29 -2.32  0.0458 0.214
#> 4     4 Orpington-Severe    18    66    20    18   137    48 -1.89  0.161  0.401
#> 5     5 Montreal-Home        8    14     8    13    18    11 -0.384 0.205  0.453
#> 6     6 Montreal-Transf…    57    19     7    52    18     4  0.172 0.0369 0.192
#> 7     7 Newcastle           34    52    45    33    41    34  0.272 0.0603 0.245
#> 8     8 Umea               110    21    16   183    31    27 -0.425 0.0149 0.122
#> 9     9 Uppsala             60    30    27    52    23    20  0.290 0.0363 0.190

# Fisher's z for correlations
meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni)
#> # A meta_es: 16 rows x 13 columns
#> # Measure:   Fisher's z transformed correlation
#>    authors         year    ni     ri controls design a_measure c_measure meanage
#>    <chr>          <int> <int>  <dbl> <chr>    <chr>  <chr>     <chr>       <dbl>
#>  1 Axelsson et a…  2009   109  0.187 none     cross… self-rep… other        22  
#>  2 Axelsson et a…  2011   749  0.162 none     cross… self-rep… NEO          53.6
#>  3 Bruce et al.    2010    55  0.34  none     prosp… other     NEO          43.4
#>  4 Christensen e…  1999   107  0.32  none     cross… self-rep… other        41.7
#>  5 Christensen &…  1995    72  0.27  none     prosp… other     NEO          46.4
#>  6 Cohen et al.    2004    65  0     none     prosp… other     NEO          41.2
#>  7 Dobbels et al.  2005   174  0.175 none     cross… self-rep… NEO          52.3
#>  8 Ediger et al.   2007   326  0.05  multiple prosp… self-rep… NEO          41  
#>  9 Insel et al.    2006    58  0.26  none     prosp… other     other        77  
#> 10 Jerant et al.   2011   771  0.01  multiple prosp… other     NEO          78.6
#> 11 Moran et al.    1997    56 -0.09  multiple prosp… other     NEO          57.2
#> 12 O'Cleirigh et…  2007    91  0.37  none     prosp… self-rep… NEO          37.9
#> 13 Penedo et al.   2003   116  0     none     cross… self-rep… NEO          39.2
#> 14 Quine et al.    2012   537  0.15  none     prosp… self-rep… other        69  
#> 15 Stilley et al.  2004   158  0.24  none     prosp… other     NEO          46.2
#> 16 Wiebe & Chris…  1997    65  0.04  none     prosp… other     NEO          56  
#> # ℹ 4 more variables: quality <int>, .yi <dbl>, .vi <dbl>, .sei <dbl>
```

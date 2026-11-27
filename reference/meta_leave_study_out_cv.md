# Leave-one-study-out cross-validation

`meta_leave_study_out_cv()` creates an `rsample` resampling object in
which each study in turn forms the assessment set and the remaining
studies form the analysis set. Every effect size from the same study is
held out together, which avoids leakage when studies report several
correlated effect sizes. It is the natural way to estimate how well a
meta-regression predicts the result of a new study.

## Usage

``` r
meta_leave_study_out_cv(.data, study)
```

## Arguments

- .data:

  A data frame, usually a
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md).

- study:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  The study identifier.

## Value

An `rset` tibble of class `meta_leave_study_out_cv` with columns
`splits` and `id` (the study label).

## Examples

``` r
bcg <- meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg
)
folds <- meta_leave_study_out_cv(bcg, study = author)
folds
#> #  Leave-one-study-out cross-validation
#> # A tibble: 11 × 2
#>    splits         id                  
#>    <list>         <chr>               
#>  1 <split [12/1]> Aronson             
#>  2 <split [12/1]> Ferguson & Simes    
#>  3 <split [11/2]> Rosenthal et al     
#>  4 <split [12/1]> Hart & Sutherland   
#>  5 <split [12/1]> Frimodt-Moller et al
#>  6 <split [12/1]> Stein & Aronson     
#>  7 <split [12/1]> Vandiviere et al    
#>  8 <split [12/1]> TPT Madras          
#>  9 <split [12/1]> Coetzee & Berjak    
#> 10 <split [11/2]> Comstock et al      
#> 11 <split [12/1]> Comstock & Webster  
rsample::assessment(folds$splits[[1]])
#> # A meta_es: 1 rows x 12 columns
#> # Measure:   log risk ratio
#>   trial author   year  tpos  tneg  cpos  cneg ablat alloc     .yi   .vi  .sei
#>   <int> <chr>   <int> <int> <int> <int> <int> <int> <chr>   <dbl> <dbl> <dbl>
#> 1     1 Aronson  1948     4   119    11   128    44 random -0.889 0.326 0.571
```

# Cluster cross-validation for meta-analytic data

`meta_cluster_cv()` splits clusters (for example research groups,
laboratories, countries or species) into `v` folds so that all effect
sizes from a cluster are in the same fold. Folds are balanced by the
number of effect sizes: clusters are shuffled and then assigned, largest
first, to the fold that currently holds the fewest rows.

## Usage

``` r
meta_cluster_cv(.data, cluster, v = 5, repeats = 1)
```

## Arguments

- .data:

  A data frame, usually a
  [`<meta_es>`](https://tidymetr.in4metrix.dev/reference/new_meta_es.md).

- cluster:

  \<[`data-masking`](https://rlang.r-lib.org/reference/args_data_masking.html)\>
  The cluster identifier.

- v:

  The number of folds. Must not exceed the number of clusters.

- repeats:

  The number of times to repeat the partitioning.

## Value

An `rset` tibble of class `meta_cluster_cv` with columns `splits` and
`id` (and `id2` when `repeats > 1`).

## Examples

``` r
set.seed(1)
folds <- meta_cluster_cv(school_calendar, cluster = district, v = 4)
folds
#> #  4-fold cluster cross-validation
#> # A tibble: 4 × 2
#>   splits          id   
#>   <list>          <chr>
#> 1 <split [42/14]> Fold1
#> 2 <split [41/15]> Fold2
#> 3 <split [42/14]> Fold3
#> 4 <split [43/13]> Fold4
```

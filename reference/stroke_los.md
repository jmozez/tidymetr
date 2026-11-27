# Specialist stroke care and length of hospital stay

Mean length of hospital stay (days) for patients who received specialist
stroke unit care (group 1) or conventional care (group 2) in nine
trials. A standard example for standardised mean differences.

## Usage

``` r
stroke_los
```

## Format

A tibble with 9 rows and 8 columns:

- study:

  Study number.

- source:

  Trial site and patient group.

- n1, m1, sd1:

  Sample size, mean and standard deviation of length of stay with
  specialist care.

- n2, m2, sd2:

  Sample size, mean and standard deviation of length of stay with
  conventional care.

## Source

Normand, S.-L. T. (1999). Meta-analysis: formulating, evaluating,
combining, and reporting. *Statistics in Medicine*, 18(3), 321-359.
[doi:10.1002/(SICI)1097-0258(19990215)18:3\<321::AID-SIM28\>3.0.CO;2-P](https://doi.org/10.1002/%28SICI%291097-0258%2819990215%2918%3A3%3C321%3A%3AAID-SIM28%3E3.0.CO%3B2-P)

Values cross-checked against `dat.normand1999` in the 'metadat' package.

## Examples

``` r
meta_effect_size(stroke_los, "SMD",
  m1 = m1, sd1 = sd1, n1 = n1, m2 = m2, sd2 = sd2, n2 = n2)
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
```

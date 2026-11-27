# BCG vaccine trials for preventing tuberculosis

Results of 13 controlled trials of the Bacillus Calmette-Guerin (BCG)
vaccine against tuberculosis, the classic example for random-effects
meta-analysis and meta-regression. The protective effect of the vaccine
is known to grow with distance from the equator (`ablat`).

## Usage

``` r
bcg_trials
```

## Format

A tibble with 13 rows and 9 columns:

- trial:

  Trial number.

- author:

  First author(s).

- year:

  Publication year.

- tpos, tneg:

  Vaccinated participants who did and did not develop tuberculosis.

- cpos, cneg:

  Unvaccinated participants who did and did not develop tuberculosis.

- ablat:

  Absolute latitude of the trial site (degrees).

- alloc:

  Method of treatment allocation: `"random"`, `"alternate"` or
  `"systematic"`.

## Source

Colditz, G. A., Brewer, T. F., Berkey, C. S., Wilson, M. E., Burdick,
E., Fineberg, H. V. and Mosteller, F. (1994). Efficacy of BCG vaccine in
the prevention of tuberculosis: meta-analysis of the published
literature. *JAMA*, 271(9), 698-702.
[doi:10.1001/jama.1994.03510330076038](https://doi.org/10.1001/jama.1994.03510330076038)

Berkey, C. S., Hoaglin, D. C., Mosteller, F. and Colditz, G. A. (1995).
A random-effects regression model for meta-analysis. *Statistics in
Medicine*, 14(4), 395-411.
[doi:10.1002/sim.4780140406](https://doi.org/10.1002/sim.4780140406)

Values cross-checked against `dat.bcg` in the 'metadat' package.

## Examples

``` r
bcg_trials
#> # A tibble: 13 × 9
#>    trial author                year  tpos  tneg  cpos  cneg ablat alloc     
#>    <int> <chr>                <int> <int> <int> <int> <int> <int> <chr>     
#>  1     1 Aronson               1948     4   119    11   128    44 random    
#>  2     2 Ferguson & Simes      1949     6   300    29   274    55 random    
#>  3     3 Rosenthal et al       1960     3   228    11   209    42 random    
#>  4     4 Hart & Sutherland     1977    62 13536   248 12619    52 random    
#>  5     5 Frimodt-Moller et al  1973    33  5036    47  5761    13 alternate 
#>  6     6 Stein & Aronson       1953   180  1361   372  1079    44 alternate 
#>  7     7 Vandiviere et al      1973     8  2537    10   619    19 random    
#>  8     8 TPT Madras            1980   505 87886   499 87892    13 random    
#>  9     9 Coetzee & Berjak      1968    29  7470    45  7232    27 random    
#> 10    10 Rosenthal et al       1961    17  1699    65  1600    42 systematic
#> 11    11 Comstock et al        1974   186 50448   141 27197    18 systematic
#> 12    12 Comstock & Webster    1969     5  2493     3  2338    33 systematic
#> 13    13 Comstock et al        1976    27 16886    29 17825    33 systematic
meta_effect_size(bcg_trials, "RR",
  event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg)
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
```

#' BCG vaccine trials for preventing tuberculosis
#'
#' Results of 13 controlled trials of the Bacillus Calmette-Guerin (BCG)
#' vaccine against tuberculosis, the classic example for random-effects
#' meta-analysis and meta-regression. The protective effect of the vaccine
#' is known to grow with distance from the equator (`ablat`).
#'
#' @format A tibble with 13 rows and 9 columns:
#' \describe{
#'   \item{trial}{Trial number.}
#'   \item{author}{First author(s).}
#'   \item{year}{Publication year.}
#'   \item{tpos, tneg}{Vaccinated participants who did and did not develop
#'     tuberculosis.}
#'   \item{cpos, cneg}{Unvaccinated participants who did and did not
#'     develop tuberculosis.}
#'   \item{ablat}{Absolute latitude of the trial site (degrees).}
#'   \item{alloc}{Method of treatment allocation: `"random"`,
#'     `"alternate"` or `"systematic"`.}
#' }
#' @source
#' Colditz, G. A., Brewer, T. F., Berkey, C. S., Wilson, M. E., Burdick,
#' E., Fineberg, H. V. and Mosteller, F. (1994). Efficacy of BCG vaccine in
#' the prevention of tuberculosis: meta-analysis of the published
#' literature. *JAMA*, 271(9), 698-702.
#' \doi{10.1001/jama.1994.03510330076038}
#'
#' Berkey, C. S., Hoaglin, D. C., Mosteller, F. and Colditz, G. A. (1995).
#' A random-effects regression model for meta-analysis. *Statistics in
#' Medicine*, 14(4), 395-411. \doi{10.1002/sim.4780140406}
#'
#' Values cross-checked against `dat.bcg` in the 'metadat' package.
#' @examples
#' bcg_trials
#' meta_effect_size(bcg_trials, "RR",
#'   event1 = tpos, n1 = tpos + tneg, event2 = cpos, n2 = cpos + cneg)
"bcg_trials"

#' Specialist stroke care and length of hospital stay
#'
#' Mean length of hospital stay (days) for patients who received
#' specialist stroke unit care (group 1) or conventional care (group 2) in
#' nine trials. A standard example for standardised mean differences.
#'
#' @format A tibble with 9 rows and 8 columns:
#' \describe{
#'   \item{study}{Study number.}
#'   \item{source}{Trial site and patient group.}
#'   \item{n1, m1, sd1}{Sample size, mean and standard deviation of length
#'     of stay with specialist care.}
#'   \item{n2, m2, sd2}{Sample size, mean and standard deviation of length
#'     of stay with conventional care.}
#' }
#' @source
#' Normand, S.-L. T. (1999). Meta-analysis: formulating, evaluating,
#' combining, and reporting. *Statistics in Medicine*, 18(3), 321-359.
#' \doi{10.1002/(SICI)1097-0258(19990215)18:3<321::AID-SIM28>3.0.CO;2-P}
#'
#' Values cross-checked against `dat.normand1999` in the 'metadat'
#' package.
#' @examples
#' meta_effect_size(stroke_los, "SMD",
#'   m1 = m1, sd1 = sd1, n1 = n1, m2 = m2, sd2 = sd2, n2 = n2)
"stroke_los"

#' Conscientiousness and medication adherence
#'
#' Correlations between conscientiousness (a personality trait) and
#' adherence to medication in 16 studies.
#'
#' @format A tibble with 16 rows and 10 columns:
#' \describe{
#'   \item{authors}{Study authors.}
#'   \item{year}{Publication year.}
#'   \item{ni}{Sample size.}
#'   \item{ri}{Observed correlation.}
#'   \item{controls}{Number of variables controlled for (`"none"` or
#'     `"multiple"`).}
#'   \item{design}{`"cross-sectional"` or `"prospective"`.}
#'   \item{a_measure}{Adherence measure: `"self-report"` or `"other"`.}
#'   \item{c_measure}{Conscientiousness measure: `"NEO"` or `"other"`.}
#'   \item{meanage}{Mean age of the participants (years).}
#'   \item{quality}{Methodological quality score (1 to 4).}
#' }
#' @source
#' Molloy, G. J., O'Carroll, R. E. and Ferguson, E. (2014).
#' Conscientiousness and medication adherence: a meta-analysis. *Annals of
#' Behavioral Medicine*, 47(1), 92-101. \doi{10.1007/s12160-013-9524-4}
#'
#' Values cross-checked against `dat.molloy2014` in the 'metadat' package.
#' @examples
#' meta_effect_size(adherence_cor, "ZCOR", r = ri, n = ni) |> meta_pool()
"adherence_cor"

#' Modified school calendars and student achievement
#'
#' Standardised mean differences in achievement between schools on a
#' modified (year-round) calendar and schools on a traditional calendar.
#' The 56 effect sizes come from schools nested in 11 school districts, the
#' standard example for three-level meta-analysis.
#'
#' @format A tibble with 56 rows and 6 columns:
#' \describe{
#'   \item{district}{School district identifier (level 3).}
#'   \item{school}{School within district (level 2).}
#'   \item{study}{Effect size identifier.}
#'   \item{year}{Year of the study.}
#'   \item{yi}{Standardised mean difference (positive values favour the
#'     modified calendar).}
#'   \item{vi}{Sampling variance of `yi`.}
#' }
#' @source
#' Konstantopoulos, S. (2011). Fixed effects and variance components
#' estimation in three-level meta-analysis. *Research Synthesis Methods*,
#' 2(1), 61-76. \doi{10.1002/jrsm.35}
#'
#' The effect sizes were collected by Cooper, H., Valentine, J. C.,
#' Charlton, K. and Melson, A. (2003). The effects of modified school
#' calendars on student achievement and on school and community attitudes.
#' *Review of Educational Research*, 73(1), 1-52.
#' \doi{10.3102/00346543073001001}
#'
#' Values cross-checked against `dat.konstantopoulos2011` in the
#' 'metadat' package.
#' @examples
#' meta_multilevel(school_calendar, yi = yi, vi = vi,
#'   cluster = district, within = school)
"school_calendar"

#' Interventions for smoking cessation (a treatment network)
#'
#' Arm level results of 24 trials comparing four interventions for helping
#' people stop smoking: no contact, self-help, individual counselling and
#' group counselling. Two trials have three arms. A standard example for
#' network meta-analysis. Larger cessation counts are better, so use
#' `small_values = "bad"` in [meta_network()].
#'
#' @format A tibble with 50 rows (arms) and 7 columns:
#' \describe{
#'   \item{id}{Arm identifier.}
#'   \item{study}{Study identifier.}
#'   \item{authors}{Study authors.}
#'   \item{year}{Publication year.}
#'   \item{trt}{Intervention: `"no_contact"`, `"self_help"`,
#'     `"ind_counseling"` (individual counselling) or `"grp_counseling"`
#'     (group counselling).}
#'   \item{xi}{Number of people who stopped smoking.}
#'   \item{ni}{Number of people in the arm.}
#' }
#' @source
#' Hasselblad, V. (1998). Meta-analysis of multitreatment studies.
#' *Medical Decision Making*, 18(1), 37-43.
#' \doi{10.1177/0272989X9801800110}
#'
#' Values cross-checked against `dat.hasselblad1998` in the 'metadat'
#' package.
#' @examples
#' meta_pairwise(smoking_cessation, study = study, treatment = trt,
#'   measure = "OR", event = xi, n = ni)
"smoking_cessation"

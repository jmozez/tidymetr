# Builds the datasets shipped in data/. Run from the package root with
#   Rscript data-raw/make_data.R
#
# Every dataset is a published meta-analytic dataset, transcribed from the
# original publication. The values were cross-checked against the copies
# curated in the 'metadat' package (dat.bcg, dat.normand1999,
# dat.molloy2014, dat.konstantopoulos2011 and dat.hasselblad1998). Each
# source is cited in R/data.R.

library(tibble)

# BCG vaccine trials ----------------------------------------------------------
# Colditz et al. (1994), JAMA 271(9), 698-702; absolute latitude from
# Berkey et al. (1995), Statistics in Medicine 14(4), 395-411.
bcg_trials <- tibble(
  trial = 1:13,
  author = c(
    "Aronson", "Ferguson & Simes", "Rosenthal et al", "Hart & Sutherland",
    "Frimodt-Moller et al", "Stein & Aronson", "Vandiviere et al",
    "TPT Madras", "Coetzee & Berjak", "Rosenthal et al", "Comstock et al",
    "Comstock & Webster", "Comstock et al"
  ),
  year = c(1948L, 1949L, 1960L, 1977L, 1973L, 1953L, 1973L, 1980L, 1968L,
           1961L, 1974L, 1969L, 1976L),
  tpos = c(4L, 6L, 3L, 62L, 33L, 180L, 8L, 505L, 29L, 17L, 186L, 5L, 27L),
  tneg = c(119L, 300L, 228L, 13536L, 5036L, 1361L, 2537L, 87886L, 7470L,
           1699L, 50448L, 2493L, 16886L),
  cpos = c(11L, 29L, 11L, 248L, 47L, 372L, 10L, 499L, 45L, 65L, 141L, 3L,
           29L),
  cneg = c(128L, 274L, 209L, 12619L, 5761L, 1079L, 619L, 87892L, 7232L,
           1600L, 27197L, 2338L, 17825L),
  ablat = c(44L, 55L, 42L, 52L, 13L, 44L, 19L, 13L, 27L, 42L, 18L, 33L,
            33L),
  alloc = c("random", "random", "random", "random", "alternate",
            "alternate", "random", "random", "random", "systematic",
            "systematic", "systematic", "systematic")
)

# Specialist stroke care and length of stay -----------------------------------
# Normand (1999), Statistics in Medicine 18(3), 321-359, Table I.
# Group 1: specialist stroke care; group 2: conventional care.
stroke_los <- tibble(
  study = 1:9,
  source = c("Edinburgh", "Orpington-Mild", "Orpington-Moderate",
             "Orpington-Severe", "Montreal-Home", "Montreal-Transfer",
             "Newcastle", "Umea", "Uppsala"),
  n1 = c(155L, 31L, 75L, 18L, 8L, 57L, 34L, 110L, 60L),
  m1 = c(55, 27, 64, 66, 14, 19, 52, 21, 30),
  sd1 = c(47, 7, 17, 20, 8, 7, 45, 16, 27),
  n2 = c(156L, 32L, 71L, 18L, 13L, 52L, 33L, 183L, 52L),
  m2 = c(75, 29, 119, 137, 18, 18, 41, 31, 23),
  sd2 = c(64, 4, 29, 48, 11, 4, 34, 27, 20)
)

# Conscientiousness and medication adherence ----------------------------------
# Molloy, O'Carroll and Ferguson (2014), Annals of Behavioral Medicine
# 47(1), 92-101.
adherence_cor <- tibble(
  authors = c("Axelsson et al.", "Axelsson et al.", "Bruce et al.",
              "Christensen et al.", "Christensen & Smith", "Cohen et al.",
              "Dobbels et al.", "Ediger et al.", "Insel et al.",
              "Jerant et al.", "Moran et al.", "O'Cleirigh et al.",
              "Penedo et al.", "Quine et al.", "Stilley et al.",
              "Wiebe & Christensen"),
  year = c(2009L, 2011L, 2010L, 1999L, 1995L, 2004L, 2005L, 2007L, 2006L,
           2011L, 1997L, 2007L, 2003L, 2012L, 2004L, 1997L),
  ni = c(109L, 749L, 55L, 107L, 72L, 65L, 174L, 326L, 58L, 771L, 56L, 91L,
         116L, 537L, 158L, 65L),
  ri = c(0.187, 0.162, 0.340, 0.320, 0.270, 0.000, 0.175, 0.050, 0.260,
         0.010, -0.090, 0.370, 0.000, 0.150, 0.240, 0.040),
  controls = c("none", "none", "none", "none", "none", "none", "none",
               "multiple", "none", "multiple", "multiple", "none", "none",
               "none", "none", "none"),
  design = c("cross-sectional", "cross-sectional", "prospective",
             "cross-sectional", "prospective", "prospective",
             "cross-sectional", "prospective", "prospective", "prospective",
             "prospective", "prospective", "cross-sectional", "prospective",
             "prospective", "prospective"),
  a_measure = c("self-report", "self-report", "other", "self-report",
                "other", "other", "self-report", "self-report", "other",
                "other", "other", "self-report", "self-report",
                "self-report", "other", "other"),
  c_measure = c("other", "NEO", "NEO", "other", "NEO", "NEO", "NEO", "NEO",
                "other", "NEO", "NEO", "NEO", "NEO", "other", "NEO", "NEO"),
  meanage = c(22.00, 53.59, 43.36, 41.70, 46.39, 41.20, 52.30, 41.00, 77.00,
              78.60, 57.20, 37.90, 39.20, 69.00, 46.20, 56.00),
  quality = c(1L, 1L, 2L, 1L, 2L, 2L, 1L, 3L, 2L, 3L, 2L, 2L, 1L, 2L, 3L,
              1L)
)

# Modified school calendars (three-level data) --------------------------------
# Konstantopoulos (2011), Research Synthesis Methods 2(1), 61-76, using the
# studies collected by Cooper, Valentine, Charlton and Melson (2003).
school_calendar <- tibble(
  district = c(11L, 11L, 11L, 11L, 12L, 12L, 12L, 12L, 18L, 18L, 18L, 27L,
               27L, 27L, 27L, 56L, 56L, 56L, 56L, 58L, 58L, 58L, 58L, 58L,
               58L, 58L, 58L, 58L, 58L, 58L, 71L, 71L, 71L, 86L, 86L, 86L,
               86L, 86L, 86L, 86L, 86L, 91L, 91L, 91L, 91L, 91L, 91L, 108L,
               108L, 108L, 108L, 108L, 644L, 644L, 644L, 644L),
  school = c(1L, 2L, 3L, 4L, 1L, 2L, 3L, 4L, 1L, 2L, 3L, 1L, 2L, 3L, 4L, 1L,
             2L, 3L, 4L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 1L,
             2L, 3L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 1L, 2L, 3L, 4L, 5L, 6L,
             1L, 2L, 3L, 4L, 5L, 1L, 2L, 3L, 4L),
  study = 1:56,
  year = c(1976L, 1976L, 1976L, 1976L, 1989L, 1989L, 1989L, 1989L, 1994L,
           1994L, 1994L, 1976L, 1976L, 1976L, 1976L, 1997L, 1997L, 1997L,
           1997L, 1976L, 1976L, 1976L, 1976L, 1976L, 1976L, 1976L, 1976L,
           1976L, 1976L, 1976L, 1997L, 1997L, 1997L, 1997L, 1997L, 1997L,
           1997L, 1997L, 1997L, 1997L, 1997L, 2000L, 2000L, 2000L, 2000L,
           2000L, 2000L, 2000L, 2000L, 2000L, 2000L, 2000L, 1995L, 1995L,
           1994L, 1994L),
  yi = c(-0.18, -0.22, 0.23, -0.30, 0.13, -0.26, 0.19, 0.32, 0.45, 0.38,
         0.29, 0.16, 0.65, 0.36, 0.60, 0.08, 0.04, 0.19, -0.06, -0.18, 0.00,
         0.00, -0.28, -0.04, -0.30, 0.07, 0.00, 0.05, -0.08, -0.09, 0.30,
         0.98, 1.19, -0.07, -0.05, -0.01, 0.02, -0.03, 0.00, 0.01, -0.10,
         0.50, 0.66, 0.20, 0.00, 0.05, 0.07, -0.52, 0.70, -0.03, 0.27,
         -0.34, 0.12, 0.61, 0.04, -0.05),
  vi = c(0.118, 0.118, 0.144, 0.144, 0.014, 0.014, 0.015, 0.024, 0.023,
         0.043, 0.012, 0.020, 0.004, 0.004, 0.007, 0.019, 0.007, 0.005,
         0.004, 0.020, 0.018, 0.019, 0.022, 0.020, 0.021, 0.006, 0.007,
         0.007, 0.007, 0.007, 0.015, 0.011, 0.010, 0.001, 0.001, 0.001,
         0.001, 0.001, 0.001, 0.001, 0.001, 0.010, 0.011, 0.010, 0.009,
         0.013, 0.013, 0.031, 0.031, 0.030, 0.030, 0.030, 0.087, 0.082,
         0.067, 0.067)
)

# Smoking cessation network ---------------------------------------------------
# Hasselblad (1998), Medical Decision Making 18(1), 37-43. One row per arm;
# xi is the number of people who stopped smoking out of ni.
smoking_cessation <- tibble(
  id = 1:50,
  study = c(1L, 1L, 2L, 2L, 2L, 3L, 3L, 4L, 4L, 5L, 5L, 6L, 6L, 7L, 7L,
            8L, 8L, 9L, 9L, 9L, 10L, 10L, 11L, 11L, 12L, 12L, 13L, 13L,
            14L, 14L, 15L, 15L, 16L, 16L, 17L, 17L, 18L, 18L, 19L, 19L,
            20L, 20L, 21L, 21L, 22L, 22L, 23L, 23L, 24L, 24L),
  authors = rep(c(
    "Reid et al.", "Cottraux et al.", "Slama et al.", "Jamrozik et al.",
    "Rabkin et al.", "Decker and Evans", "Richmond et al.", "Leung",
    "Mothersill et al.", "Langford et al.", "Gritz et al.",
    "Campbell et al.", "Sanders et al.", "Hilleman et al.",
    "Gillams et al.", "Mogielnicki et al.", "Page et al.",
    "Vetter and Ford", "Williams and Hall", "Pallonen et al.",
    "Russell et al.", "Stewart and Rosser", "Russell et al.",
    "Kendrick et al."
  ), times = c(2, 3, 2, 2, 2, 2, 2, 2, 3, rep(2, 15))),
  year = rep(c(1974L, 1983L, 1990L, 1984L, 1984L, 1989L, 1986L, 1991L,
               1988L, 1983L, 1992L, 1986L, 1989L, 1993L, 1984L, 1986L,
               1986L, 1990L, 1988L, 1994L, 1983L, 1982L, 1979L, 1995L),
             times = c(2, 3, 2, 2, 2, 2, 2, 2, 3, rep(2, 15))),
  trt = c(
    "no_contact", "ind_counseling", "no_contact", "ind_counseling",
    "grp_counseling", "no_contact", "ind_counseling", "no_contact",
    "ind_counseling", "no_contact", "ind_counseling", "self_help",
    "ind_counseling", "no_contact", "ind_counseling", "no_contact",
    "ind_counseling", "self_help", "ind_counseling", "grp_counseling",
    "no_contact", "ind_counseling", "no_contact", "self_help",
    "no_contact", "self_help", "no_contact", "ind_counseling",
    "ind_counseling", "grp_counseling", "ind_counseling", "grp_counseling",
    "self_help", "grp_counseling", "no_contact", "ind_counseling",
    "no_contact", "ind_counseling", "no_contact", "grp_counseling",
    "no_contact", "self_help", "no_contact", "ind_counseling",
    "no_contact", "ind_counseling", "no_contact", "ind_counseling",
    "no_contact", "ind_counseling"
  ),
  xi = c(75L, 363L, 9L, 23L, 10L, 2L, 9L, 58L, 237L, 0L, 9L, 20L, 16L, 3L,
         31L, 1L, 26L, 11L, 12L, 29L, 6L, 17L, 79L, 77L, 18L, 21L, 64L,
         107L, 12L, 20L, 9L, 3L, 7L, 32L, 5L, 8L, 20L, 34L, 0L, 9L, 8L,
         19L, 95L, 143L, 15L, 36L, 78L, 73L, 69L, 54L),
  ni = c(731L, 714L, 140L, 140L, 138L, 106L, 205L, 549L, 1561L, 33L, 48L,
         49L, 43L, 100L, 98L, 31L, 95L, 78L, 85L, 170L, 39L, 77L, 702L,
         694L, 671L, 535L, 642L, 761L, 76L, 74L, 55L, 26L, 66L, 127L, 62L,
         90L, 234L, 237L, 20L, 20L, 116L, 149L, 1107L, 1031L, 187L, 504L,
         584L, 675L, 1177L, 888L)
)

dir.create("data", showWarnings = FALSE)
save(bcg_trials, file = "data/bcg_trials.rda", compress = "xz")
save(stroke_los, file = "data/stroke_los.rda", compress = "xz")
save(adherence_cor, file = "data/adherence_cor.rda", compress = "xz")
save(school_calendar, file = "data/school_calendar.rda", compress = "xz")
save(smoking_cessation, file = "data/smoking_cessation.rda",
     compress = "xz")

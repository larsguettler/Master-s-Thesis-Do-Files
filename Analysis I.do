
*** ----------------------------------------------------------------------------------------***




************** MASTER'S THESIS DO-FILE - ALI STYLE ANALYSIS ***************




*** ---------------------------------------------------------------------------------------- ***





******* 	SECTION 1 - Initial Commands, Setting Up Directory, and Loading Data 	*******
clear all
set more off

global path "C:/Users/Lars/Dropbox/Master's Thesis"
use "$path/in/SLMP_geodataset_long.dta", clear


*** Scaling NDVI ***
gen ndvi_help = ln(((ndvi*0.0001)+1))
replace ndvi= ndvi_help

*** Dropping observations in 2017 due to the strange behaviour of the data ***

drop if year>2016

** Setting the dataset as panel data and sorting out the time variable so they comply with STATA's format **
ssc install numdate
format %9.0f yearandmonth 
numdate monthly yrmo = yearandmonth, pattern(YM)
xtset id yrmo

*******		SECTION 2 - Generating variables needed for the analysis 		******
**  Generating a variable stating the mean NDVI for each pixel, and generating a variable stating//
// 	the observations relation to the mean (the NDVI anomaly)  **
bysort month id: egen ndvi_mean_help=mean(ndvi) if year<2009
bysort month id: egen ndvi_mean=max(ndvi_mean_help)
gen ndvi_an = ndvi-ndvi_mean

** Generating a variable describing the number of years a pixel has been treated at the time of observation **

gen treatmentyear = year-critws_implemstart
replace treatmentyear=0 if treatmentyear==.
replace treatmentyear=0 if treatmentyear<1

label variable treatmentyear "1 year of treatment"
** Grouping those variables into groups: 1 for the first year, and 3 subsequent groupings **
gen treat1year=1 if treatmentyear==1
replace treat1year=0 if treat1year==.

gen treat2years=1 if treatmentyear==2
replace treat2years=0 if treat2years==.

gen treat3years=1 if treatmentyear==3
replace treat3years=0 if treat3years==.

gen treat4years=1 if treatmentyear==4
replace treat4years=0 if treat4years==.

gen treat5years=1 if treatmentyear==5
replace treat5years=0 if treat5years==.

gen treat6years=1 if treatmentyear==6
replace treat6years=0 if treat6years==.

gen treat7years=1 if treatmentyear==7
replace treat7years=0 if treat7years==.

gen treat8years=1 if treatmentyear==8
replace treat8years=0 if treat8years==.


label variable treat1year "1 year"
label variable treat2years "2 years"
label variable treat3years "3 years"
label variable treat4years "4 years"
label variable treat5years "5 years"
label variable treat6years "6 years"
label variable treat7years "7 years"
label variable treat8years "8 years"

*******		SECTION 3 - Running the regressions and outputting tables 		******

****			Table 1			 *****
** regressing on the effect of an individual year **

xtreg ndvi_an treatmentyear i.year i.month, re

reg ndvi_an treatmentyear i.year i.month, r
outreg2 using "$path/out/ALItreatmentyears.doc",  $outopt label nonotes addnote("Note: Year and month dummy variables are included in the regression to account for yearly variations and seasonality. Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.")title("The effect of a year of treatment on NDVI anomalies") ctitle(NDVI Anomaly) keep(treatmentyear) replace


****			Table 2			 *****
** regressing on the effect of being in a specific group **
reg ndvi_an treat1year i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label nonotes addnote("Note: Year and month dummy variables are included in all regressions to account for yearly variations and seasonality. Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") keep(treat1year) title("The effect of the SLMP on NDVI anomalies disaggregated on specific number of years in treatment") ctitle(NDVI Anomaly) replace
reg ndvi_an treat2years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat2years)
reg ndvi_an treat3years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat3years)
reg ndvi_an treat4years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat4years)
reg ndvi_an treat5years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat5years)
reg ndvi_an treat6years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat6years)
reg ndvi_an treat7years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat7years)
reg ndvi_an treat8years i.year i.month, r
outreg2 using "$path/out/ALItreatyeargroups.doc",  $outopt label keep(treat8years)


** Manual inspection of the number of observations in each treatgroup so I can add it manually to the table later **
tab treatmentyear


*******		SECTION 4 - Testing the equal trends assumption 		******

****			Table 3			 *****

gen TREAT=1 if critws_id>0 
replace TREAT=0 if critws_id==.
label variable TREAT "Pixel in SLMP area"
xtreg ndvi_an year if year<2009 & TREAT==1, fe
outreg2 using "$path/out/ALIequaltrendsassumption.doc",  $outopt label nonotes addnote("Note: Year and month dummy variables are included in the regression to account for yearly variations and seasonality. Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("Test for Parallel Trends Assumption: Average Yearly Change in NDVI 2000-2008") ctitle ("Treatment Areas") keep(year) replace
xtreg ndvi_an year if year<2009 & TREAT==0, fe
outreg2 using "$path/out/ALIequaltrendsassumption.doc",  $outopt label ctitle ("Treatment Areas") keep(year)

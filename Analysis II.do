
*** ----------------------------------------------------------------------------------------***




**************         MASTER'S THESIS DO-FILE - Nygård Style Analysis           ***************




*** ---------------------------------------------------------------------------------------- ***





******* 	SECTION 1 - Initial Commands, Setting Up Directory, and Loading Data 	******* 
clear all
set more off

global path "C:/Users/Lars/Dropbox/Master's Thesis"
use "$path/in/SLMP_geodataset_long.dta", clear

*** Taking the Log of NDVI to make the anomalies in percentages***
gen ndvi_help = ln(((ndvi*0.0001)+1))
replace ndvi= ndvi_help

***TEMPORARILY DROPPING THE YEAR 2017 ***

drop if year>2016

 
******* 	SECTION 2 - Generating variables needed for the Predicted Greenness Anomalies estimation 	******* 

** Setting the dataset as panel data and sorting out the time variable so they comply with STATA's format **
ssc install numdate
format %9.0f yearandmonth 
numdate monthly yrmo = yearandmonth, pattern(YM)
xtset id yrmo


** Generating monthly means of the greenness and weather variables **

bysort month id: egen ndvi_mean_help=mean(ndvi) if year<2009
bysort month id: egen ndvi_mean=max(ndvi_mean_help)
bysort month id: egen lst_day_mean_help=mean(lst_day) if year<2009
bysort month id: egen lst_day_mean=max(lst_day_mean_help)
bysort month id: egen lst_night_mean_help=mean(lst_night) if year<2009
bysort month id: egen lst_night_mean=max(lst_night_mean_help)
bysort month id: egen chirps_mean_help=mean(chirps) if year<2009
bysort month id: egen chirps_mean=max(chirps_mean_help)
** sort back **
sort id yrmo

** Generating anomaly variables  for greenness and weather variables **

gen ndvi_an = ndvi-ndvi_mean
gen chirps_an = chirps-chirps_mean
gen lst_day_an = lst_day-lst_day_mean
gen lst_night_an = lst_night-lst_night_mean

** Generating a variable indicating if a pixel is TREAT or not **
gen TREAT=1 if critws_id>0 
replace TREAT=0 if critws_id==.

** Generating lagged weather anomaly variables **

sort id yrmo

foreach y in 1 2 3 4 5 6 {
gen chirps_an_lag`y' = l`y'.chirps_an
}

foreach y in 1 2 3 4 5 6 {
gen lst_day_an_lag`y' = l`y'.lst_day_an
}

foreach y in 1 2 3 4 5 6 {
gen lst_night_an_lag`y' = l`y'.lst_night_an
}

** Generating month-weather anomaly interaction terms (to account for that the effect of the lagged anomaly//
// may vary across seasons) **
gen chirps_an_m = month#c.chirps_an
foreach y in 1 2 3 4 5 6 {
gen chirps_an_m_lag`y' = month#c.chirps_an_lag`y'
}

gen lst_day_an_m = month#c.lst_day_an
foreach y in 1 2 3 4 5 6 {
gen lst_day_an_m_lag`y' = month#c.lst_day_an_lag`y'
}

gen lst_night_an_m = month#c.lst_night_an
foreach y in 1 2 3 4 5 6 {
gen lst_night_an_m_lag`y' = month#c.lst_night_an_lag`y'
}


** Label variables (Not entirely sure why I do this, but Nygård does it so I follow) **

global chirps_an chirps_an chirps_an_lag1 chirps_an_lag2 chirps_an_lag3 chirps_an_lag4 chirps_an_lag5 chirps_an_lag6
global chirps_an_m chirps_an_m chirps_an_m_lag1 chirps_an_m_lag2 chirps_an_m_lag3 chirps_an_m_lag4 chirps_an_m_lag5 chirps_an_m_lag6
 
global lst_day_an lst_day_an lst_day_an_lag1 lst_day_an_lag2 lst_day_an_lag3 lst_day_an_lag4 lst_day_an_lag5 lst_day_an_lag6 
global lst_day_an_m lst_day_an_m lst_day_an_m_lag1 lst_day_an_m_lag2 lst_day_an_m_lag3 lst_day_an_m_lag4 lst_day_an_m_lag5 lst_day_an_m_lag6 

global lst_night_an lst_night_an lst_night_an_lag1 lst_night_an_lag2 lst_night_an_lag3 lst_night_an_lag4 lst_night_an_lag5 lst_night_an_lag6
global lst_night_an_m lst_night_an_m lst_night_an_m_lag1 lst_night_an_m_lag2 lst_night_an_m_lag3 lst_night_an_m_lag4 lst_night_an_m_lag5 lst_night_an_m_lag6



******* 	SECTION 3 - Running the PGA estimation		******* 

****			Table 4			 *****

** Regressing anomalies with year-dummies for treatment and control separately ** 
eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if TREAT==1
outreg2 using "$path/out/NYGAARDpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label nonotes addnote("Note: 'chirps' is the level of precipitation, 'lst_day' the day time temperature, and 'lst_night' the nighttime temperature. Year dummy variables are included in the regression to account for yearly variations, and monthly interaction terms are included in the regression to account for how the effect might vary with seasonality.  Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("Predicted Greenness Anomalies Model") ctitle(SLMP Areas) replace
predict ndvi_treat_an
 

eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if TREAT==0
outreg2 using "$path/out/NYGAARDpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label ctitle(Control Areas)
predict ndvi_control_an

gen ndvi_hat_an=ndvi_treat_an if TREAT==1
replace ndvi_hat_an=ndvi_control_an if TREAT==0


******* 	SECTION 3 - Testing for whether treatment areas outperformed their prediction more than control areas		******* 


** Generating a variable describing the number of years a pixel has been treated at the time of observation ****

gen treatmentyear = year-critws_implemstart 
replace treatmentyear=0 if treatmentyear==.
replace treatmentyear=0 if treatmentyear<1
label variable treatmentyear "1 year of treatment"
** Generating differences between observed NDVI anomalies and predicted NDVI Anomalies **

gen diff_an = ndvi_an - ndvi_hat_an

** Testing for an effect of the program in the mid-late growing season of the drought years of 2015 and 2016 **

****			Table 5			 *****
reg diff_an treatmentyear if yearandmonth==201508, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label nonotes addnote("Note: Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("The effect of the SLMP on the difference between observed and predicted greenness anomalies in the mid-late growing period of 2015") ctitle(August) replace
reg diff_an treatmentyear if yearandmonth==201509, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label ctitle(September)
reg diff_an treatmentyear if yearandmonth==201510, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label ctitle(October)


****			Table 6			 *****
reg diff_an treatmentyear if yearandmonth==201608, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label ctitle(August)
reg diff_an treatmentyear if yearandmonth==201609, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label ctitle(September)
reg diff_an treatmentyear if yearandmonth==201610, r
outreg2 using "$path/out/NYGAARD20152016treateffect.doc", label ctitle(October)


reg diff_an treatmentyear if ndvi_hat_an<0, r

** Testing whether treatment areas performed better than control areas before treatment implementation **

**** (LEFT OUT OF THE DOCUMENT, BUT WOULD LIKE TO DISCUSS HOW TO TEST FOR THE EQUAL TRENDS ASSUMPTION HERE AS WELL ****

gen TREAT=1 if critws_id>0 
replace TREAT=0 if critws_id==.
label variable TREAT "Pixel in SLMP area"
reg diff_an TREAT if treatmentyear==0 & year>2008, r
outreg2 using "$path/out/ALIequaltrendsassumption.doc",  $outopt label nonotes addnote("Note: Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("Test for the equal trends assumption: the effect of being in an SLMP area before program implementation on the difference between predicted and observed NDVI anomalies") ctitle ("Difference from prediction") replace

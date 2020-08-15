
*** ----------------------------------------------------------------------------------------***




**************         MASTER'S THESIS DO-FILE - Güettler Style Analysis         ***************




*** ---------------------------------------------------------------------------------------- ***


******* 	  SECTION 1 - Initial Commands, Setting Up Directory, and Loading Data 			*******   
clear all
set more off

global path "C:/Users/Lars/Dropbox/Master's Thesis"
use "$path/in/SLMP_geodataset_long.dta", clear


***TEMPORARILY DROPPING YEAR 2017 as it looks really strange (very very strange) compared to the rest ***
drop if year>2016


*** Taking the Log of NDVI to turn the anomalies into percentages***
gen ndvi_help = ln(((ndvi*0.0001)+1))
replace ndvi= ndvi_help

 
******* 	SECTION 2 - Generating variables needed for the Predicted Greenness Anomalies estimations 	*******

** Setting the dataset as panel data and sorting out the time variable so they comply with STATA's format **
ssc install numdate
format %9.0f yearandmonth 
numdate monthly yrmo = yearandmonth, pattern(YM)
xtset id yrmo

** Generating a variable indicating whether a pixel generally is control or treatment **

gen TREAT=1 if critws_id>0 
replace TREAT=0 if critws_id==.
label variable TREAT "Pixel is in SLMP area"
** Generating a variable that indicates whether the observation is before the initiation of the program or not **

gen posttreat=1 if year>2008
replace posttreat=0 if year<2009

** Generating a category variable with a number for each group and period **

gen group=1 if TREAT==1 & posttreat==0
replace group=2 if TREAT==1 & posttreat==1
replace group=3 if TREAT==0 & posttreat==0
replace group=4 if TREAT==0 & posttreat==1

** Generating monthly means of the greenness and weather variables **

bysort month id: egen ndvi_mean_1=mean(ndvi) if group==1
bysort month id: egen lst_day_mean_1=mean(lst_day) if group==1
bysort month id: egen lst_night_mean_1=mean(lst_night) if group==1
bysort month id: egen chirps_mean_1=mean(chirps) if group ==1

bysort month id: egen ndvi_mean_2=mean(ndvi) if group==2
bysort month id: egen lst_day_mean_2=mean(lst_day) if group==2
bysort month id: egen lst_night_mean_2=mean(lst_night) if group==2
bysort month id: egen chirps_mean_2=mean(chirps) if group==2

bysort month id: egen ndvi_mean_3=mean(ndvi) if group==3
bysort month id: egen lst_day_mean_3=mean(lst_day) if group==3
bysort month id: egen lst_night_mean_3=mean(lst_night) if group==3
bysort month id: egen chirps_mean_3=mean(chirps) if group==3

bysort month id: egen ndvi_mean_4=mean(ndvi) if group==4
bysort month id: egen lst_day_mean_4=mean(lst_day) if group==4
bysort month id: egen lst_night_mean_4=mean(lst_night) if group==4
bysort month id: egen chirps_mean_4=mean(chirps) if group==4

gen ndvi_mean=ndvi_mean_1 if group==1
replace ndvi_mean=ndvi_mean_2 if group==2
replace ndvi_mean=ndvi_mean_3 if group==3
replace ndvi_mean=ndvi_mean_4 if group==4

gen lst_day_mean=lst_day_mean_1 if group==1
replace lst_day_mean=lst_day_mean_2 if group==2
replace lst_day_mean=lst_day_mean_3 if group==3
replace lst_day_mean=lst_day_mean_4 if group==4

gen lst_night_mean=lst_night_mean_1 if group==1
replace lst_night_mean=lst_night_mean_2 if group==2
replace lst_night_mean=lst_night_mean_3 if group==3
replace lst_night_mean=lst_night_mean_4 if group==4

gen chirps_mean=chirps_mean_1 if group==1
replace chirps_mean=chirps_mean_2 if group==2
replace chirps_mean=chirps_mean_3 if group==3
replace chirps_mean=chirps_mean_4 if group==4


** sort back **
sort id yearandmonth

** Generating anomaly variables  for greenness and weather variables **

gen ndvi_an = ndvi-ndvi_mean
gen chirps_an = chirps-chirps_mean
gen lst_day_an = lst_day-lst_day_mean
gen lst_night_an = lst_night-lst_night_mean

** Generating lagged anomaly variables **
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

/* generate monthly dummies */
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



******* 	SECTION 3 - Estimating PGA coefficients and predicted values for treatment and control in both periods 	*******

****			Table 7			 *****

eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if group==1 & ndvi_an<0
outreg2 using "$path/out/GUETTLERpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label nonotes addnote("Note: 'chirps' is the level of precipitation, 'lst_day' the day time temperature, and 'lst_night' the nighttime temperature. Year dummy variables are included in the regression to account for yearly variations, and monthly interaction terms are included in the regression to account for how the effect might vary with seasonality.  Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("Predicted Greenness Anomalies Model for SLMP and control areas in the periods before and in the years of the SLMP") ctitle(SLMP Areas 2000-2008)replace
predict ndvi_pretreat_treat_an

eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if group==2 & ndvi_an<0
outreg2 using "$path/out/GUETTLERpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label ctitle(SLMP Areas 2009-2017)
predict ndvi_posttreat_treat_an

eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if group==3 & ndvi_an<0
outreg2 using "$path/out/GUETTLERpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label ctitle(Control Areas 2000-2008)
predict ndvi_pretreat_control_an

eststo: reg ndvi_an $chirps_an $lst_day_an $lst_night_an $chirps_an_m $lst_day_an_m $lst_night_an_m i.year if group==4 & ndvi_an<0
outreg2 using "$path/out/GUETTLERpgacoef.doc",  $outopt keep($chirps_an $lst_day_an $lst_night_an) label ctitle(Control Areas 2009-2017)
predict ndvi_posttreat_control_an



******* 	SECTION 4 - Generating the estimation variable indicating whether a pixel would have experienced 
/// 		a lesser or greater NDVI anomaly with the coefficients from the first period, and running the estimation		*******


gen estimate_estimate_diff=ndvi_posttreat_treat_an-(ndvi_pretreat_treat_an) if TREAT==1
replace estimate_estimate_diff=ndvi_posttreat_control_an-(ndvi_pretreat_control_an) if TREAT==0
label variable estimate_estimate_diff "Difference between 2000-2008 prediction and 2009-2017 prediction"

****			Table 8			 *****
reg estimate_estimate_diff TREAT if year>2008 & ndvi_an<0, r
outreg2 using "$path/out/GUETTLERfinaltreatmenttest.doc",  $outopt label nonotes addnote("Note:  Robust standard errors in parentheses. Significance levels: *** significant at 1%, ** significant at 5%, * significant at 10%.") title("The difference in the change of elasticities SLMP and control areas") replace

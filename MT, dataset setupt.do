
*** ----------------------------------------------------------------------------------------***




**************MASTER'S THESIS DO-FILE - SETTING UP THE DATASET***************




*** ---------------------------------------------------------------------------------------- ***





******* 	SECTION 1 - Initial Commands, Setting Up Directory, and Loading Data 	*******
clear all
set more off



******* 	SECTION 2 - Loading in the raster data and additional information form arcmap 	********


*** 		2.1 - loading, editing and saving the control raster data 	***

** First I do some edits to the supplementary data from arcmap that will merge with the rasterdata later, 
/// and save it as .dta file **
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\
import excel controlareasnames, firstrow
rename ADM3_EN controlworeda_name
rename Value controlareas
save controlareasnames.dta, replace


** Then, I load in the rasterdata for the control areas, and set the coordinates as desired **
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\RasterdataSLMP"
ras2dta, files(controlareas) idc(id) genxcoord(x) genycoord(y) replace clear
g lon = (x/7200)*360 - 180.025
g lat = (y*(-1)/3600)*180 + 90.025
drop if controlareas==.

** Finally, I merge the two datasets **
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\
merge m:1 controlareas using controlareasnames.dta
save controlareas.dta, replace 


*** 		2.2 loading, editing and saving the treatment raster data 	***

** Similar to with the control areas data, I do some edits to the supplementary data from arcmap that will merge with 
/// the rasterdata later, and save it as .dta file **
clear all
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\
import excel critwsnames, firstrow
rename cws_nm critws_name
rename Value critws
save critwsnames.dta, replace

** Actually, maybe this is the additional data, and the above is data tracing the names, from another step in the 
/// processing of the geodata. That is probably the case for the control areas as well **
clear all
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\
import excel critwsadditionaldata, firstrow
rename cws_nm critws_name
save critwsadditionaldata.dta, replace

** And then I load in the raster data with the accurate coordinates **
cd "C:\Users\Lars\Dropbox\Master's Thesis\in\RasterdataSLMP"
ras2dta, files(critws) idc(id) genxcoord(x) genycoord(y) replace clear
g lon = (x/7200)*360 - 180.025
g lat = (y*(-1)/3600)*180 + 90.025
drop if critws==.

** ... and finally I merge 
cd "C:\Users\Lars\Dropbox\Master's Thesis\in"
merge m:1 critws using critwsnames.dta, generate (_merge2)
merge m:1 critws_name using critwsadditionaldata.dta, generate (_merge3)
rename FIRST_W_Code critws_id


******* 	SECTION 3 - Merging the control data, treatment data, and greenness and weather data, and then 
///   		merging with GIZ-data about watersheds 		********

***			3.1 - Doing some manual edits to make the treatment and control data match up with GIZ-data 	***
** Deleting variables that don't match with the GIZ-data, changing some ID's so they match **

replace critws_id=40208 if critws_name=="Meki"
replace critws_id=30712 if critws_name=="Yezat"
replace critws_id=30709 if critws_name=="Kechem"
replace critws_id=40503 if critws_name=="Debis"
replace critws_id=60207 if critws_name=="Shari"
replace critws_id=60308 if critws_name=="Upper Yabus"
replace critws_id=60404 if critws_name=="Meti"
drop if id==.


save critws.dta, replace 


*** 		3.2 - Merging the control and treatment data using id 		***
merge 1:1 id using controlareas.dta, generate (_merge4)
drop if critws==. & controlareas==.
save treatmentcontrolmerge.dta, replace


*** 		3.3 - Loading in Ethiopia_Wide (Weather and Greenness data), deleting duplicates and merging with
///			the treatment and control data 		***
clear all
use Ethiopia_Wide.dta 
duplicates drop id, force

merge 1:1 id using treatmentcontrolmerge.dta, generate (_merge5)
drop if critws==. & controlareas==.

**Saving the new dataset**
save SLMP_geodataset.dta, replace

*** 		3.4 - Loading in the GIZ data, editing and merging with the geodataset  		***
use "MWS.dta", clear

** Here I do some manual edits to errors in the dataset regarding a key variable **
replace MWSimplemstart=. if MWSimplemstart==0
replace MWSimplemstart=. if MWSimplemstart==1
replace MWSimplemstart=. if MWSimplemstart==9999

** Here I generate a variable indicating when a watershed was first treated **
egen critws_implemstart = min(MWSimplemstart), by(CrWSid)

** and since I am only interested in one observation per critical watershed, I drop the rest **
bysort CrWSid: keep if _n==1

** ...and I also only keep variables that are of some interest to me (or may be for someone else **
keep CrWSid CrWSname CrWSphaseout project1 HHtotalCrWS AreaCrWSha PSNP AGP PASIDP DRDIP critws_implemstart MWSimplemstart CrWSid

** Then I do an edit to the critical watershed id's so they match the format in the geodataset, and save it **
gen critws_idx=CrWSid/100 
gen critws_id=round(critws_idx)
duplicates drop critws_id, force

save poppedataedited.dta, replace

** Now, I merge with the geodataset I set up previously, and drop variables I don't need. Finally, I save it **
use SLMP_geodataset.dta, clear
merge m:1 critws_id using poppedataedited.dta, generate (_merge6)
drop if _merge6==2

drop OBJECTID ADM2_CODE ADM1_CODE ADM0_CODE ADM0_NAME ADM2_NAME _merge2 Shape FIRST_Z_CODE ORIG_FID Shape_Length Shape_Area _merge3 _merge4 _merge _merge5 _merge6 critws_idx
rename CrWSname critws_name_GIZ_DATA
order critws_id critws_name controlworeda_name FIRST_R_NAME FIRST_W_NAME FIRST_donor_1 critws controlareas critws_implemstart CrWSphaseout Count, after(id)
order x y OBJECTID_12 FIRST_Z_NAME SUM_AreaMWSha SUM_HHMale SUM_HHFmale SUM_HHTotal critws_name_GIZ_DATA project1 HHtotalCrWS AreaCrWSha PSNP AGP PASIDP DRDIP, after(lon)

save SLMP_geodataset_wide.dta, replace

*** 		4 - Reshaping it Long, cleaning up the data a bit and saving the final dataset 			***
	
*** 		4.1 - generating a separate year and month variable 		***
reshape long ndvi chirps lst_day lst_night, i(id) j(yearandmonth)
gen year = yearandmonth/100
replace year = round(year)

gen month=real(substr(string(yearandmonth),5,6))

***			4.2 - Cropping the dataset to only include observations up until and including 2017
/// as the GIZ-data only stretches that far 	***
drop if year>2017

***			4.3. Saving the final data it in long version		 ***

save SLMP_geodataset_long.dta, replace





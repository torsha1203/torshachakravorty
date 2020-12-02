* objective - replicate tables and figures b1 & b2 from ch2 (abhilasha)
* created by - torsha chakravorty (25/08/2020)
* rewritten - 08/09/2020

* preliminaries 
clear all 
set more off 
if "`c(username)'" == "aadit" {
	global cloud = "C:/Users/`c(username)'/Dropbox"
	global path = "$cloud/research/alcohol"
	global overleaf = "$cloud/apps/overleaf/dar_sahay_prohibition"
	global remotedata "C:/Users/`c(username)'/Dropbox/copy/data/bihar_scrb/shyam_20171008"
}
else if "`c(username)'" == "torsh" {
	global path = "C:/Users/`c(username)'/Desktop/Indian School of Business/Aaditya Dar - prohibition"
} 
else {
	display as error "Please specify root directory" ///
	"Your username is: `c(username)'" /// 
	"Replace yourName with `c(username)'" 
	exit 
}

* global build path 
global binput "$path/build/input"
global bcode "$path/build/code"
global boutput "$path/build/output"
global btemp "$path/build/temp"
global bdropbox "$boutput/dropbox"

* global analysis path
global acode "$path/analysis/code"
global aoutput "$path/analysis/output"
global atemp "$path/analysis/temp"

* global results path
global ptab "$atemp/replication_tc/tables"

* stars
global estar3 star(* 0.10 ** 0.05 *** 0.01)
global estar4 star(+ 0.15 * 0.10 ** 0.05 *** 0.01)

* get data
use "$boutput/dropbox/dist_month_analysis_abhilasha.dta"

keep if scode == 10

label var post_i "Post"
label var std_drink "BanExposure"

label var crs_dsp "Dacoity"
label var crs_ksv "Kidnapping"
label var crs_rsp "Robbery"
label var crs_ipc_adj "All IPC (adj)"
label var crs_ipc "All IPC"
label var crs_tot "All Crimes"
label var crs_vaw "VAW"
label var dsi "Post*BanExposure"

e 
********************************************************************************************
************************** HEADLINE RESULT : MODEL RANGE QUARTER FE ************************
********************************************************************************************

* table 2.3 & 2.4 
set more off 
foreach var in ksv muv rav thp {
eststo crs_`var': quietly areg crs_`var' i.post_i##c.std_drink i.t i.prange#i.quarter if scode==10 , a(dcode) vce(cluster dcode)
sum crr_`var' if post_i==0 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp,  ///
keep (1.post_i#*std_drink) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") ///
title("Table 2.3 - Effect of Alcohol Ban on Crime")


********************************************************************************************
********************************* ROBUSTNESS CHECKS ****************************************
********************************************************************************************
* table 2.5
* Drop monsoon months july-october months, irrespective of year  
gen sand_mining_3=(month >=7 & month < 10)

set more off 
foreach var in ksv muv rav thp  {  
eststo crs_`var': quietly areg crs_`var' i.post_i##c.std_drink i.t i.prange#i.quarter if sand_mining_3!=1, a(dcode) vce(cluster dcode)
sum crr_`var' if post_i==0 & sand_mining_3!=1 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#*c.std_drink) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps 

* Floods 
* drop time period hit by the flood - aug-sep 2017
gen flood_2=(t >= tm(2017m08) & t < tm(2017m10))

set more off 
foreach var in ksv muv rav thp {  
eststo crs_`var': quietly areg crs_`var' i.post_i##c.std_drink i.t i.prange#i.quarter if flood_2!=1, a(dcode) vce(cluster dcode)
sum crr_`var' if post_i==0 & flood_2!=1 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#*c.std_drink) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps 

* Elections 
gen elec=(t > tm(2016m04) & t < tm(2016m11))

set more off 
foreach var in ksv muv rav thp  {  
eststo crs_`var': quietly areg crs_`var' i.post_i##c.std_drink i.t i.prange#i.quarter if elec!=1, a(dcode) vce(cluster dcode)
sum crr_`var' if post_i==0 & elec!=1 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#*c.std_drink) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps 

* Naxalite activity 
set more off 
foreach var in ksv muv rav thp  {  
eststo crs_`var': quietly areg crs_`var' i.post_i##c.std_drink i.t i.prange#i.quarter if naxal!=1, a(dcode) vce(cluster dcode)
sum crr_`var' if post_i==0 & naxal!=1 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#*c.std_drink) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps 


* robustness to measurement of ban-exposure
* table 2.6
* panel A - muslim dominated districts
set more off 
foreach c in ksv muv rav thp {  
eststo crs_`c': quietly  xtreg crs_`c' i.post_i##c.std_drink ///
i.t i.prange#i.quarter if !inlist(dcode, 211, 209, 210, 212), fe vce(cluster dcode)
sum crr_`c' if post_i==0 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#c.std_drink)  ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* alcohol density - no. of alcohol shops per capita 
* add alcohol shop variable - only matches for bihar districts from 2013m1-2018m3
merge 1:1 dcode t using "$bdropbox/dxm_alcohol_settlement.dta", ///
gen(m_alc_shop) keepusing(stl_*)		///all matched from master
drop if m_alc_shop == 2 

set more off 
foreach c in ksv muv rav thp {  
eststo crs_`c': quietly  xtreg crs_`c' i.post_i##c.stl_fl ///
i.t i.prange#i.quarter, fe vce(cluster dcode)
sum crr_`c' if post_i==0 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#c.stl_fl)  ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* table 2.7 
* distance to border (all merge)
rename dcode dcode_2011
merge m:1 dcode_2011 using "$boutput/dropbox/d_br_distance2border.dta"
rename NEAR_DIST dist_to_border

set more off 
foreach c in ksv muv rav thp {  
eststo crs_`c': quietly  xtreg crs_`c' i.post_i##c.std_drink i.t##c.dist_to_border i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0 //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (1.post_i#c.std_drink)  ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* table 2.8 
* Panel A
gen nov_mar=(t >= tm(2015m11) & t < tm(2016m4))
gen drink_nov_mar = std_drink*nov_mar
gen apr_sep=(t >= tm(2016m4) & t < tm(2016m10))
gen drink_apr_sep = std_drink*apr_sep //interact the dummy with std drink 
gen post_oct=(t >= tm(2016m10))
gen drink_post_oct = std_drink*post_oct //interact the dummy with std drink 

set more off 
foreach c in ksv muv rav thp {  
eststo crs_`c': quietly xtreg crs_`c' drink_apr_sep drink_post_oct i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode) 
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
} 

esttab crs_ksv crs_muv crs_rav crs_thp,  ///
keep (drink_apr_sep drink_post_oct)  ///
coefl(drink_apr_sep Ban_apr_sep drink_post_oct Ban_post_oct) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 

* Panel B
* enforcement data 
* arrest related to prohibition made by police (this file includes prohibition activity by excise dept)
merge 1:1 dcode t using "$boutput/dropbox/enforcement_tot.dta", ///
gen(m_pol) keepusing(ex_* pol_*)  ///data only from 2016m4 to 2018m3 - 912 observations

* replace non-missing values with zero 
recode ex_* (.=0)
recode pol_* (.=0)
sort dcode t

gen arrest_rate_1 = enf_pol_arrests/int_month_pop_t
gen arrest_rate_2 = pol_arrest_total/int_month_pop_t //total = drunk + others 
egen total_arrest = rowtotal(enf_pol_arrests)
gen arrest_rate_3 = total_arrest/int_month_pop_t

foreach i of num 1/3 {
egen std_arrest_rate_`i' = std(arrest_rate_`i')
}

* Prohibition arrest data is only valid for post period, 
* we can check whether, after the ban, regions that had higher enforcement activity faced higher crime - YES!
* Post period 
set more off 
foreach c in crs_ksv crs_muv crs_rav crs_thp {  
eststo `c': quietly xtreg `c' c.std_arrest_rate_3  ///
i.t i.prange#i.quarter if scode==10 & post_i==1 , fe vce(cluster dcode) 
} 

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (std_arrest_rate_3)  ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* table 2.9 - shadow econ effect 
* Evidence 1 Black Market Price -  No effect 
set more off 
foreach c in ksv muv rav thp {  
eststo crs_`c': quietly  xtreg crs_`c' c.dsi##c.above_med_avg_price_2016 i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi c.dsi#*c.above_med_avg_price_2016)  ///
coefl(dsi Post*BanExposure c.dsi#*c.above_med_avg_price_2016 BlackMarket) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 



* Evidence 2: border versus interior - no effect 
foreach c in ksv muv rav thp {
eststo crs_`c' : quietly xtreg crs_`c' c.dsi##i.all_border i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi 1.all_border#c.dsi)  ///
coefl(dsi BanExposure 1.all_border#c.dsi BorderDist) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* Evidence 3: nepal border 
foreach c in ksv muv rav thp {
eststo crs_`c' : quietly xtreg crs_`c' c.dsi##i.nepal_border i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi 1.nepal_border#c.dsi)  ///
coefl(dsi BanExposure 1.nepal_border#c.dsi BorderDist) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* table 2.11 - other mechanisms 
* gender norms + employment index (all matched)
merge m:1 dcode using "$boutput/archive/dxm/emp_colact.dta", gen(m_emp)

* panel A - negative income effect 
foreach c in ksv muv rav thp {
eststo crs_`c': quietly  xtreg crs_`c' c.dsi##c.emp_index i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}
 
esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi c.dsi#*c.emp_index)  ///
coefl(dsi Post*BanExposure c.dsi#*c.emp_index Employment) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* panel B - withdrawal symptopm effect (frequency of getting drunk)
foreach c in ksv muv rav thp {
eststo crs_`c': quietly  xtreg crs_`c' c.dsi##c.drink_often_wt i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi c.dsi#*c.drink_often_wt)  ///
coefl(dsi Post*BanExposure c.dsi#*c.drink_often_wt DrinkOften) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* panel C - women's decision making (reporting effect)
foreach c in ksv muv rav thp {
eststo crs_`c': quietly  xtreg crs_`c' c.dsi##c.dec_index i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi c.dsi#*c.dec_index)  ///
coefl(dsi Post*BanExposure c.dsi#*c.dec_index WomenDecision) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


* panel D - effect by collective action (reporting effect)
foreach c in ksv muv rav thp {
eststo crs_`c': quietly  xtreg crs_`c' c.dsi##c.colact_index i.t i.prange#i.quarter if scode==10, fe vce(cluster dcode)
sum crr_`c' if post_i==0  //pre-shock dep var mean 
estadd scalar Pre_Ban_Mean = r(mean)
}

esttab crs_ksv crs_muv crs_rav crs_thp, ///
keep (dsi c.dsi#*c.colact_index)  ///
coefl(dsi Post*BanExposure c.dsi#*c.colact_index CollectAction) ///
b(%9.3f) se(%9.3f) $estar3 ar2 compres  ///
scalars(Pre_Ban_Mean) sfmt(%9.2f) label fragment nogaps ///
mtitles ("kidnapping" "murder" "rape" "theft") 


/*
-------------------------------------------------------------------------------
objective					: make choropleth maps 
-------------------------------------------------------------------------------
user defined commands 		: ssc install spmap
ssc install shp2dta
-------------------------------------------------------------------------------
date created 				: 2018-04-19 by aaditya 
-------------------------------------------------------------------------------
date modified 				: 2020-05-05 by torsha
-------------------------------------------------------------------------------

*/

* preliminaries 
clear all 
set more off 
if "`c(username)'" == "dar" {
	global path = "C:/Users/dar/google_drive/alcohol/"
	global remotedata "C:/Users/dar/Dropbox/copy/data/bihar_scrb/shyam_20171008"
}
else if "`c(username)'" == "USER" {
	global path "C:/Users/USER/Indian School of Business\Aaditya Dar - prohibition"
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
global bmaps "$path/maps"

* global analysis path
global acode "$path/analysis/code"
global aoutput "$path/analysis/output"
global atemp "$path/analysis/temp"

global estar4 star(+ 0.15 * 0.10 ** 0.05 *** 0.01)
global estar3 star(* 0.10 ** 0.05 *** 0.01)
 
 
* get data
use "$boutput/dxm_2013m1_2018m3.dta", clear 
keep if stateut == "bihar"
 
duplicates report dcode t

* sanity check 
isid dcode t

* prep to merge
rename dcode censuscode

* set as panel data
xtset censuscode t

* merge
merge m:1 censuscode using "$bmaps/biharDist2011db", gen(m_geo)

* format variables 
format drink*wt %9.2gc

* standalone (drink*wt at baseline)
cap graph drop drink_pop_wt
spmap drink_pop_wt if t == tm(2016m4) ///
using "$path/maps/biharDist2011co.dta", ///
clmethod(quantile) clnumber(9) ///
id(geoid_dist) fc(YlGn) legend(position(5)) ///
label(x(x_cen) y(y_cen) label(district) size(vsmall)) ///
subtitle("Baseline % of drinking males") name("drink_pop_wt")

graph export "$path/maps/violent_map/drink.png", replace

* prep for second merge 
drop geoid-m_geo


* work on violent crime in general & VAW
collapse (sum) cr_violent cr_rape cr_kidnapping (mean) pop, by(censuscode district post_i)

* create var for crimes against women
egen cr_vaw = rowtotal(cr_rape cr_kidnapping) ///only women crimes

* set as panel data 
xtset censuscode post_i

* generate crime rates, differences b/w pre & post, and format data
foreach c in violent rape kidnapping vaw {
	gen crr_`c' = (cr_`c'/pop)*100000
	gen crr_`c'_diff = D.crr_`c'
	format crr_`c' crr_`c'_diff %9.2gc
}				
///38 missing values generated for each category

 

* merge 
merge m:1 censuscode using "$bmaps/biharDist2011db", gen(m_geo)

* make individual graphs & save to reqd folder
foreach c in violent rape kidnapping vaw {
	spmap crr_`c' if post_i == 0 using "$bmaps/biharDist2011co.dta", ///
		id(geoid_dist) fc(YlGn) legend(position(5)) label(x(x_cen) y(y_cen) label(district) size(vsmall)) ///
		subtitle("`c'_pre") name("`c'_pre")
	graph export "$path/maps/violent_map/`c'_pre.png", replace

	spmap crr_`c' if post_i == 1 using "$bmaps/biharDist2011co.dta", ///
		id(geoid_dist) fc(YlGn) legend(position(5)) label(x(x_cen) y(y_cen) ///
			label(district) size(vsmall)) subtitle("`c'_post") name("`c'_pst")
	graph export "$path/maps/violent_map/`c'_pst.png", replace

	spmap crr_`c'_diff if post_i == 1 using "$bmaps/biharDist2011co.dta", ///
		id(geoid_dist) fc(YlGn) legend(position(5)) label(x(x_cen) y(y_cen) ///
			label(district) size(vsmall)) subtitle("Change in `c' crime rates") name("vio_`c'_dff")
	graph export "$path/maps/violent_map/vio_`c'_dff.png", replace
}


* combine graphs created above
* rape & kidnapping
foreach c in rape kidnapping {
	graph combine drink_pop_wt `c'_pre `c'_pst vio_`c'_diff, ///
	title("`c'") name("gph_`c'")
	graph export "$path/maps/bihar_`c'.png"
}

* violence against women	
graph combine drink_pop_wt vaw_pre vaw_pst vio_vaw_dff, ///
title("Violence against Women : rape + kidnapping") name("gph_vaw")
graph export "$path/maps/bihar_vaw.png", ///
width(1600) height(1200) replace 


exit 

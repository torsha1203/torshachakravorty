
* objective : build choropleth maps for spatial analysis

* preliminaries 
clear all 
set rmsg on 
set more off 

* change as required
global path = "C:/Users/torsh/Desktop/Indian School of Business/Nikhitha Mathew - DISE_standardized"

* global build path 
global binput "$path/input"
global bcode "$path/code"
global bmaps "$path/maps"
global btemp "$path/temp"

e 

*----------------- need not be repeated --------------------------------
* install spmap and other commands
ssc install spmap
ssc install shp2dta

* convert shp 2 dta file
shp2dta using "$bmaps/Indian_States", database(india_stdb) coordinates(india_stcoord) genid(id)


* link id with 2011 state codes
use "$bmaps/india_stdb.dta"
rename st_nm state 
replace state = subinstr(strtrim(stritrim(lower(state))), " ", "", .)

* make necessary changes for merging 
replace state = "andaman" if regexm(state, "^andaman")  
replace state = "arunachalpradesh" if state == "arunanchalpradesh"
replace state = "chattisgarh" if state == "chhattisgarh"   
replace state = "dadarnagar" if regexm(state, "^dadara&")   
replace state = "daman" if state == "daman&diu"    
replace state = "delhi" if state == "nctofdelhi"
replace state = "himachal" if state == "himachalpradesh" 
replace state = "jammu" if regexm(state, "^jammu")
replace state = "puduchery" if state == "puducherry"    
replace state = "tn" if state == "tamilnadu"    

save, replace
exit   
*--------------------------------------------------------------------

* begin main part of creating choropleth maps 
* get main data
use "$btemp/enr_sxy_final.dta"

* merge coordinates 
merge m:1 state using "$bmaps/india_stdb.dta", gen(m_mapdb)

* telangana not merged
drop if m_mapdb != 3 

rename *, lower
split acyear, parse("-")
order acyear1, after(acyear)
rename acyear1 year
destring year, replace
drop acyear*

* format variables 
format prop_* %9.2gc 

* use spmap 
graph drop _all

foreach y in 2005 2007 2012 2016 {
	spmap prop_reserved_g using "$bmaps/india_stcoord.dta" ///
	if year == `y', id(id) legend(position(5)) ///
	fcolor(Blues) subtitle("`y'") name("resrvd_g_`y'")
	graph export "$bmaps/png files/prop_res_g_`y'.png", replace
}

graph combine resrvd_g_2005 resrvd_g_2007 resrvd_g_2012 resrvd_g_2016, ///
title("Proportion of girls within reserved category", span) ///
name(comb_reserved_g) iscale(0.5) scheme(economist)
graph export "$path/graphs/comb_reserved_g.png", replace  


*********************************************************************
* enrollment final maps - district 2001 boundaries
*********************************************************************

* get data 
use "D:\ISB_tc\Indian School of Business\Nikhitha Mathew - DISE_standardized\output\schxbxyxgender_enr_c1_gen - Copy.dta"

replace dname = subinstr(strtrim(stritrim(lower(dname))), " ", "", .)
* run dname do file relevant sections - 
do "D:\ISB_tc\Indian School of Business\Nikhitha Mathew - DISE_standardized\code\build_2011_dname.do"

merge m:1 dname using "D:\ISB_tc\Indian School of Business\Nikhitha Mathew - DISE_standardized\code\dcode-scode\map_d2011_d2001.dta", gen(m_dcode)
keep if m_dcode == 3

* merge in census sex ratio 
rename state scode_cen 
e 

* merge census district 
merge m:1 dcode_2011 using "D:\ISB_tc\Indian School of Business\Nikhitha Mathew - DISE_standardized\output\district_census_sexratio.dta", gen(m_pop)

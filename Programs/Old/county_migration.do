clear 
clear matrix
set more off

global raw "..\Datasets\SOI_County_Migration"
global data "..\Datasets"
global output "..\Output"
set graphics off

********************
*** Data Cleaning***
********************

// years refer to filing years, so 1516 is for income attributable to TYs 2014 and 2015 and for addresses in 2015 and 2016. Income data are for year 2. 
// y1 is origin

// Inflows

foreach y in "1112" "1213" "1314" "1415" "1516" "1617" "1718" "1819" "1920" "2021" {
	clear
	tempfile in`y'
	import delimited "$raw\county`y'\countyinflow`y'.csv"
	gen y="`y'"
	rename y2_statefips d_state
	rename y2_countyfips d_county
	rename y1_statefips o_state
	rename y1_countyfips o_county
	rename y1_state o_statename
	rename y1_countyname o_countyname
	rename n1 returns
	rename n2 exemptions
	save `in`y'', replace
}
foreach y in "0910" "1011" {
	clear
	tempfile in`y'
	import delimited "$raw\county`y'\countyinflow`y'.csv"
	gen y="`y'"
	rename state_code_dest d_state
	rename county_code_dest d_county
	rename state_code_origin o_state
	rename county_code_origin o_county
	rename state_abbrv o_statename
	rename county_name o_countyname
	rename return_num returns
	rename exmpt_num exemptions
	rename aggr_agi agi
	save `in`y'', replace
}

// Outflows

foreach y in "1112" "1213" "1314" "1415" "1516" "1617" "1718" "1819" "1920" "2021" {
	clear
	tempfile out`y'
	import delimited "$raw\county`y'\countyoutflow`y'.csv"
	gen y="`y'"
	rename y2_statefips d_state
	rename y2_countyfips d_county
	rename y1_statefips o_state
	rename y1_countyfips o_county
	rename y2_state d_statename
	rename y2_countyname d_countyname
	rename n1 returns
	rename n2 exemptions
	save `out`y'', replace
}
foreach y in "0910" "1011" {
	clear
	tempfile out`y'
	import delimited "$raw\county`y'\countyoutflow`y'.csv"
	gen y="`y'"
	rename state_code_dest d_state
	rename county_code_dest d_county
	rename state_code_origin o_state
	rename county_code_origin o_county
	rename state_abbrv d_statename
	rename county_name d_countyname
	rename return_num returns
	rename exmpt_num exemptions
	rename aggr_agi agi
	save `out`y'', replace
}

foreach t in "in" "out" {
	tempfile `t'
	use ``t'0910', clear
	foreach y in "1011" "1112" "1213" "1314" "1415" "1516" "1617" "1718" "1819" "1920" "2021" {
		append using ``t'`y''
	}
	gen `t'_count=returns
	gen `t'_meanagi=agi/returns
	save ``t'', replace
}

use `in', clear
keep if strpos(o_countyname,"US & For")|strpos(o_countyname,"US and Foreign")>0
gen year="20"+substr(y,3,2)
destring year, replace
keep d_state d_county in_count in_meanagi year
rename d_state statefips
rename d_county countyfips
save "$data\inflows.dta", replace

use `out', clear
keep if strpos(d_countyname,"US & For")|strpos(d_countyname,"US and Foreign")>0
gen year="20"+substr(y,3,2)
destring year, replace
keep o_state o_county out_count out_meanagi year
rename o_state statefips
rename o_county countyfips
save "$data\outflows.dta", replace

/*replace state="ALASKA" if state=="AK"
replace state="ALABAMA" if state=="AL"
replace state="ARKANSAS" if state=="AR"
replace state="ARIZONA" if state=="AZ"
replace state="CALIFORNIA" if state=="CA"
replace state="COLORADO" if state=="CO"
replace state="CONNECTICUT" if state=="CT"
replace state="DISTRICT OF COLUMBIA" if state=="DC"
replace state="DELAWARE" if state=="DE"
replace state="FLORIDA" if state=="FL"
replace state="GEORGIA" if state=="GA"
replace state="HAWAII" if state=="HI"
replace state="IOWA" if state=="IA"
replace state="IDAHO" if state=="ID"
replace state="ILLINOIS" if state=="IL"
replace state="INDIANA" if state=="IN"
replace state="KANSAS" if state=="KS"
replace state="KENTUCKY" if state=="KY"
replace state="LOUISIANA" if state=="LA"
replace state="MASSACHUSETTS" if state=="MA"
replace state="MARYLAND" if state=="MD"
replace state="MAINE" if state=="ME"
replace state="MICHIGAN" if state=="MI"
replace state="MINNESOTA" if state=="MN"
replace state="MISSOURI" if state=="MO"
replace state="MISSISSIPPI" if state=="MS"
replace state="MONTANA" if state=="MT"
replace state="NORTH CAROLINA" if state=="NC"
replace state="NORTH DAKOTA" if state=="ND"
replace state="NEBRASKA" if state=="NE"
replace state="NEW HAMPSHIRE" if state=="NH"
replace state="NEW JERSEY" if state=="NJ"
replace state="NEW MEXICO" if state=="NM"
replace state="NEVADA" if state=="NV"
replace state="NEW YORK" if state=="NY"
replace state="OHIO" if state=="OH"
replace state="OKLAHOMA" if state=="OK"
replace state="OREGON" if state=="OR"
replace state="PENNSYLVANIA" if state=="PA"
replace state="RHODE ISLAND" if state=="RI"
replace state="SOUTH CAROLINA" if state=="SC"
replace state="SOUTH DAKOTA" if state=="SD"
replace state="TENNESSEE" if state=="TN"
replace state="TEXAS" if state=="TX"
replace state="UTAH" if state=="UT"
replace state="VIRGINIA" if state=="VA"
replace state="VERMONT" if state=="VT"
replace state="WASHINGTON" if state=="WA"
replace state="WISCONSIN" if state=="WI"
replace state="WEST VIRGINIA" if state=="WV"
replace state="WYOMING" if state=="WY"*/



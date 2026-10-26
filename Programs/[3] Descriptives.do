clear 
clear matrix
set more off
set graphics off

global raw "..\Datasets\SOI_County_Income"
global us "..\Datasets\SOI_National_Income"
global data "..\Datasets"

global output "..\Output\withcapgain"
global set "\inequality"

// Shapefile for maps
use "$data\countyshapes.dta", clear
tempfile shapes
rename STATE_FIPS statefips
rename CNTY_FIPS countyfips
destring statefips countyfips, replace
save `shapes', replace

*** 1. Cutoff for top 20% Income - by county, 2020 
clear
import delimited "$data\Income_stat_byQuintile_byCounty.csv"
gen statefips=substr(geoid,8,2)
gen countyfips=substr(geoid,10,3)
destring statefips countyfips, replace
histogram fourth_ul, percent xtitle(80th Income Percentile by County ($) - 2020) xlabel(,format(%9.0gc) nogrid) ylabel(, nogrid) note("Data Source: U.S. Census") bins(100)
graph export "$output\fig8.png", replace
graph export "$output\fig8.pdf", replace

*** 2. Theil Histogram - by county, 2019

use "$data$set", clear
bysort id: gen n=_n
sum UStheil if year==2019
histogram Ctheil if year==2019 & n==1, percent xtitle(Theil T Index by County - 2019) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI, Theil for U.S. at Vertical Line") bins(100) xline(`r(mean)', lpattern(solid)) 
graph export "$output\fig9.png", replace
graph export "$output\fig9.pdf", replace

*** 3. US Theil Decomposition and Realized Gains - by year
gen income=returns*mean
collapse (sum) income (median) Ctheil UStheil STtheil USgini, by(statefips countyfips year)
bysort year: egen USincome=sum(income)
bysort state year: egen STincome=sum(income)
gen USincome_share=income/USincome
gen STincome_share=income/STincome

preserve
gen wt_ctheil=USincome_share*Ctheil
collapse (sum) wt_ctheil (median) UStheil USgini, by(year)
merge 1:1 year using "$data\capgains.dta", nogen
gen Between=(UStheil-wt_ctheil)/UStheil
gen Within=wt_ctheil/UStheil
twoway (line Within year, lpattern(dash) yaxis(1)) (line Between year, lpattern(dot) yaxis(1)) (line UStheil year, yaxis(2)), xtitle(Year) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") ytitle(Share of U.S. Inequality, axis(1)) ytitle(Theil Index, axis(2)) legend(label(1 "Within-County Inequality") label(2 "Between-County Inequality") label(3 "US Theil Index") col(3) pos(6))
graph export "$output\fig6.png", replace
graph export "$output\fig6.pdf", replace

replace capgain=capgain/1000000
twoway (line capgain year, lpattern(dash) yaxis(1)) (line UStheil year, yaxis(2)), xtitle(Year) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") ytitle(Realized Capital Gains (Millions), axis(1)) ytitle(Theil Index, axis(2)) legend(label(1 "Realized Capital Gains") label(2 "US Theil Index") col(2) pos(6))
graph export "$output\fig3.png", replace
graph export "$output\fig3.pdf", replace

twoway (line USgini year, lpattern(dash) yaxis(1)) (line UStheil year, yaxis(2)), xtitle(Year) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") ytitle(Gini Coefficient, axis(1)) ytitle(Theil Index, axis(2)) legend(label(1 "Realized Capital Gains") label(2 "US Theil Index") col(2) pos(6))
graph export "$output\fig2.png", replace
graph export "$output\fig2.pdf", replace
restore

*** 4. Maps - County Theil Contribution 2020, Theil 2020, Change Theil 2010-2020
gen ctheil_share=USincome_share*Ctheil/UStheil
egen id=group(statefips countyfips)
sort id year
tempfile change
save `change', replace
keep if inlist(year, 2010, 2019)
by id: gen D_Ctheil=Ctheil-Ctheil[_n-1]
keep if year==2019
merge 1:1 statefips countyfips using `shapes', keep(3)

drop if inlist( STATE_NAME, "Alaska", "Hawaii") // figure out what to do about AK and HI to make map look better
// County Theil Indices
spmap Ctheil using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues) 
graph export "$output\fig10.png", replace
graph export "$output\fig10.pdf", replace
preserve
sort Ctheil 
count
keep if _n<=20|_n>=`r(N)'-20
keep Ctheil NAME state
merge m:1 statefips using "$data\statenames.dta", nogen keep(3)
drop statefips
export excel using "$output\tab2.xlsx", sheetreplace firstrow(variables)
restore

// Change in County Theil Indices 2010-2019
spmap D_Ctheil using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues) 
graph export "$output\fig11.png", replace
graph export "$output\fig11.pdf", replace
preserve
drop if D_Ctheil==.
sort D_Ctheil 
count
keep if _n<=20|_n>=`r(N)'-20
merge 1:1 statefips countyfips using "$data\countynames.dta", nogen keep(3)
keep D_Ctheil NAME state 
export excel using "$output\tab3.xlsx", sheetreplace firstrow(variables)
restore
	
// County Contributions to National Inequality
spmap ctheil_share using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues) 
graph export "$output\fig7.png", replace
graph export "$output\fig7.pdf", replace
preserve
sort ctheil_share
count 
keep if _n<=20|_n>=`r(N)'-20
keep ctheil_share NAME state
merge m:1 statefips using "$data\statenames.dta", nogen keep(3)
drop statefips
sort ctheil_share
export excel using "$output\tab1.xlsx", sheetreplace firstrow(variables)
restore

*** 5. Changes in Inequality Over Time
use `change', clear
foreach v in "Ctheil" {
	sort id year
	xtset id year
	gen D_`v'=`v'-l.`v'
	gen D10`v'=`v'-l9.`v'
	bysort id: egen x=max(D10`v')
	replace D10`v'=x
	drop x
	drop if D10`v'==.
}
foreach v in "D10Ctheil" {
	bysort statefips: egen STmax=max(`v')
	bysort statefips: egen STmin=min(`v')
	egen USmax=max(`v')
	egen USmin=min(`v')
}
gen STmin_county=(D10Ctheil==STmin)
gen STmax_county=(D10Ctheil==STmax)
gen USmin_county=(D10Ctheil==USmin)
gen USmax_county=(D10Ctheil==USmax)

merge m:1 statefips countyfips using "$data\countynames.dta", nogen keep(3)
save "$data\changes.dta", replace

// Lists of 10 biggest increasing and decreasing states by inequality
preserve
collapse (median) STtheil UStheil, by(statefips year)
xtset statefips year
gen D10STtheil=STtheil-l9.STtheil
keep if year==2019
merge 1:1 statefips using "$data\statenames.dta", nogen
sort D10STtheil
count
keep if _n<=10|_n>=`r(N)'-10
keep D10STtheil state
export excel using "$output\tab4.xlsx", sheetreplace firstrow(variables)
restore

// Plot of Theils for US and Top State Changers
collapse (median) STtheil UStheil, by(statefips year)
xtset statefips year
gen D10STtheil=STtheil-l9.STtheil
bysort statefips: egen x=max(D10STtheil)
sort x year
count
keep if _n<=10|_n>=`r(N)'-9

preserve
tempfile min
keep if _n<=10
keep statefips year STtheil UStheil
merge m:1 statefips using "$data\statenames.dta", nogen keep(3)
rename STtheil min_STtheil
rename state min_state
keep year min_STtheil min_state UStheil
save `min', replace
restore

keep if _n>10
keep statefips year STtheil 
merge m:1 statefips using "$data\statenames.dta", nogen keep(3)
rename STtheil max_STtheil
rename state max_state
keep year max_STtheil max_state
merge 1:1 year using `min', nogen keep(3)
twoway (line min_STtheil year, lpattern(dash)) (line max_STtheil year, lpattern(dot)) (line UStheil year), xtitle(Year) note("Data Source: IRS SOI") ytitle(Theil Index) legend(label(1 "Biggest State Decline (WY)") label(2 "Biggest State Increase (FL)") label(3 "US Theil Index") col(3) pos(6)) xlabel(,nogrid) ylabel(, nogrid) // label states
graph export "$output\fig5.png", replace
graph export "$output\fig5.pdf", replace

// Plot of Theils for States and Top County Changers
use "$data\changes.dta", clear

preserve 
tempfile a
keep if STmin_county==1
keep statefips Ctheil year countyname
rename Ctheil min_Ctheil
rename countyname min_countyname
save `a', replace
restore

keep if STmax_county==1
keep statefips Ctheil STtheil year countyname
rename Ctheil max_Ctheil
rename countyname max_countyname
merge 1:1 statefips year using `a', nogen
merge m:1 statefips using "$data\statenames.dta", nogen keep(3) 

preserve
keep if statefips<21
sort statefips year
twoway (line max_Ctheil year, lpattern(dash)) (line STtheil year) (line min_Ctheil year, lpattern(dot)), by(state, note("Data Source: IRS SOI") legend(off) cols(2) yrescale) xtitle("") xlabel(,nogrid) ylabel(, nogrid) ytitle("") legend(label(1 "Within-County Inequality") label(2 "Between-County Inequality")) xsize(5) ysize(7)
graph export "$output\fig12a.png", replace
graph export "$output\fig12a.pdf", replace
restore

preserve
keep if statefips>=21 & statefips<37
sort statefips year
twoway (line max_Ctheil year, lpattern(dash)) (line STtheil year) (line min_Ctheil year, lpattern(dot)), by(state, note("Data Source: IRS SOI") legend(off) cols(2) yrescale) xtitle("") xlabel(,nogrid) ylabel(, nogrid) ytitle("") legend(label(1 "Within-County Inequality") label(2 "Between-County Inequality")) xsize(5) ysize(7)
graph export "$output\fig12b.png", replace
graph export "$output\fig12b.pdf", replace
restore

preserve
keep if statefips>=37
sort statefips year
twoway (line max_Ctheil year, lpattern(dash)) (line STtheil year) (line min_Ctheil year, lpattern(dot)), by(state, note("Data Source: IRS SOI") legend(off) cols(2) yrescale) xtitle("") xlabel(,nogrid) ylabel(, nogrid) ytitle("") legend(label(1 "Within-County Inequality") label(2 "Between-County Inequality")) xsize(5) ysize(7)
graph export "$output\fig12c.png", replace
graph export "$output\fig12c.pdf", replace
restore

*** 6. Effect of migration on county income 
*** Need all AGI for migration exercise ***

use "$data$set", clear
gen agi=returns*mean
collapse (sum) returns agi (median) Ctheil, by(statefips countyfips year)
gen avg_agi=agi/returns
egen id=group(statefips countyfips)
merge 1:1 statefips countyfips year using "$data\inflows", keep(1 3) nogen
merge 1:1 statefips countyfips year using "$data\outflows", keep(1 3) nogen
gen in_agi=in_count*in_meanagi
gen out_agi=out_count*out_meanagi
xtset id year
*keep if strpos(countyname,"Kimball")>0
/* assume immigrants and emmigrants follow same income trajectory
for each year, calculate income without any new migration*/
// AGI and returns of filers who were resident in the prior year
// need to check large swings in agi for natives, see Blaine County Idaho (https://www.mtexpress.com/wood_river_journal/special_sections/blaine-county-s-wealth-gap-cultural-diversity-are-increasing/article_10adbd56-4a7c-11ed-8123-8b7a6a29399d.html)
//https://www.naplesnews.com/story/news/2023/05/31/collier-county-wealthiest-florida-counties-list/70272164007/
tsfill
gen impute=(statefips==.)
foreach v of varlist returns in_count in_meanagi out_count out_meanagi agi avg_agi {
	ipolate `v' year, gen(i`v')
	replace `v'=i`v' if impute==1
}
merge m:1 statefips countyfips using "$data\countynames.dta", nogen keep(1 3)
merge m:1 statefips using "$data\statenames.dta", nogen keep(1 3)
foreach v of varlist statefips state countyfips countyname {
	replace `v'=`v'[_n-1] if impute==1
}
// Counterfactual native returns
sort id year
xtset id year
gen nativeret=returns-in_count+out_count				// annual native returns
gen nativeret_pctchg=(nativeret-l.returns)/l.returns	// annual pct change in native returns
gen counterret=nativeret if year==2010					// native returns at start of period
	replace counterret=l.counterret*(1+nativeret_pctchg) if year>2010	// trajectory of 2010 natives

// Counterfactual agi from natives
gen nativeagi=avg_agi*returns-in_agi+out_agi
gen nativeagi_pctchg=(nativeagi-l.agi)/(l.agi)
gen counteragi=nativeagi if year==2010
	replace counteragi=l.counteragi*(1+nativeagi_pctchg) if year>2010

// Difference between actual and counterfactual returns and AGI	
gen counteravg_agi=counteragi/counterret
gen agipctchg_mig=(avg_agi-counteravg_agi)/counteravg_agi
gen retpctchg_mig=(returns-counterret)/counterret
bysort id: egen allin_ret=sum(in_count)
bysort id: egen allout_ret=sum(out_count)
bysort id: egen allin_agi=sum(in_agi)
bysort id: egen allout_agi=sum(out_agi)

// Regressions of migration correlates of increase in inequality
gen avgagi_in=(allin_agi/allin_ret)
gen avgagi_out=allout_agi/allout_ret
gen D10Ctheil=(Ctheil-l9.Ctheil)/l9.Ctheil
gen D10avgagi=(avg_agi-l9.avg_agi)/l9.avg_agi
gen netmigpct=(allin_ret-allout_ret)/l9.returns
gen l9avg_agi=l9.avg_agi

outreg2 using "$output\tab5.xls", excel replace sum(log)

areg D10Ctheil D10avgagi if year==2019, a(statefips) robust
	outreg2 using "$output\tab6.xls", replace
reg D10Ctheil D10avgagi avgagi_in avgagi_out l9.avg_agi netmigpct if year==2019, robust
	outreg2 using "$output\tab6.xls", append
areg D10Ctheil D10avgagi avgagi_in avgagi_out l9.avg_agi netmigpct if year==2019, a(statefips)  robust
	outreg2 using "$output\tab6.xls", append
reg D10Ctheil D10avgagi c.avgagi_in##c.l9avg_agi c.avgagi_out##c.l9avg_agi netmigpct if year==2019, robust
	outreg2 using "$output\tab6.xls", append
areg D10Ctheil D10avgagi c.avgagi_in##c.l9avg_agi c.avgagi_out##c.l9avg_agi netmigpct if year==2019, a(statefips)  robust
	outreg2 using "$output\tab6.xls", append
reg D10Ctheil D10avgagi agipctchg_mig retpctchg_mig l9.avg_agi if year==2019,  robust
	outreg2 using "$output\tab6.xls", append
areg D10Ctheil D10avgagi agipctchg_mig retpctchg_mig l9.avg_agi if year==2019, a(statefips)   robust
	outreg2 using "$output\tab6.xls", append

*** 7. Local Inequality Index

use "$data\inequality", clear
*sort statefips countyfips year
collapse (sum) mean returns (median) Ca* USa* STa*, by(statefips countyfips year)
gen income=mean*returns

preserve
tempfile a1
collapse (mean) Ca* [aw=returns], by(year)
foreach v of varlist Ca* {
	rename `v' `v'_pc
}
save `a1', replace
restore

preserve
tempfile a2
collapse (mean) Ca* [aw=income], by(year)
foreach v of varlist Ca* {
	rename `v' `v'_py
}
save `a2', replace
restore

collapse (sum) income mean returns (median) Ca* USa* STa*, by(statefips year)

preserve
tempfile a3
collapse (mean) STa* [aw=returns], by(year)
foreach v of varlist STa* {
	rename `v' `v'_pc
}
save `a3', replace
restore

preserve
tempfile a4
collapse (mean) STa* [aw=income], by(year)
foreach v of varlist STa* {
	rename `v' `v'_py
}
save `a4', replace
restore

duplicates drop year, force
keep year US*
merge 1:1 year using `a1', nogen
merge 1:1 year using `a2', nogen
merge 1:1 year using `a3', nogen
merge 1:1 year using `a4', nogen

gen index=.

twoway (line USa1 year) (line Ca1_pc year) (line STa1_pc year)
save "$data\new_index.dta", replace




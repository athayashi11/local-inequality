clear 
clear matrix
set more off
**testing git
global data "..\Datasets"

***run with and without capital gains
local cg=1

quietly {

*** Calculate Inequality Measures Over Time at Different Geographies ***
// before 2010, data not disaggregated by AGI group
// ginis are too high compared to census -- check cutpoints, consider capgains, not that data does not include people not requried to file returns (low income group). 
// note location in tax data may differ from taxpayer's actual residence
// county year variable is the tax year
use "$data\statescounties", clear 

if `cg'==0 {
	replace agi=agi-capgain
}

*1. Create balanced panel
drop if countyfips==0 	// aggregate up to state and national levels for consistency in data?
drop if statefips==11	// drop DC
drop if agi_stub==1		// drop people with AGI<$1 (business losses?)
drop if returns<1
gen mean=agi/returns
drop if mean<3 // some counties in early years have negative AGI in $1-$10k range offsetting positive income in $10-$25k range resulting in too low AGI/return					

preserve				// drop counties that are not in entire sample
tempfile b
duplicates drop id year, force
bysort id: gen n=_n
bysort id: egen maxn=max(n)
drop if maxn<11
duplicates drop statefips countyfips, force
keep statefips countyfips
save `b', replace
restore
merge m:1 statefips countyfips using `b', nogen keep(3)

// AGI cutoffs for intervals
gen lcut=1 if agi_stub==2
	replace lcut=25 if agi_stub==3
	replace lcut=50 if agi_stub==4
	replace lcut=75 if agi_stub==5
	replace lcut=100 if agi_stub==6
	replace lcut=200 if agi_stub==7
gen hcut=25 if agi_stub==2
	replace hcut=50 if agi_stub==3
	replace hcut=75 if agi_stub==4
	replace hcut=100 if agi_stub==5
	replace hcut=200 if agi_stub==6
	replace hcut=. if agi_stub==7
drop if mean>hcut|mean<lcut	

bysort id year: gen n=_n
bysort id year: egen maxn=max(n)
drop if maxn<6
drop n maxn

preserve
collapse (sum) capgain, by(year)
keep if year<=2019
save "$data\capgains.dta", replace 
restore 

// create histograms within intervals per Cowell and Mehta
expand 2 if agi_stub<7				
bysort id agi_stub year: gen n=_n if agi_stub<7
rename agi_stub interval

sort id year interval

gen lmean=(mean+lcut)/2 if interval<7
gen hmean=(mean+hcut)/2 if interval<7
replace returns=returns*(mean-hmean)/(lmean-hmean) if n==1 & interval<7
replace returns=returns*(1-(mean-hmean)/(lmean-hmean)) if n==2 & interval<7
replace hcut=mean if n==1
	replace mean=lmean if n==1
replace lcut=mean if n==2
	replace mean=hmean if n==2
replace interval=lcut

// estimate pareto distribution above $200,000
gen alpha=(mean/lcut)/((mean/lcut)-1) if interval==200
gen x400=1-(lcut/400)^alpha
gen x600=(lcut/400)^alpha-(lcut/600)^alpha
gen x800=(lcut/600)^alpha-(lcut/800)^alpha
gen x1m=(lcut/800)^alpha-(lcut/1000)^alpha
gen x1pm=(lcut/1000)^alpha

sort id year interval
expand 5 if interval==200
bysort id year interval: gen k=_n if interval==200
replace hcut=400 if k==1
	replace returns=returns*x400 if k==1
replace lcut=400 if k==2
	replace hcut=600 if k==2
	replace returns=returns*x600 if k==2
replace lcut=600 if k==3
	replace hcut=800 if k==3
	replace returns=returns*x800 if k==3
replace lcut=800 if k==4
	replace hcut=1000 if k==4
	replace returns=returns*x1m if k==4
replace lcut=1000 if k==5
	replace hcut=. if k==5
	replace returns=returns*x1pm if k==5

// calculate conditional mean agi in pareto distribution
preserve
tempfile q
keep if k==5
expand 1000
gen x=rpareto(alpha,200)
drop k
gen k=1 if x>=200 & x<400 
replace k=2 if x>=400 & x<600 
replace k=3 if x>=600 & x<800 
replace k=4 if x>=800 & x<1000 
replace k=5 if x>=1000
collapse (mean) x, by(statefips countyfips year k)
save `q', replace
restore 

merge m:1 statefips countyfips year k using `q', nogen
replace mean=x if interval==200
replace interval=lcut if k!=.
	
keep statefips state countyfips countyname interval returns year mean lcut hcut
egen id=group(statefips countyfips year)
egen id2=group(statefips year)
foreach v of varlist interval returns mean lcut hcut {
	replace `v'=round(`v',1)
}

gen Cgini=.
gen Ca05=.
gen Ca1=.
gen Ca2=.
gen Cp9010=.
gen Cmeanmed=.
gen Cmeanlogdev=.
gen Ctheil=.
gen Chalfsqcoeffvar=.
sum id
local b="`r(max)'"
*forval i=1/`r(max)' {
forval i=1/10 {
	noisily display "`i' of `b'"
	preserve
	tempfile a
	keep if id==`i'
	ineqdeco mean [fw=returns]
	replace Cgini=`r(gini)'
	replace Ca05=`r(ahalf)'
	replace Ca1=`r(a1)'
	replace Ca2=`r(a2)'
	replace Cp9010=`r(p90p10)'
	replace Cmeanmed=`r(mean)'/`r(p50)'
	replace Cmeanlogdev=`r(ge0)'
	replace Ctheil=`r(ge1)'
	replace Chalfsqcoeffvar=`r(ge2)'
	keep id C*
	duplicates drop id, force
	save `a', replace
	restore
	merge m:1 id using `a', nogen update
}

gen USgini=.
gen USa05=.
gen USa1=.
gen USa2=.
gen USp9010=.
gen USmeanmed=.
gen USmeanlogdev=.
gen UStheil=.
gen UShalfsqcoeffvar=.
forval y=2010/2020 {
	noisily display "year `y'"
	preserve
	tempfile b
	keep if year==`y'
	ineqdeco mean [fw=returns]
	replace USgini=`r(gini)'
	replace USa05=`r(ahalf)'
	replace USa1=`r(a1)'
	replace USa2=`r(a2)'
	replace USp9010=`r(p90p10)'
	replace USmeanmed=`r(mean)'/`r(p50)'
	replace USmeanlogdev=`r(ge0)'
	replace UStheil=`r(ge1)'
	replace UShalfsqcoeffvar=`r(ge2)'
	keep year US*
	duplicates drop year, force
	save `b', replace
	restore
	merge m:1 year using `b', nogen update
}

gen STgini=.
gen STa05=.
gen STa1=.
gen STa2=.
gen STp9010=.
gen STmeanmed=.
gen STmeanlogdev=.
gen STtheil=.
gen SThalfsqcoeffvar=.
sum id2
local p="`r(max)'"
forval z=1/`r(max)'{
	noisily display "`z' of `p'"
	preserve
	tempfile c
	keep if id2==`z'
	ineqdeco mean [fw=returns]
	replace STgini=`r(gini)'
	replace STa05=`r(ahalf)'
	replace STa1=`r(a1)'
	replace STa2=`r(a2)'
	replace STp9010=`r(p90p10)'
	replace STmeanmed=`r(mean)'/`r(p50)'
	replace STmeanlogdev=`r(ge0)'
	replace STtheil=`r(ge1)'
	replace SThalfsqcoeffvar=`r(ge2)'
	keep id2 ST*
	duplicates drop id2, force
	save `b', replace
	restore
	merge m:1 id2 using `b', nogen update
}
drop interval hcut
drop if year==2020 	// drop first COVID year

if `cg'==1 {
	save "$data\inequality", replace
}
if `cg'==0 {
	save "$data\inequality_nocg", replace
}

}

use "$data\inequality", clear
keep statefips countyfips countyname state
duplicates drop statefips countyfips, force
save "$data\countynames.dta", replace

use "$data\inequality", clear
keep statefips state
duplicates drop 
save "$data\statenames.dta", replace
clear 
clear matrix
set more off

global data "..\Data"
global output "..\Output"

capture log using "$output\engage.log", replace
clear
*https://www.epi.org/publication/income-inequality-in-the-us/
import excel "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Datasets\1-99 income ratio 2013.xlsx", sheet("Sheet1")
gen geo=1 if _n<52
	replace geo=2 if geo==. & _n<3117
	replace geo=3 if geo==. & _n>3117
drop if A==.
rename C top1_avginc
rename D bot99_avginc
rename E ratio199

drop if geo==3

split B, p(,) g(s)
gen s=(s2=="")
gen state=B if s2==""
statastates, n(state)
replace s2=state_abbrev if s2==""
keep top1_avginc bot99_avginc ratio199 s1 s2 s
rename s1 county
rename s2 state
rename s state_level
replace state=trim(state)

tempfile a
preserve
keep if state_level==1
keep state ratio199
rename ratio199 state_ratio199
save `a', replace
restore

*histogram ratio199, by(state)

/*keep if state_level==0
merge m:1 state using `a', nogen
histogram ratio199 if state=="AR", xline(15) title("AR")*/

keep if state_level==0
collapse (mean) avg_ratio199=ratio199 (median) med_ratio199=ratio199 (min) min_ratio199=ratio199 (max) max_ratio199=ratio199 (sd) sd_ratio199=ratio199, by(state)
merge 1:1 state using `a', nogen

gen diff=state_ratio199-med_ratio199

scatter med_ratio199 state_ratio199, mlabel(state)
graph export "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Output\med.pdf", replace
scatter diff state_ratio199, mlabel(state)
graph export "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Output\diff.pdf", replace
scatter sd_ratio199 state_ratio199, mlabel(state)
graph export "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Output\sd.pdf", replace
scatter min_ratio199 state_ratio199, mlabel(state)
graph export "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Output\min.pdf", replace
scatter max_ratio199 state_ratio199, mlabel(state)
graph export "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Output\max.pdf", replace

 

*U.S. ratio is 25.3

*** 3. calculate gini 
keep if year==2020 & countyfips==0
keep if agi_stub==5
sort I_gini
egen idy=group(statefips countyfips year)
gen I_gini=.
sum idy
forval i=1/`r(max)' {
	display `i'
	capture fastgini mean [w=returns] if idy==`i'
	quietly capture replace I_gini=`r(gini)' if idy==`i'
}
	
*** 4. mean/median income ratio
preserve 
tempfile a
collapse (mean) mean [aw=returns], by(idy)
rename mean avg_agi
save `a', replace
restore
merge m:1 idy using `a', nogen
// calculate median income - using average income in agi_stub with median return
sort idy interval
by idy: egen sumreturns=sum(returns)
by idy: gen cumreturns=sum(returns)
gen median=mean if cumreturns>sumreturns/2 & cumreturns[_n-1]<sumreturns/2
// ratio of mean to median income by id year
gen I_meanmed=avg_agi/median

*** 5. coefficient of variation and stdev of log income
gen I_cv=.
gen lnmean=ln(mean)
gen I_sdlninc=.
sum idy
forval i=1/`r(max)' {
	display `i'
	capture sum mean [fw=returns] if idy==`i', detail
	capture replace I_cv=`r(sd)'/`r(mean)' if idy==`i'
	
	capture sum lnmean [fw=returns] if idy==`i', detail
	capture replace I_sdlninc=`r(sd)' if idy==`i'
}

******************************************************************

use "$data\usa", clear // getting ginis that are too big
keep if agi_stub>1
// AGI cutoffs for intervals
gen mean=agi/returns					
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
	replace hcut=. if agi_stub==8

// create histograms within intervals per Cowll and Mehta
expand 2 if agi_stub<7				
bysort year agi_stub: gen n=_n if agi_stub<7
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
replace mean=(hcut+lcut)/2 if k<5
bysort year interval: egen allreturns=sum(returns) if interval>=200
replace interval=lcut if k!=.
gen meanshare=(returns/allreturns)*mean if interval>=200
bysort year interval: egen allmeanshare=sum(meanshare) if interval>=200 & k<5
replace mean=(mean-allmeanshare[_n-1])/(returns/allreturns) if k==5

keep statefips state countyfips countyname interval returns year id mean lcut hcut

foreach v of varlist returns-interval {
	replace `v'=round(`v',1)
}

// calculate gini 
gen mean=agi/returns
gen I_gini=.
forval y=2010/2020 {
	fastgini mean [w=returns] if year==`y'
	replace I_gini=`r(gini)' if year==`y'
}
// mean/median income ratio
by year: egen allret=sum(returns)
gen x=avg_agi*returns/allret
by year: egen mean=sum(x)
// calculate median income - using average income in agi_stub with median return
by year: gen cumreturns=sum(returns)
gen median=avg_agi if cumreturns>sumreturns/2 & cumreturns[_n-1]<sumreturns/2
// ratio of mean to median income by id year
gen I_meanmed=avg_agi/median

*** 5. coefficient of variation and stdev of log income
gen I_cv=.
gen lnmean=ln(mean)
gen I_sdlninc=.
sum idy
forval i=1/`r(max)' {
	display `i'
	capture sum mean [fw=returns] if idy==`i', detail
	capture replace I_cv=`r(sd)'/`r(mean)' if idy==`i'
	
	capture sum lnmean [fw=returns] if idy==`i', detail
	capture replace I_sdlninc=`r(sd)' if idy==`i'
}

/**** 2. Map of county inequality and changes in inequality 2010-2020
*spshape2dta "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Datasets\USA_Counties",  saving(countyshapes) replace

use "$data\statescounties_inequality", clear
keep if median~=. & inlist(year, 2010, 2020)
foreach v of varlist I_gini I_meanmed I_cv I_sdlninc {
	sort id year
	by id: gen D_`v'=(`v'-`v'[_n-1])/`v'[_n-1]
}
keep if year==2020 & countyfips!=0
merge 1:1 statefips countyfips using `a', keep(3)

foreach v in "gini" "meanmed" "cv" "sdlninc" {
	count if I_`v'==.
	spmap I_`v' using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues)
	*graph export "$output\fig2_`v'.png", replace
	graph export "$output\fig2_`v'.pdf", replace
	count if D_I_`v'==.
	spmap D_I_`v' using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues)
	*graph export "$output\fig2_D`v'.png", replace
	graph export "$output\fig2_D`v'.pdf", replace
}*/


/*foreach v in "gini" "meanmed" "cv" "sdlninc" {
	foreach k in "max" "min" {
		preserve
		tempfile a`k'`v'
		keep statefips year D`v' I_`v' `k'D10`v' `k'D10`v'_name 
		keep if `k'D10`v'_name!=""
		rename D`v' `k'D`v' 
		rename I_`v' `k'I_`v'
		save `a`k'`v'', replace
		restore
	}
}
save "$data\trendingcounties", replace

use "$data\ineqovertime", clear
keep if countyfips==0
keep statefips state countyfips countyname year I_* D*
foreach v of varlist I* D* {
	rename `v' state`v'
}
foreach v in "gini" "meanmed" "cv" "sdlninc" {
	foreach k in "max" "min" {
		display "`k' x `v'"
		merge 1:1 statefips year using `a`k'`v'', nogen keep(3)
	}
}
egen g=group(statefips)
sum g
forval v=1/`r(max)' {
	preserve
	keep if g==`v'
	display `v'
	foreach v in "Ctheil" {
		su maxD10`v' if year == 2016, meanonly
		local b=`r(mean)'
		local a=maxD10`v'_name[1]
		local s=state[1]
		su minD10`v' if year == 2016, meanonly
		local d=`r(mean)'
		local c=minD10`v'_name[1]
		quietly twoway (line stateI_`v' year, lw(thick) lc(black))(line minI_`v' year, lp(dot))(line maxI_`v' year, lp(dash)), text(`b' 2016 "`a'") text(`d' 2016	"`c'") title(`s') 
		graph export "$output\\`s'`v'.pdf", replace
		*graph export "$output\\`s'.png", replace
	}
	restore
}

*/

/*use "$data\trendingcounties", clear
sort id year 
xtset id year
gen D10avg_agi=avg_agi-l10.avg_agi
gen x=(maxD10gini_name==countyname)
reg D10gini i.statefips D10avg_agi if year==2020 *//**** 2. Map of county inequality and changes in inequality 2010-2020
*spshape2dta "C:\Users\ath9f\Dropbox\2023 Inequality Spheres\Datasets\USA_Counties",  saving(countyshapes) replace

use "$data\statescounties_inequality", clear
keep if median~=. & inlist(year, 2010, 2020)
foreach v of varlist I_gini I_meanmed I_cv I_sdlninc {
	sort id year
	by id: gen D_`v'=(`v'-`v'[_n-1])/`v'[_n-1]
}
keep if year==2020 & countyfips!=0
merge 1:1 statefips countyfips using `a', keep(3)

foreach v in "gini" "meanmed" "cv" "sdlninc" {
	count if I_`v'==.
	spmap I_`v' using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues)
	*graph export "$output\fig2_`v'.png", replace
	graph export "$output\fig2_`v'.pdf", replace
	count if D_I_`v'==.
	spmap D_I_`v' using "$data\countyshapes_shp.dta", id(_ID) fcolor(Blues)
	*graph export "$output\fig2_D`v'.png", replace
	graph export "$output\fig2_D`v'.pdf", replace
}*/


/*foreach v in "gini" "meanmed" "cv" "sdlninc" {
	foreach k in "max" "min" {
		preserve
		tempfile a`k'`v'
		keep statefips year D`v' I_`v' `k'D10`v' `k'D10`v'_name 
		keep if `k'D10`v'_name!=""
		rename D`v' `k'D`v' 
		rename I_`v' `k'I_`v'
		save `a`k'`v'', replace
		restore
	}
}
save "$data\trendingcounties", replace

use "$data\ineqovertime", clear
keep if countyfips==0
keep statefips state countyfips countyname year I_* D*
foreach v of varlist I* D* {
	rename `v' state`v'
}
foreach v in "gini" "meanmed" "cv" "sdlninc" {
	foreach k in "max" "min" {
		display "`k' x `v'"
		merge 1:1 statefips year using `a`k'`v'', nogen keep(3)
	}
}
egen g=group(statefips)
sum g
forval v=1/`r(max)' {
	preserve
	keep if g==`v'
	display `v'
	foreach v in "Ctheil" {
		su maxD10`v' if year == 2016, meanonly
		local b=`r(mean)'
		local a=maxD10`v'_name[1]
		local s=state[1]
		su minD10`v' if year == 2016, meanonly
		local d=`r(mean)'
		local c=minD10`v'_name[1]
		quietly twoway (line stateI_`v' year, lw(thick) lc(black))(line minI_`v' year, lp(dot))(line maxI_`v' year, lp(dash)), text(`b' 2016 "`a'") text(`d' 2016	"`c'") title(`s') 
		graph export "$output\\`s'`v'.pdf", replace
		*graph export "$output\\`s'.png", replace
	}
	restore
}

*/

/*use "$data\trendingcounties", clear
sort id year 
xtset id year
gen D10avg_agi=avg_agi-l10.avg_agi
gen x=(maxD10gini_name==countyname)
reg D10gini i.statefips D10avg_agi if year==2020 */
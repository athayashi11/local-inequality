clear 
clear matrix
set more off

global data "..\Datasets"
global output "..\Output"
set graphics on

import delimited "$data\Income_stat_byQuintile_byCounty.csv"

gen statefips=substr(geoid,8,2)
gen countyfips=substr(geoid,10,3)
destring statefips countyfips, replace
gen top8095_mean=(highest_mean-top5_mean*0.05)/0.95
gen top5_ul=999999
drop highest_mean
gen id=_n

tempfile b
save `b', replace
****SOMETHING WRONG. CAN'T DO SPLIT HISTOGRAM FOR 80-95 WITHOUT CUTOFF. PARETO FROM 80-100?
count
forval z=1/`r(N)' {
	tempfile temp
	preserve
	keep if id==`z'
	local x=countyfips[1]
	local y=statefips[1]
	display `x'
	display `y'
	local z=top5_ll[1]
	if `z'==250001 {
		local m=highest_mean[1]
	}
	drop highest_mean
	insobs 1
	replace lowest_ul=lowest_mean[_n-1] if _n==2
	replace second_ul=second_mean[_n-1] if _n==2
	replace third_ul=third_mean[_n-1] if _n==2
	replace fourth_ul=fourth_mean[_n-1] if _n==2
	replace top5_ll=top8095_mean[_n-1] if _n==2
	replace top5_ul=top5_mean[_n-1] if _n==2
	xpose, clear v
	rename v1 h_cutoff
	rename v2 mean
	keep if strpos(_varname,"_ul")>0|strpos(_varname,"_ll")>0
	drop if strpos(_varname,"error")>0|strpos(_varname,"share")>0
	gen l_cutoff=h_cutoff[_n-1]
	replace h_cutoff=. if _varname=="top5_ul"
	replace l_cutoff=0 if _varname=="lowest_ul"
	rename _varname interval
	order interval l_cutoff h_cutoff mean 
	replace interval="20" if interval=="lowest_ul"
	replace interval="40" if interval=="second_ul"
	replace interval="60" if interval=="third_ul"
	replace interval="80" if interval=="fourth_ul"
	replace interval="95" if interval=="top5_ll"
	replace interval="100" if interval=="top5_ul"
	destring interval, replace
	
	if `z'==250001 {
		replace h_cutoff=. if interval==95
		replace l_cutoff=. if interval==100
	}
	
	// interpolate within quintile using Cowell and Mehta
	expand 2 if interval!=100
	bysort interval: gen n=_n if interval!=100
	gen w=20
		replace w=15 if interval==95
	gen lmean=(mean+l_cutoff)/2
	gen hmean=(mean+h_cutoff)/2
	gen p=(mean-hmean)/(lmean-hmean)
	replace w=20*p if n==1
	replace h_cutoff=mean if n==1
	replace mean=lmean if n==1
	replace w=20*(1-p) if n==2
	replace l_cutoff=mean if n==2
	replace mean=hmean if n==2
	replace w=5 if interval==100
	
	replace interval=10 if interval==20 & n==1
	replace interval=30 if interval==40 & n==1
	replace interval=50 if interval==60 & n==1
	replace interval=70 if interval==80 & n==1
	replace interval=87 if interval==95 & n==1
	
	if `z'==250001 {
		replace mean=(`m'-(7/20)*mean[_n-1])*20/13 if interval==95
	}
	
	** inequality federal policies ***

// 1. FCIRA

// 2. Loan Payment Pause

// 3. Student debt forgiveness

// 4. Biden tax plan
	
	*** Policy []: Student debt forgiveness - $50k with no cap***
	// https://budgetmodel.wharton.upenn.edu/issues/2022/8/23/forgiving-student-loans
	local expenditure=820000000000/1000		// amount of expenditure (agi in thousands)
	local pop=26260000						// eligible recipients https://www.whitehouse.gov/briefing-room/statements-releases/2023/01/27/fact-sheet-biden-harris-administration-releases-new-data-showing-26-million-people-in-all-50-states-applied-or-were-automatically-eligible-for-one-time-student-debt-relief/
	// need to revise when add back agi stub 1
	// per capita transfer within percentiles
	gen t20=(`expenditure'*.10011)/(0.2*`pop')
	gen t40=(`expenditure'*.1837)/(0.2*`pop')
	gen t60=(`expenditure'*.2539)/(0.2*`pop')
	gen t80=(`expenditure'*.2650)/(0.2*`pop')
	gen t90=(`expenditure'*.1237)/(0.1*`pop')
	gen t95=(`expenditure'*.0493)/(0.05*`pop')
	gen t99=(`expenditure'*.0215)/(0.04*`pop')
	gen t100=(`expenditure'*.0028)/(0.01*`pop')
	
// need to impute cutoffs above 5% lower limit. use pareto distribution [reasonable for all counties?]
// use 90%, 95% and 99% cutoffs https://en.wikipedia.org/wiki/Pareto_distribution
// expected value of income above cutoff gives alpha
	
	gen x20=28784 if h_cutoff>28784 & l_cutoff<28784
	gen x40=50795 if h_cutoff>50795 & l_cutoff<50795
	gen x60=82400 if h_cutoff>82400 & l_cutoff<82400
	gen x80=141096 if h_cutoff>141096 & l_cutoff<141096
	gen x90=212209 if h_cutoff>212209 & l_cutoff<212209
	gen x95=321699 if h_cutoff>321699 & l_cutoff<321699
	gen x99=961711 if h_cutoff>961711 & l_cutoff<961711

// something weird with alameda and other counties with top cutoff of 250001	
	
	gen x20_share=(x20-l_cutoff)/(h_cutoff-l_cutoff)
	gen x40_share=(x40-l_cutoff)/(h_cutoff-l_cutoff) if x20==.
		replace x40_share=(x40-x20)/(h_cutoff-l_cutoff) if x40!=. & x20!=.
		replace x40_share=1-x20_share if x40==. & x20!=.
	gen x60_share=(x60-l_cutoff)/(h_cutoff-l_cutoff) if x40==.
		replace x60_share=(x60-x40)/(h_cutoff-l_cutoff) if x60!=. & x40!=.
		replace x60_share=1-x40_share if x60==. & x40!=.
	gen x80_share=(x80-l_cutoff)/(h_cutoff-l_cutoff) if x60==.
		replace x80_share=(x80-x60)/(h_cutoff-l_cutoff) if x80!=. & x60!=.
		replace x80_share=1-x60_share if x80==. & x60!=.
	gen x90_share=(x90-l_cutoff)/(h_cutoff-l_cutoff) if x80==.
		replace x90_share=(x90-x80)/(h_cutoff-l_cutoff) if x90!=. & x80!=.
		replace x90_share=1-x80_share if x90==. & x80!=.
	gen x95_share=(x95-l_cutoff)/(h_cutoff-l_cutoff) if x90==.
		replace x95_share=(x95-x90)/(h_cutoff-l_cutoff) if x95!=. & x90!=.
		replace x95_share=1-x90_share if x95==. & x90!=.
	gen x99_share=(x99-l_cutoff)/(h_cutoff-l_cutoff) if x95==.
		replace x99_share=(x99-x95)/(h_cutoff-l_cutoff) if x99!=. & x95!=.
		replace x99_share=1-x95_share if x99==. & x95!=.
	gen x100_share=1-x99_share if x99!=.
	
	// probability X>x is (Xmin/x)^alpha
	* pareto runs into issues for very poor hudspeth
	if `z'!=250001 {
	local xm=l_cutoff[11]
	local alpha=(mean[11]/`xm')/((mean[11]/`xm')-1)
	replace x80_share=1-(`xm'/141096)^`alpha' if interval==100 & x80!=. & x60==.
	replace x90_share=(`xm'/141096)^`alpha'-(`xm'/212209)^`alpha' if interval==100 & x80!=. & x60==.
	replace x95_share=(`xm'/212209)^`alpha'-(`xm'/321699)^`alpha' if interval==100 & x80!=. & x60==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==100 & x80!=. & x60==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==100 & x80!=. & x60==.
	
	replace x90_share=1-(`xm'/212209)^`alpha' if interval==100 & x90!=. & x80==.
	replace x95_share=(`xm'/212209)^`alpha'-(`xm'/321699)^`alpha' if interval==100 & x90!=. & x80==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==100 & x90!=. & x80==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==100 & x90!=. & x80==.

	replace x95_share=1-(`xm'/321699)^`alpha' if interval==100 & x95!=. & x90==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==100 & x95!=. & x90==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==100 & x95!=. & x90==.
	
	replace x99_share=1-(`xm'/961711)^`alpha' if interval==100 & x99!=. & x95==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==100 & x99!=. & x95==.
	}
	
	if `z'==250001 {
	local xm=l_cutoff[10]
	local alpha=(mean[10]/`xm')/((mean[11]/`xm')-1)
	replace x80_share=1-(`xm'/141096)^`alpha' if interval==95 & x80!=. & x60==.
	replace x90_share=(`xm'/141096)^`alpha'-(`xm'/212209)^`alpha' if interval==95 & x80!=. & x60==.
	replace x95_share=(`xm'/212209)^`alpha'-(`xm'/321699)^`alpha' if interval==95 & x80!=. & x60==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==95 & x80!=. & x60==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==95 & x80!=. & x60==.
	
	replace x90_share=1-(`xm'/212209)^`alpha' if interval==95 & x90!=. & x80==.
	replace x95_share=(`xm'/212209)^`alpha'-(`xm'/321699)^`alpha' if interval==95 & x90!=. & x80==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==95 & x90!=. & x80==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==95 & x90!=. & x80==.

	replace x95_share=1-(`xm'/321699)^`alpha' if interval==95 & x95!=. & x90==.
	replace x99_share=(`xm'/321699)^`alpha'-(`xm'/961711)^`alpha' if interval==95 & x95!=. & x90==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==95 & x95!=. & x90==.
	
	replace x99_share=1-(`xm'/961711)^`alpha' if interval==95 & x99!=. & x95==.
	replace x100_share=(`xm'/961711)^`alpha' if interval==95 & x99!=. & x95==.
	}
	
	replace x20_share=1 if x20==. & (x20[_n+1]!=. | x20[_n+2]!=.)
	replace x40_share=1 if x40_share==. & (x40_share[_n+1]!=. | x40_share[_n+2]!=.) & (x40_share[_n-1]!=. | x40_share[_n-2]!=.)
	replace x60_share=1 if x60_share==. & (x60_share[_n+1]!=. | x60_share[_n+2]!=.) & (x60_share[_n-1]!=. | x60_share[_n-2]!=.)
	replace x80_share=1 if x80_share==. & (x80_share[_n+1]!=. | x80_share[_n+2]!=.) & (x80_share[_n-1]!=. | x80_share[_n-2]!=.)
	replace x90_share=1 if x90_share==. & (x90_share[_n+1]!=. | x90_share[_n+2]!=.) & (x90_share[_n-1]!=. | x90_share[_n-2]!=.)
	replace x95_share=1 if x95_share==. & (x95_share[_n+1]!=. | x95_share[_n+2]!=.) & (x95_share[_n-1]!=. | x95_share[_n-2]!=.)
	replace x99_share=1 if x99_share==. & (x99_share[_n+1]!=. | x99_share[_n+2]!=.) & (x99_share[_n-1]!=. | x99_share[_n-2]!=.)

	foreach v of varlist *_share {
		replace `v'=0 if `v'==.
	}

	if `z'==250001 {
		replace w=7.5 if interval==87
		replace w=12.5 if interval==95
		drop if interval==100
		replace interval=100 if interval==95
	}
	
	gen mean2=mean+x20_share*t20+x40_share*t40+x60_share*t60+x80_share*t80+x90_share*t90+x95_share*t95+x99_share*t99+x100_share*t100

	gen countyfips=`x'
	gen statefips=`y'

	replace w=round(w,1)
	expand w // what does this mean for top tail? expanding at mean?
	rename mean mean1
	forval v=1/2 {
		// mean/median income
		egen m`v'=mean(mean`v')
		gen I_meanmed`v'=m`v'/h_cutoff if interval==50 
		gen DI_meanmed`v'=(I_meanmed`v'-I_meanmed1)/I_meanmed1
		
		//gini
		gen I_gini`v'=.
		capture fastgini mean`v'
		capture replace I_gini`v'=`r(gini)'
		gen DI_gini`v'=(I_gini`v'-I_gini1)/I_gini1

		// mean 95/10 ratio (87/10 ratio for 2500001 counties)
		gen a`v'=mean`v' if interval==100
			egen aa`v'=max(a`v')
		gen b`v'=mean`v' if interval==10
			egen bb`v'=max(b`v')
		gen I_9510`v'=aa`v'/bb`v'
		gen DI_9510`v'=(I_9510`v'-I_95101)/I_95101
		
		// coefficient of variation
		gen I_cv`v'=.
		capture sum mean`v', detail
		capture replace I_cv`v'=`r(sd)'/`r(mean)'
		gen DI_cv`v'=(I_cv`v'-I_cv1)/I_cv1
		
		//stdev of log income
		gen lnmean`v'=ln(mean`v')
		capture sum lnmean`v', detail
		gen I_sdlninc`v'=.
		capture replace I_sdlninc`v'=`r(sd)'
		gen DI_sdlninc`v'=(I_sdlninc`v'-I_sdlninc1)/I_sdlninc1
	}
	
	keep if interval==50
	keep if _n==1
	keep I_* DI_* countyfips statefips
	
	save `temp', replace
	restore 
	merge 1:1 countyfips statefips using `temp', nogen update
}
save "$data\simulations.dta", replace


use "$data\simulations.dta", replace
keep name fourth_ul top5_ll gini_index statefips countyfips I_* DI_*




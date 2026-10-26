clear 
clear matrix
set more off
set graphics off

global data "..\Datasets"
global output "..\Output\NYU"

use "$data\inequality", clear

keep if year==2019
keep countyfips-mean Ctheil UStheil STtheil
replace mean=mean*1000

quietly{
*** 1. Sanders Tax Plan 
// https://www.taxpolicycenter.org/publications/analysis-senator-sanderss-tax-proposals
// by 2021 cash income percentile

// create policy schedule assuming uniform distribution within quintile
preserve

local cut20=26200
local cut40=52000
local cut60=93300
local cut80=169500
local cut90=247700
local cut95=352800
local cut99=837400
local cut999=3665700

local ben20=170
local ben40=480
local ben60=1070
local ben80=2220
local ben90=4060
local ben95=7060
local ben99=22350
local ben999=518190
local ben1=3494650

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean-policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "Sanders County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "Sanders State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\fig14_sandersT.png", replace
graph export "$output\fig14_sandersT.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_sandersSD.png", replace
graph export "$output\countysim_sandersSD.pdf", replace

/*gen dCcv=Ccv_policy-Ccv
sum dCcv
histogram dCcv, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_sandersCV.png", replace
graph export "$output\countysim_sandersCV.pdf", replace*/
outreg2 using "$output\sanders_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\sanders_data.xls", firstrow(variables) replace
restore

*** 2. TCJA
// https://www.taxpolicycenter.org/publications/distributional-analysis-conference-agreement-tax-cuts-and-jobs-act/full
preserve
local cut20=25000
local cut40=48600
local cut60=86100
local cut80=149400
local cut90=216800
local cut95=307900
local cut99=732800
local cut999=3439900

local ben20=60
local ben40=380
local ben60=930
local ben80=1810
local ben90=2970
local ben95=4550
local ben99=13480
local ben999=51140
local ben1=193380

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "TCJA County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "TCJA State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(TCJA - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcja.png", replace
graph export "$output\countysim_tcja.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(TCJA - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcjaSD.png", replace
graph export "$output\countysim_tcjaSD.pdf", replace

/*gen dCcv=Ccv_policy-Ccv
sum dCcv
histogram dCcv, percent xtitle(TCJA - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcjaCV.png", replace
graph export "$output\countysim_tcjaCV.pdf", replace*/
outreg2 using "$output\tcja_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\tcja_data.xls", firstrow(variables) replace
restore

// 3. Student debt forgiveness
*** Policy []: Student debt forgiveness - $50k with no cap***
// https://budgetmodel.wharton.upenn.edu/issues/2022/8/23/forgiving-student-loans
preserve
use "$data\inequality", clear
keep if year==2019
keep countyfips-mean Ctheil UStheil STtheil
replace mean=mean*1000
local expenditure=820300000000		// amount of expenditure 
	//www.whitehouse.gov/briefing-room/statements-releases/2023/01/27/fact-sheet-biden-harris-administration-releases-new-data-showing-26-million-people-in-all-50-states-applied-or-were-automatically-eligible-for-one-time-student-debt-relief/
	// need to revise when add back agi stub 1
	// per capita transfer within percentiles

local cut20=28784
local cut40=40795
local cut60=82400
local cut80=141096
local cut90=212209
local cut95=321699
local cut99=961711
local cut999=3668499

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

sum returns if q==20
local ben20=(`expenditure'*.10011)/`r(sum)'
sum returns if q==40
local ben40=(`expenditure'*.1837)/`r(sum)'
sum returns if q==60
local ben60=(`expenditure'*.2539)/`r(sum)'
sum returns if q==80
local ben80=(`expenditure'*.2650)/`r(sum)'
sum returns if q==90
local ben90=(`expenditure'*.1237)/`r(sum)'
sum returns if q==95
local ben95=(`expenditure'*.0493)/`r(sum)'
sum returns if q==99
local ben99=(`expenditure'*.0215)/`r(sum)'
sum returns if q==99
local ben999=(`expenditure'*.0025)/`r(sum)'
local ben1=0
****WHY IS Q60 NEGATIVE!?
gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "Loan County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "Loan State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(50k Student Debt Forgiveness - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebt.png", replace
graph export "$output\countysim_studebt.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(50k Student Debt Forgiveness - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebtSD.png", replace
graph export "$output\countysim_studebtSd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(50k Student Debt Forgiveness - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebtCV.png", replace
graph export "$output\countysim_studebtCV.pdf", replace*/
outreg2 using "$output\studebt_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\studebt_data.xls", firstrow(variables) replace
restore

// 4. Loan Payment Pause - current law
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=210000000000		// amount of expenditure 
	
local cut20=28784
local cut40=40795
local cut60=82400
local cut80=141096
local cut90=212209
local cut95=321699
local cut99=961711
local cut999=3668499

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

sum returns if q==20
local ben20=(`expenditure'*.025)/`r(sum)'
sum returns if q==40
local ben40=(`expenditure'*.1030)/`r(sum)'
sum returns if q==60
local ben60=(`expenditure'*.2210)/`r(sum)'
sum returns if q==80
local ben80=(`expenditure'*.3520)/`r(sum)'
sum returns if q==90
local ben90=(`expenditure'*.1740)/`r(sum)'
sum returns if q==95
local ben95=(`expenditure'*.086)/`r(sum)'
sum returns if q==99
local ben99=(`expenditure'*.032)/`r(sum)'
sum returns if q==99
local ben999=(`expenditure'*.008)/`r(sum)'
local ben1=0
****WHY IS Q60 NEGATIVE!?
gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "Interest1 County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "Interest1 State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1.png", replace
graph export "$output\countysim_interest1.pdf", replace

sum dCtheil
twoway histogram dCtheil if dCtheil<=0, percent xtitle(Student Loan Interest Moratorium - County Effects) xlabel(,nogrid) ylabel(, nogrid) bins(100) xline(`r(mean)') color(midblue) legend(off)|| histogram dCtheil if dCtheil>0, percent xtitle(Student Loan Interest Moratorium - County Effects) xlabel(,nogrid) ylabel(, nogrid) bins(50) color(red) legend(off)
graph export "$output\countysim_interest1-alumni.png", replace
graph export "$output\countysim_interest1-alumni.pdf", replace
sum dCtheil
twoway histogram dCtheil if dCtheil<=-.0022|dCtheil>-.001, percent xtitle(Student Loan Interest Moratorium - County Effects) xlabel(,nogrid) ylabel(, nogrid) bins(100) xline(`r(mean)') color(white) legend(off)
graph export "$output\countysim_interest1-alumninat.png", replace
graph export "$output\countysim_interest1-alumninat.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1SD.png", replace
graph export "$output\countysim_interest1Sd.pdf", replace

histogram dCsd, percent xtitle(Student Loan Interest Moratorium - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) bins(100) xline(`r(mean)') color(red) 
graph export "$output\countysim_interest1SD-alumni.png", replace
graph export "$output\countysim_interest1SD-alumni.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1CV.png", replace
graph export "$output\countysim_interest1CV.pdf", replace*/

gen inc=(dCtheil>0)
save "$data\interest1.dta", replace
outreg2 using "$output\interest1_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\interest1_data.xls", firstrow(variables) replace
restore 

// 5. Loan Payment Pause - alternative 1
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=129000000000		// amount of expenditure 
	
local cut20=28784
local cut40=40795
local cut60=82400
local cut80=141096
local cut90=212209
local cut95=321699
local cut99=961711
local cut999=3668499

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

sum returns if q==20
local ben20=(`expenditure'*.054)/`r(sum)'
sum returns if q==40
local ben40=(`expenditure'*.221)/`r(sum)'
sum returns if q==60
local ben60=(`expenditure'*.475)/`r(sum)'
sum returns if q==80
local ben80=(`expenditure'*.25)/`r(sum)'
sum returns if q==90
local ben90=(`expenditure'*0)/`r(sum)'
sum returns if q==95
local ben95=(`expenditure'*0)/`r(sum)'
sum returns if q==99
local ben99=(`expenditure'*0)/`r(sum)'
sum returns if q==99
local ben999=(`expenditure'0)/`r(sum)'
local ben1=0
****WHY IS Q60 NEGATIVE!?
gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "Interest2 County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "Interest2 State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2.png", replace
graph export "$output\countysim_interest2.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2SD.png", replace
graph export "$output\countysim_interest2Sd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2CV.png", replace
graph export "$output\countysim_interest2CV.pdf", replace*/
outreg2 using "$output\interest2_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\interest2_data.xls", firstrow(variables) replace
restore	

// 5. Loan Payment Pause - alternative 2
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=6100000000		// amount of expenditure 
	
local cut20=28784
local cut40=40795
local cut60=82400
local cut80=141096
local cut90=212209
local cut95=321699
local cut99=961711
local cut999=3668499

gen q=20 if mean>=0 & mean<`cut20'
	replace q=40 if mean>=`cut20' & mean<`cut40'
	replace q=60 if mean>=`cut40' & mean<`cut60'
	replace q=80 if mean>=`cut60' & mean<`cut80'
	replace q=90 if mean>=`cut80' & mean<`cut90'
	replace q=95 if mean>=`cut90' & mean<`cut95'
	replace q=99 if mean>=`cut95' & mean<`cut99'
	replace q=999 if mean>=`cut99' & mean<`cut999'
	replace q=1 if mean>=`cut999'

sum returns if q==20
local ben20=(`expenditure'*.136)/`r(sum)'
sum returns if q==40
local ben40=(`expenditure'*.455)/`r(sum)'
sum returns if q==60
local ben60=(`expenditure'*.393)/`r(sum)'
sum returns if q==80
local ben80=(`expenditure'*.017)/`r(sum)'
sum returns if q==90
local ben90=(`expenditure'*0)/`r(sum)'
sum returns if q==95
local ben95=(`expenditure'*0)/`r(sum)'
sum returns if q==99
local ben99=(`expenditure'*0)/`r(sum)'
sum returns if q==99
local ben999=(`expenditure'0)/`r(sum)'
local ben1=0
****WHY IS Q60 NEGATIVE!?
gen q20=(`ben20'/10)*20
gen q40=q20+((`ben40'-q20)/10)*20
gen q60=q40+((`ben60'-q40)/10)*20
gen q80=q60+((`ben80'-q60)/10)*20
gen q90=q80+((`ben90'-q80)/5)*10
gen q95=q90+((`ben95'-q90)/2.5)*5
gen q99=q95+((`ben99'-q95)/2)*4
gen q999=q99+((`ben999'-q99)/0.45)*0.9
gen q1=q999+((`ben1'-q999)/0.05)*0.1

gen policy=(`ben20'/10)*20*((mean-0)/(`cut20'-0)) if q==20
replace policy=q20+((`ben40'-q20)/10)*20*((mean-`cut20')/(`cut40'-`cut20')) if q==40
replace policy=q40+((`ben60'-q40)/10)*20*((mean-`cut40')/(`cut60'-`cut40')) if q==60
replace policy=q60+((`ben80'-q60)/10)*20*((mean-`cut60')/(`cut80'-`cut60')) if q==80
replace policy=q80+((`ben90'-q80)/5)*10*((mean-`cut80')/(`cut90'-`cut80')) if q==90
replace policy=q90+((`ben95'-q90)/2.5)*5*((mean-`cut90')/(`cut95'-`cut90')) if q==95
replace policy=q95+((`ben99'-q95)/2)*4*((mean-`cut95')/(`cut99'-`cut95')) if q==99
replace policy=q99+((`ben999'-q99)/0.45)*0.9*((mean-`cut99')/(`cut999'-`cut99')) if q==999
sum mean
replace policy=q999+((`ben1'-q999)/0.05)*0.1*((mean-`cut999')/(`r(max)'-`cut99')) if q==1
// assume top income is top mean in data

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd=`r(sd)'

gen mean_orig=mean
replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}
sum mean [w=returns]
gen USsd_policy=`r(sd)'

ineqdeco mean [fw=returns]
gen UStheil_policy=`r(ge1)'

gen Ctheil_policy=.
gen STtheil_policy=.
sum id
forval i=1/`r(max)' {
	noisily display "Interest3 County `i'"
	ineqdeco mean [fw=returns] if id==`i'
	replace Ctheil_policy=`r(ge1)' if id==`i'
}
egen id2=group(statefips)
sum id2
forval j=1/`r(max)' {
	noisily display "Interest3 State `j'"
	ineqdeco mean [fw=returns] if id2==`j'
	replace STtheil_policy=`r(ge1)' if id2==`j'
}
count if Ctheil_policy>Ctheil
count if STtheil_policy>STtheil

gen income_policy=returns*mean
gen income=returns*mean_orig
collapse (sum) income income_policy (median) Ctheil* UStheil* Csd* USsd*, by(statefips countyfips)
egen USincome=sum(income)
egen USincome_policy=sum(income_policy)
gen USincome_share=income/USincome
gen USincome_policy_share=income_policy/USincome_policy
egen id=group(statefips countyfips)

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
gen dUStheil=UStheil_policy-UStheil
sum dUStheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3.png", replace
graph export "$output\countysim_interest3.pdf", replace

gen dCsd=Csd_policy-Csd
gen dUSsd=USsd_policy-USsd
sum dUSsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3SD.png", replace
graph export "$output\countysim_interest3Sd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3CV.png", replace
graph export "$output\countysim_interest3CV.pdf", replace*/
outreg2 using "$output\interest3_stats.xls", excel replace sum(log)

gen CT=Ctheil*USincome_share
gen CT_policy=Ctheil_policy*USincome_policy_share
collapse (sum) CT_policy CT (median) UStheil UStheil_policy
export excel using "$output\interest3_data.xls", firstrow(variables) replace
restore	
}

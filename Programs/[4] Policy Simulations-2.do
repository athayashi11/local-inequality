clear 
clear matrix
set more off
set graphics off

global data "..\Datasets"
global output "..\Output\withcapgain"

use "$data\inequality", clear
keep if year==2019
keep statefips-mean Ctheil UStheil STtheil
replace mean=mean*1000
sum returns
local pop=`r(sum)'

quietly{
*** 1. Sanders Tax Plan 
// https://www.taxpolicycenter.org/publications/analysis-senator-sanderss-tax-proposals
// by 2021 cash income percentile

// create policy schedule assuming uniform distribution within quintile
preserve

xtile p=mean [fw=returns], nq(1000)	
replace p=p/10
	
gen ben20=170
gen ben40=480
gen ben60=1070
gen ben80=2220
gen ben90=4060
gen ben95=7060
gen ben99=22350
gen ben999=518190
gen ben1=3494650

gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean-policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\fig14_sandersT.png", replace
graph export "$output\fig14_sandersT.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_sandersSD.png", replace
graph export "$output\countysim_sandersSD.pdf", replace

/*gen dCcv=Ccv_policy-Ccv
sum dCcv
histogram dCcv, percent xtitle(Bernie Sanders 2020 Campaign Tax Proposals - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_sandersCV.png", replace
graph export "$output\countysim_sandersCV.pdf", replace*/
outreg2 using "$output\sanders_stats.xls", excel replace sum(log)
restore

*** 2. TCJA
// https://www.taxpolicycenter.org/publications/distributional-analysis-conference-agreement-tax-cuts-and-jobs-act/full
preserve

xtile p=mean [fw=returns], nq(1000)	
replace p=p/10

gen ben20=60
gen ben40=380
gen ben60=930
gen ben80=1810
gen ben90=2970
gen ben95=4550
gen ben99=13480
gen ben999=51140
gen ben1=193380
	
gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(TCJA - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcja.png", replace
graph export "$output\countysim_tcja.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(TCJA - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcjaSD.png", replace
graph export "$output\countysim_tcjaSD.pdf", replace

/*gen dCcv=Ccv_policy-Ccv
sum dCcv
histogram dCcv, percent xtitle(TCJA - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_tcjaCV.png", replace
graph export "$output\countysim_tcjaCV.pdf", replace*/
outreg2 using "$output\tcja_stats.xls", excel replace sum(log)
restore

// 3. Student debt forgiveness
*** Policy []: Student debt forgiveness - $50k with no cap***
// https://budgetmodel.wharton.upenn.edu/issues/2022/8/23/forgiving-student-loans
preserve
use "$data\inequality", clear
keep if year==2019
keep statefips-mean Ctheil UStheil STtheil
replace mean=mean*1000
local expenditure=820300000000		// amount of expenditure 
	//www.whitehouse.gov/briefing-room/statements-releases/2023/01/27/fact-sheet-biden-harris-administration-releases-new-data-showing-26-million-people-in-all-50-states-applied-or-were-automatically-eligible-for-one-time-student-debt-relief/
	// need to revise when add back agi stub 1
	// per capita transfer within percentiles
xtile p=mean [fw=returns], nq(1000)	
replace p=p/10
	
gen ben20=(`expenditure'*.10011)/(0.2*`pop')
gen ben40=(`expenditure'*.1837)/(0.2*`pop')
gen ben60=(`expenditure'*.2539)/(0.2*`pop')
gen ben80=(`expenditure'*.2650)/(0.2*`pop')
gen ben90=(`expenditure'*.1237)/(0.1*`pop')
gen ben95=(`expenditure'*.0493)/(0.05*`pop')
gen ben99=(`expenditure'*.0215)/(0.04*`pop')
gen ben999=(`expenditure'*.0025)/(0.009*`pop')
gen ben1=(`expenditure'*0)/(0.001*`pop')

gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(50k Student Debt Forgiveness - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebt.png", replace
graph export "$output\countysim_studebt.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(50k Student Debt Forgiveness - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebtSD.png", replace
graph export "$output\countysim_studebtSd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(50k Student Debt Forgiveness - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_studebtCV.png", replace
graph export "$output\countysim_studebtCV.pdf", replace*/
outreg2 using "$output\studebt_stats.xls", excel replace sum(log)
restore

// 4. Loan Payment Pause - current law
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=210000000000		// amount of expenditure 

xtile p=mean [fw=returns], nq(1000)	
replace p=p/10
	
gen ben20=(`expenditure'*.025)/(0.2*`pop')
gen ben40=(`expenditure'*.1030)/(0.2*`pop')
gen ben60=(`expenditure'*.2210)/(0.2*`pop')
gen ben80=(`expenditure'*.3520)/(0.2*`pop')
gen ben90=(`expenditure'*.1740)/(0.1*`pop')
gen ben95=(`expenditure'*.086)/(0.05*`pop')
gen ben99=(`expenditure'*.032)/(0.04*`pop')
gen ben999=(`expenditure'*.008)/(0.009*`pop')
gen ben1=(`expenditure'*0)/(0.001*`pop')

gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1.png", replace
graph export "$output\countysim_interest1.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1SD.png", replace
graph export "$output\countysim_interest1Sd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest1CV.png", replace
graph export "$output\countysim_interest1CV.pdf", replace*/

gen inc=(dCtheil>0)
save "$data\interest1.dta", replace

outreg2 using "$output\interest1_stats.xls", excel replace sum(log)
restore	

// 5. Loan Payment Pause - alternative 1
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=129000000000		// amount of expenditure 

xtile p=mean [fw=returns], nq(1000)	
replace p=p/10
	
gen ben20=(`expenditure'*.054)/(0.2*`pop')
gen ben40=(`expenditure'*.221)/(0.2*`pop')
gen ben60=(`expenditure'*.475)/(0.2*`pop')
gen ben80=(`expenditure'*.25)/(0.2*`pop')
gen ben90=(`expenditure'*0)/(0.1*`pop')
gen ben95=(`expenditure'*0)/(0.05*`pop')
gen ben99=(`expenditure'*0)/(0.04*`pop')
gen ben999=(`expenditure'*0)/(0.009*`pop')
gen ben1=(`expenditure'*0)/(0.001*`pop')

gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2.png", replace
graph export "$output\countysim_interest2.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2SD.png", replace
graph export "$output\countysim_interest2Sd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest2CV.png", replace
graph export "$output\countysim_interest2CV.pdf", replace*/
outreg2 using "$output\interest2_stats.xls", excel replace sum(log)
restore	

// 5. Loan Payment Pause - alternative 2
*https://budgetmodel.wharton.upenn.edu/estimates/2023/2/3/federal-student-loan-payment-pause

preserve
local expenditure=6100000000		// amount of expenditure 

xtile p=mean [fw=returns], nq(1000)	
replace p=p/10
	
local cut20=28784
local cut40=40795
local cut60=82400
local cut80=141096
local cut90=212209
local cut95=321699
local cut99=961711
local cut999=3668499

gen ben20=(`expenditure'*.136)/(0.2*`pop')
gen ben40=(`expenditure'*.455)/(0.2*`pop')
gen ben60=(`expenditure'*.393)/(0.2*`pop')
gen ben80=(`expenditure'*.017)/(0.2*`pop')
gen ben90=(`expenditure'*0)/(0.1*`pop')
gen ben95=(`expenditure'*0)/(0.05*`pop')
gen ben99=(`expenditure'*0)/(0.04*`pop')
gen ben999=(`expenditure'*0)/(0.009*`pop')
gen ben1=(`expenditure'*0)/(0.001*`pop')

gen policy=p*(ben20-0)/10 if p<=10
replace policy=ben20+(p-10)*(ben40-ben20)/(30-10) if p>10 & p<=30
replace policy=ben40+(p-30)*(ben60-ben40)/(50-30) if p>30 & p<=50
replace policy=ben60+(p-50)*(ben80-ben60)/(70-50) if p>50 & p<=70
replace policy=ben80+(p-70)*(ben90-ben80)/(85-70) if p>70 & p<=85
replace policy=ben90+(p-85)*(ben95-ben90)/(92.5-85) if p>85 & p<=92.5
replace policy=ben95+(p-92.5)*(ben99-ben95)/(97-92.5) if p>92.5 & p<=97
replace policy=ben99+(p-97)*(ben999-ben99)/(99.45-97) if p>97 & p<=99.5
replace policy=ben999+(p-99.5)*(ben1-ben999)/(1-99.45) if p>99.5

egen id=group(statefips countyfips)
sum id
gen Csd=.
gen Ccv=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd=`r(sd)' if id==`g'
	replace Ccv=`r(sd)'/`r(mean)' if id==`g'
}

replace mean=mean+policy

sum id
gen Csd_policy=.
gen Ccv_policy=.
forval g=1/`r(max)' {
	sum mean [w=returns] if id==`g'	
	replace Csd_policy=`r(sd)' if id==`g'
	replace Ccv_policy=`r(sd)'/`r(mean)' if id==`g'
}

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

bysort id: gen n=_n
keep if n==1
drop n
gen dCtheil=Ctheil_policy-Ctheil
sum dCtheil
histogram dCtheil, percent xtitle(Student Interest Pause - County Effects) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3.png", replace
graph export "$output\countysim_interest3.pdf", replace

gen dCsd=Csd_policy-Csd
sum dCsd
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (SD)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3SD.png", replace
graph export "$output\countysim_interest3Sd.pdf", replace

/*gen dCcv=(Csd_policy-Csd)/Csd
sum dCcv
histogram dCsd, percent xtitle(Student Interest Pause - County Effects (CV)) xlabel(,nogrid) ylabel(, nogrid) note("Data Source: IRS SOI") bins(100) xline(`r(mean)') 
graph export "$output\countysim_interest3CV.png", replace
graph export "$output\countysim_interest3CV.pdf", replace*/
outreg2 using "$output\interest3_stats.xls", excel replace sum(log)
restore	
}

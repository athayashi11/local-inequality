clear 
clear matrix
set more off
set graphics on

global output "..\Output"

clear
set obs 500000
gen x=rnormal(0,1)
gen income=round(exp(0.4*x)*70000,1)

xtile incq=income, nq(3)
bysort incq: sum

twoway kdensity income, xline(59000 83000) xtitle(Income) ytitle("") xlabel(30000 "Low" 74000 "Med" 130000 "Hi", nogrid) ylabel(none, nogrid)
graph export "$output\atkinson.png", replace
graph export "$output\atkinson.pdf", replace

sort income
egen mean_inc=mean(income)

ineqdeco income
gen ce1_all=-(`r(a1)'-1)*mean_inc
gen ce2_all=-(`r(a2)'-1)*mean_inc
gen a1_all=`r(a1)'

gen ce1=.
gen ce2=.
gen a1=.
	
bysort incq: egen qmean_inc=mean(income)
sum incq
forval q=1/`r(max)' {
	ineqdeco income if incq==`q'
	replace ce1=-(`r(a1)'-1)*qmean_inc if incq==`q'
	replace a1=`r(a1)' if incq==`q'
	replace ce2=-(`r(a2)'-1)*qmean_inc if incq==`q'
}

gen Dce1=qmean_inc-ce1
gen Dce2=qmean_inc-ce2

collapse (median) mean_inc-a1 qmean_inc-Dce2, by(incq)

egen meance1=mean(ce1)
egen meance2=mean(ce2)

*egen mean=mean(mean_inc)
// using uniform or log normal income and 2 equal groups (paritioning distribution) and a(1), amount preferred to inequality at national level not enough to pay off people to do it at local level.

// it becomes feasible when more inequality averse at local level

// surely if states are randomly selected, then certainty equivalents should be about the same. 




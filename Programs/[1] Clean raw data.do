clear 
clear matrix
set more off
*testing git
global counties "..\Datasets\SOI_County_Income"
global us "..\Datasets\SOI_National_Income"
global data "..\Datasets"
global output "..\Output"
set graphics on

*** [1] National Income Data ***
if "us"=="us" {
clear
tempfile n20
import excel "$us\20in54us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==26|_n==42	// header, number of returns, AGI, capital gains
destring C-L, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<13
gen year=2020
save `n20', replace

clear
tempfile n19
import excel "$us\19in54us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==25|_n==41
destring C-L, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<12
gen year=2019
save `n19', replace

clear
tempfile n18
import excel "$us\18in54us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==26|_n==42
destring C-L, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<13
gen year=2018
save `n18', replace

clear
tempfile n17
import excel "$us\17in53us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==26|_n==42
destring C-L, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<13
gen year=2017
save `n17', replace

foreach x in "15" "16" {
	clear
	tempfile n`x'
	import excel "$us\\`x'in53us.xlsx", sheet("Sheet1")
	keep if _n==4|_n==9|_n==24|_n==40
	destring C-L, replace force
	xpose, clear
	gen agi_stub=_n-2
	keep if _n>2 & _n<13
	gen year=20`x'
	save `n`x'', replace
}

clear
tempfile n14
import excel "$us\14in53us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==20|_n==36
destring C-L, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<13
gen year=2014
save `n14', replace

foreach x in "12" "13" { 
	clear
	tempfile n`x'
	import excel "$us\\`x'in53us.xlsx", sheet("Sheet1")
	keep if _n==4|_n==9|_n==16|_n==32
	destring C-L, replace force
	xpose, clear
	gen agi_stub=_n-2
	keep if _n>2 & _n<13
	gen year=20`x'
	save `n`x'', replace
}

clear
tempfile n11
import excel "$us\11in53us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==14|_n==30
destring C-K, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<12
gen year=2011
save `n11', replace

clear
tempfile n10
import excel "$us\10in53us.xlsx", sheet("Sheet1")
keep if _n==4|_n==9|_n==14|_n==30
destring C-K, replace force
xpose, clear
gen agi_stub=_n-2
keep if _n>2 & _n<12
replace v1=.
gen year=2010
save `n10', replace

use `n10'
foreach x in "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
	append using `n`x''
}
drop v1
rename v2 returns
rename v3 agi
rename v4 capgain
gen state="US"

// collapse $1-$10k and $10k-$25k stubs from 2012 to match $1-$25k stub in 2010/11
preserve
tempfile a
keep if year>2011 & inlist(agi_stub,2,3)
collapse (sum) returns agi capgain, by(state year)
gen agi_stub=2
save `a', replace
restore

drop if year>2011 & inlist(agi_stub,2,3)
append using `a'
sort year agi_stub
replace agi_stub=agi_stub-1 if year>2011 & inlist(agi_stub,4,5,6,7,8,9,10)

// collapse stubs 7-9 to conform to top state stub: $200k+ 
preserve
tempfile b
keep if inlist(agi_stub,7,8,9)
collapse (sum) returns agi capgain, by(state year)
gen agi_stub=7
save `b', replace
restore

drop if inlist(agi_stub,7,8,9)
append using `b'
sort year agi_stub
gen id=9999

/*2010-2020
1 = Under $1
2 = $1 under $25,000
3 = $25,000 under $50,000
4 = $50,000 under $75,000
5 = $75,000 under $100,000
6 = $100,000 under $200,000
7 = $200,000 or more*/

save "$data\usa", replace
}

*** [2] County Income Data ***

// County Data
if "counties"=="counties" {
foreach x in "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" { 
	tempfile y`x'
	clear
	import delimited "$counties\20`x'countyincome\\`x'incyallagi.csv"					 	
	gen year=20`x'
	save `y`x'', replace
}
use `y10'
foreach x in "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" {
	append using `y`x''
}
keep statefips state countyfips countyname agi_stub n1 a00100 year a01000
rename n1 returns
rename a00100 agi
rename a01000 capgain

egen id=group(statefips countyfips)

// collapse $1-$10k and $10k-$25k stubs from 2012 to match $1-$25k stub in 2010/11
preserve
tempfile a
keep if year>2011 & inlist(agi_stub,2,3)
collapse (sum) returns agi capgain (median) id statefips countyfips, by(state countyname year)
gen agi_stub=2
save `a', replace
restore

drop if year>2011 & inlist(agi_stub,2,3)
append using `a'
sort id year agi_stub
replace agi_stub=agi_stub-1 if year>2011 & inlist(agi_stub,4,5,6,7,8)

/* AGI stubs
2010-2020
0 = No AGI Stub
1 = `Under $1'
2 = '$1 under $25,000'
3 = $25,000 under $50,000
4 = $50,000 under $75,000
5 = $75,000 under $100,000
6 = $100,000 under $200,000
7 = $200,000 or more*/

save "$data\statescounties", replace	
}

*** Add nonfilers
use "$data\statescounties", clear
//take 2020 data on EIP mailings to nonfilers by state and allocate to counties based on share of state poverty
//https://www.irs.gov/newsroom/irs-releases-state-by-state-breakdown-of-nearly-9-million-non-filers-who-will-be-mailed-letters-about-economic-impact-payments
//https://www.cbpp.org/research/poverty-and-inequality/a-guide-to-statistics-on-historical-trends-in-income-inequality

clear
tempfile a
import excel "$data\state nonfilers.xlsx", sheet("Sheet1")
keep if _n>3
destring C, replace
rename C missing
rename A state
save `a', replace

clear
import excel "$data\Poverty-Rates-by-County-1960-2010.xlsm", sheet("Data")
rename C state
rename V persons_poverty
keep if _n>3
destring B, replace
gen fips=string(B,"%05.0f")
gen countyfips=substr(fips,3,3)
gen statefips=substr(fips,1,2)
destring countyfips, replace 
destring statefips, replace
destring persons_poverty, replace
replace statefips=countyfips if D=="State Total"
replace countyfips=0 if D=="State Total"
bysort state: egen poverty=sum(persons_poverty) if D!="State Total"
replace poverty=persons_poverty if D=="State Total"
gen poverty_share=persons_poverty/poverty
keep countyfips statefips state poverty_share
merge m:1 state using `a', keep(3) nogen

gen nonfilers=round(0.8*missing*poverty_share,1)		// assume 40% married filing jointly
gen agi_nonfilers=round(nonfilers*(12.4*0.6+24.8*0.2)/2,1)	// using 2019 standard deduction and assum uniform income distribution. Assume poverty pop is constant over time

keep countyfips statefips nonfilers agi_nonfilers
gen agi_stub=2
merge 1:m statefips countyfips agi_stub using "$data\statescounties", nogen keep(2 3)
replace returns=returns+nonfilers if agi_stub==2 & nonfilers!=. 
replace agi=agi+agi_nonfilers if agi_stub==2 & agi_nonfilers!=.
save "$data\statescounties", replace	

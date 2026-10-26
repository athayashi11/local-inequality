clear 
clear matrix
set more off

global data "C:\Users\ath9f\Dropbox\2024 Inequality Spheres\Programs\Simulations"
*global output "..\Output"
set graphics on

set obs 10
gen theta_a=0.5
gen rho=-10
gen sigma=1/(rho-1)
gen delta=rho*sigma
gen p2=_n/10
gen e1=1
gen e2=1

gen n=(theta^sigma)/((1+e1)*((theta^sigma)+(p2^delta))-delta*(p2^delta))
gen d=(theta^(-sigma))/((1+e2)*((theta^(-sigma))+(p2^(-delta)))-delta*(p2^(-delta)))
gen x=n+d

/*
// What is the effect of a 1% change in B's income on A's expenditure needed to achieve some amount of utility?

set obs 6
gen theta_a=(_n-1)/5
expand 6
bysort theta: gen theta_b=(_n-1)/5
expand 11
bysort theta_a theta_b: gen rho_a=(_n-8)/4
expand 11
bysort theta_a theta_b rho_a: gen r=(_n-8)/4

// Case 1: Same City - Different Utilities


// Case 2: Different Cities



expand 5
bysort theta t e2 e1 rho r: gen c=_n

bysort theta_a theta_b: gen e2=_n
expand 6
bysort theta t e2: gen e1=_n
expand 11

gen p1=.10 if c==1
	replace p1=.50 if c==2
	replace p1=1 if c==3
	replace p1=2 if c==4
	replace p1=10 if c==5
	drop c
expand 5
bysort theta t e2 e1 rho r p1: gen c=_n
gen p3=.10 if c==1
	replace p3=.50 if c==2
	replace p3=1 if c==3
	replace p3=2 if c==4
	replace p3=10 if c==5
	drop c

gen sigma=1/(rho-1)
gen delta=rho*sigma
gen s=1/(r-1)
gen d=r*s
*/

// looks like effect of 1% change in B's income has <1% effect on A's income when in different cities. 

set obs 1
gen theta=0.9
gen rho=-5
gen sigma=1/(rho-1)
gen delta=rho*sigma
gen p1=.00001

gen e2=1
gen p3=1000

gen r=-100
gen s=1/(r-1)
gen d=r*s

gen c=d*(t^s)*(p3^d)/(1+(t^s)*(p3^d))

gen first=(theta^(-sigma))/((p1^delta)+(theta^(-sigma)))

gen second=1+e2-d*(t^s)*(p3^d)/(1+(t^s)*(p3^d))

gen z=first/second // a 1% increase in B's income requires a more than 1% increase in A's income to stay at the same utility levels

gen e1=1

gen third=1-(e1+1)*(theta^sigma)/delta

gen fourth=(p1^delta)/((p1^delta)+(theta^(-sigma)))

gen w=fourth/(second*third)

gen all=z+w

*sum 
*count if all>1 & all<.
*/
/*set obs 6
gen theta=(_n-1)/10
expand 11
bysort theta: gen t=(_n-1)/10
expand 11
bysort theta t: gen e2=(_n-1)/2
expand 11
bysort theta t e2: gen e1=(_n-1)/2
expand 11
bysort theta t e2 e1: gen rho=(_n-8)/4
expand 11
bysort theta t e2 e1 rho: gen r=(_n-8)/4
expand 5
bysort theta t e2 e1 rho r: gen c=_n
gen p1=.10 if c==1
	replace p1=.50 if c==2
	replace p1=1 if c==3
	replace p1=2 if c==4
	replace p1=10 if c==5
	drop c
expand 5
bysort theta t e2 e1 rho r p1: gen c=_n
gen p3=.10 if c==1
	replace p3=.50 if c==2
	replace p3=1 if c==3
	replace p3=2 if c==4
	replace p3=10 if c==5
	drop c

gen sigma=1/(rho-1)
gen delta=rho*sigma
gen s=1/(r-1)
gen d=r*s

gen first=(theta^(-sigma))/((p1^delta)+(theta^(-sigma)))
gen second=1+e2-d*(t^s)*(p3^d)/(1+(t^s)*(p3^d))

gen z=first/second // a 1% increase in B's income requires a more than 1% increase in A's income to stay at the same utility levels

gen third=1-(e1+1)*(theta^sigma)/delta
gen fourth=(p1^delta)/((p1^delta)+(theta^(-sigma)))

gen w=fourth/(second*third)

gen all=z+w


gen rho=0.8 // (can be positive or negative)
gen sigma=1/(rho-1)
gen delta=rho*sigma
gen p1=.05

gen first=(theta^(-sigma))/((p1^delta)+(theta^(-sigma)))

gen e2=0
gen r=-1
gen s=1/(r-1)
gen d=r*s
gen t=1
gen p3=100

gen second=1+e2-d*(t^s)*(p3^d)/(1+(t^s)*(p3^d))

gen z=first/second // a 1% increase in B's income requires a more than 1% increase in A's income to stay at the same utility levels

gen e1=0

gen third=1-(e1+1)*(theta^sigma)/delta
gen fourth=(p1^delta)/((p1^delta)+(theta^(-sigma)))

gen w=fourth/(second*third)

gen all=z+w*/

/*

gen t1=(theta^(-sigma))/(p1^(rho*sigma)+theta^(-sigma))

gen f=(t^s)*(p3^(r*s))
gen t2=(1+e2-r*s*f/(1+f))^(-1)
gen v=t1*t2

gen t3=(1-((e1+1)*theta^sigma)/(rho*sigma))^(-1)
gen t4=(p1^(rho*sigma))/(p1^(rho*sigma)+theta^(-sigma))

gen w=t2*t3*t4

gen z=v+w

*line v e1

// calculation of individual utility as function of p2
/*set obs 10
gen m=100
gen p1=5
gen p2=_n
gen theta=0.8
gen rho=-1
gen sigma=1/(rho-1)

gen x1=m/(p1*(1+(theta^(-sigma))*((p2/p1)^(rho*sigma))))
gen x2=m/(p2*(1+(theta^(sigma))*((p1/p2)^(rho*sigma))))
gen v=(x1^rho+theta*x2^rho)^(1/(rho))
twoway (line x1 p2) (line x2 p2) (line v p2)*/

// Using the model in Dropbox, solving for the equilbrium prices 
/*
// Residents of the same city
quietly {
set obs 1
gen theta=.
gen rho=.
gen sigma=.
gen m_a=.
gen m_b=.
gen m=.
gen alpha1=.
gen alpha2=.
save "$data\temp.dta", replace

forval alpha1=1/2 {

foreach rho in "-1" "0.8" {
	
foreach theta in "0.8" "1" "1.2" {

forval m_a=4/6 {

noisily display "alpha1=`alpha1' and rho=`rho' and theta=`theta' and ma=`m_a'"

clear
set obs 5000000
gen theta=`theta'
gen rho=`rho'
gen sigma=1/(rho-1)
gen m_a=`m_a'
gen m_b=5
gen m=m_a+m_b
gen alpha1=`alpha1'
gen alpha2=2

gen p1=_n/1000000
gen p2=(theta^(1/rho))*((m/alpha1)*p1^(sigma-1)-p1^(rho*sigma))^(1/(rho*sigma))

gen supply1=alpha1*p1
gen demand1=m/(p1*(1+(theta^(-sigma))*(p2/p1)^(rho*sigma)))
gen supply2=alpha2*p2
gen demand2=m/(p2*(1+(theta^(sigma))*(p1/p2)^(rho*sigma)))
gen d1=abs(supply1-demand1)
gen d2=abs(supply2-demand2)
sort d1 d2
keep if _n==1

append using "$data\temp.dta"
save "$data\temp.dta", replace

}

}

}

}

}

use "$data\temp.dta", clear
gen x1_a=m_a/(p1*(1+(theta^(-sigma))*(p2/p1)^(rho*sigma)))
gen x2_a=m_a/(p2*(1+(theta^(sigma))*(p1/p2)^(rho*sigma)))
gen u_a=((x1_a^rho)+theta*(x2_a^rho))^(1/rho)
gen x1_b=m_b/(p1*(1+(theta^(-sigma))*(p2/p1)^(rho*sigma)))
gen x2_b=m_b/(p2*(1+(theta^(sigma))*(p1/p2)^(rho*sigma)))
gen u_b=((x1_b^rho)+theta*(x2_b^rho))^(1/rho)
gen income_ratio=m_a/m_b
gen income_diff=m_a-m_b
gen utility_ratio=u_a/u_b
gen utility_diff=u_a-u_b

egen g=group(theta rho alpha1)
scatter u_b m_a if g==10 
save "$data\simulation.dta", replace


// Residents of separate cities

set obs 1
gen theta_a=.
gen theta_b=.
gen rho_a=.
gen rho_b=.
gen sigma_a=.
gen sigma_b=.
gen m_a=.
gen m_b=.
gen m=.
gen alpha1=.
gen alpha2=.
gen alpha3=.
save "$data\temp2.dta", replace

forval alpha1=1/1 {
forval alpha3=1/1 {

foreach rhoa in "0.8" {
foreach rhob in "0.8" {

foreach thetaa in "1" {
foreach thetab in "1" {
	
forval m_a=10/10 {

*noisily display "alpha1=`alpha1' and rho=`rho' and theta=`theta' and ma=`m_a'"

clear
set obs 100
gen theta_a=`thetaa'
gen theta_b=`thetab'
gen rho_a=`rhoa'
gen rho_b=`rhob'
gen sigma_a=1/(rho_a-1)
gen sigma_b=1/(rho_b-1)
gen m_a=`m_a'
gen m_b=10
gen m=m_a+m_b
gen alpha1=`alpha1'
gen alpha2=1
gen alpha3=`alpha3'

gen p1=_n/10
expand 100
bysort p1: gen p2=_n/10
expand 100
bysort p1 p2: gen p3=_n/10

gen supply1=alpha1*p1
gen supply2=alpha2*p2
gen supply3=alpha3*p3

gen demand1=m_a/(p1*(1+(theta_a^(-sigma_a))*((p2/p1)^(rho_a*sigma_a))))
gen demand2=m_a/(p2*(1+(theta_a^(sigma_a))*((p1/p2)^(rho_a*sigma_a))))+m_b/(p2*(1+(theta_b^(sigma_b))*((p3/p2)^(rho_b*sigma_b))))
gen demand3=m_b/(p3*(1+(theta_b^(-sigma_b))*((p2/p3)^(rho_b*sigma_b))))

gen d1=abs(supply1-demand1)
gen d2=abs(supply2-demand2)
gen d3=abs(supply3-demand3)
gen d=d1+d2+d3
sort d
*keep if _n==1

append using "$data\temp2.dta"
save "$data\temp2.dta", replace

}
}
}
}
}
}
}

/*
use "$data\temp2.dta", clear
gen x1_a=m_a/(p1*(1+(theta^(-sigma))*(p2/p1)^(rho*sigma)))
gen x2_a=m_a/(p2*(1+(theta^(sigma))*(p1/p2)^(rho*sigma)))
gen u_a=((x1_a^rho)+theta*(x2_a^rho))^(1/rho)
gen x1_b=m_b/(p1*(1+(theta^(-sigma))*(p2/p1)^(rho*sigma)))
gen x2_b=m_b/(p2*(1+(theta^(sigma))*(p1/p2)^(rho*sigma)))
gen u_b=((x1_b^rho)+theta*(x2_b^rho))^(1/rho)
gen income_ratio=m_a/m_b
gen income_diff=m_a-m_b
gen utility_ratio=u_a/u_b
gen utility_diff=u_a-u_b

egen g=group(theta rho alpha1)
scatter u_b m_a if g==10 
save "$data\simulation2.dta", replace*/
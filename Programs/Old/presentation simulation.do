clear
* incomes of 10, 50, 100

// county
set obs 4
gen income=10
insobs 3
replace income=50 if income==.
gen county=1

// state
insobs 1
replace income=10 if income==.
insobs 6
replace income=50 if income==.
insobs 3
replace income=500 if income==.
gen state=1 

// country
insobs 5
replace income=10 if income==.
insobs 7
replace income=500 if income==.
gen country=1

ineqdeco income if county==1
ineqdeco income if state==1
ineqdeco income if country==1

count if income==500
count if income==50

replace income=491 if income==500
replace income=60 if income==50

ineqdeco income if county==1
ineqdeco income if state==1
ineqdeco income if country==1

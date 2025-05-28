*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* descriptive_table.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file creates some variable recodes and Table 1: Descriptive statistics

use "$SIPP14keep/annual_bw_status2014.dta", clear // created in step 10

********************************************************************************
* CREATE SAMPLE AND VARIABLES
********************************************************************************

* Create dependent variable: income / pov change change
gen inc_pov = thearn_alt / threshold
sort SSUID PNUM year
by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen in_pov=.
replace in_pov=0 if inc_pov>=1.5 & inc_pov!=.
replace in_pov=1 if inc_pov <1.5

gen inc_pov_lag = inc_pov[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen pov_lag=.
replace pov_lag=0 if inc_pov_lag>=1.5 & inc_pov_lag!=.
replace pov_lag=1 if inc_pov_lag <1.5

* poverty change outcome to use
gen pov_change=.
replace pov_change=0 if in_pov==pov_lag
replace pov_change=1 if in_pov==1 & pov_lag==0
replace pov_change=2 if in_pov==0 & pov_lag==1

label define pov_change 0 "No" 1 "Moved into" 2 "Moved out of"
label values pov_change pov_change

gen pov_change_detail=.
replace pov_change_detail=1 if in_pov==0 & pov_lag==1 // moved out of poverty
replace pov_change_detail=2 if in_pov==pov_lag & pov_lag==0 // stayed out of poverty
replace pov_change_detail=3 if in_pov==pov_lag & pov_lag==1 // stay IN poverty
replace pov_change_detail=4 if in_pov==1 & pov_lag==0 // moved into

label define pov_change_detail 1 "Moved Out" 2 "Stayed out" 3 "Stayed in" 4 "Moved in"
label values pov_change_detail pov_change_detail

// 3 buckets we created for FAMDEM
gen inc_pov_summary=.
replace inc_pov_summary=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=.
replace inc_pov_summary=4 if inc_pov_change_raw==0

label define summary 1 "Up, Above Pov" 2 "Up, Not above pov" 3 "Down" 4 "No Change"
label values inc_pov_summary summary

// Breaking out income down to above v. below poverty
gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

// some lagged measures I need
sort SSUID PNUM year
gen earnings_lag = earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen thearn_lag = thearn_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

* Creating necessary independent variables
 // one variable for all pathways
egen validate = rowtotal(mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes) // make sure moms only have 1 event
browse SSUID PNUM validate mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes trans_bw60_alt2 bw60_mom

gen pathway_v1=0
replace pathway_v1=1 if mt_mom==1
replace pathway_v1=2 if ft_partner_down_mom==1
replace pathway_v1=3 if ft_partner_down_only==1
replace pathway_v1=4 if ft_partner_leave==1
replace pathway_v1=5 if lt_other_changes==1

label define pathway_v1 0 "None" 1 "Mom Up" 2 "Mom Up Partner Down" 3 "Partner Down" 4 "Partner Left" 5 "Other HH Change"
label values pathway_v1 pathway_v1

// more detailed pathway
gen start_from_0 = 0
replace start_from_0=1 if earnings_lag==0

gen hh_from_0 = 0
replace hh_from_0 = 1 if thearn_lag==0

gen pathway=0
replace pathway=1 if mt_mom==1 & start_from_0==1
replace pathway=2 if mt_mom==1 & start_from_0==0
replace pathway=3 if ft_partner_down_mom==1
replace pathway=4 if ft_partner_down_only==1
replace pathway=5 if ft_partner_leave==1
replace pathway=6 if lt_other_changes==1

label define pathway 0 "None" 1 "Mom Up, Not employed" 2 "Mom Up, employed" 3 "Mom Up Partner Down" 4 "Partner Down" 5 "Partner Left" 6 "Other HH Change"
label values pathway pathway

// program variables
gen tanf=0
replace tanf=1 if tanf_amount > 0

// need to get tanf in year prior and then eitc in year after - but this is not really going to work for 2016, so need to think about that
sort SSUID PNUM year
browse SSUID PNUM year rtanfcov tanf tanf_amount program_income eeitc
gen tanf_lag = tanf[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen tanf_amount_lag = tanf_amount[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen program_income_lag = program_income[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen eitc_after = eeitc[_n+1] if SSUID==SSUID[_n+1] & PNUM==PNUM[_n+1] & year==(year[_n+1]-1)

replace earnings_ratio=0 if earnings_ratio==. & earnings==0 & thearn_alt > 0 // wasn't counting moms with 0 earnings -- is this an issue elsewhere?? BUT still leaving as missing if NO earnings. is that right?
gen earnings_ratio_alt=earnings_ratio
replace earnings_ratio_alt=0 if earnings_ratio_alt==. // count as 0 if no earnings (instead of missing)

gen earnings_ratio_lag = earnings_ratio[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen earnings_ratio_alt_lag = earnings_ratio_alt[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)

gen zero_earnings=0
replace zero_earnings=1 if earnings_lag==0

// last_status
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr
recode marital_status_t1 (1/2=1)(3=0), gen(partnered_t1)

// first_status
recode start_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t)
label values marital_status_t marr
recode marital_status_t (1/2=1)(3=0), gen(partnered_t)

// race recode
recode race (1=1) (2=2)(4=3)(3=4)(5=4), gen(race_gp)
label define race_gp 1 "White" 2 "Black" 3 "Hispanic"
label values race_gp race_gp

// education recode
recode educ (1/2=1) (3=2) (4=3), gen(educ_gp)
label define educ_gp 1 "Hs or Less" 2 "Some College" 3 "College Plus"
label values educ_gp educ_gp

// age at first birth recode
recode ageb1 (-5/19=1) (20/24=2) (25/29=3) (30/55=4), gen(ageb1_cat)
label define ageb1_cat 1 "Under 20" 2 "A20-24" 3 "A25-29" 4 "Over 30"
label values ageb1_cat ageb1_cat

// marital status recode
recode marital_status_t1 (1/2=1)(3=0), gen(partnered)
recode partnered (0=1)(1=0), gen(single)

// household income change
by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_alt-thearn_alt[_n-1])/thearn_alt[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_alt-thearn_alt[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_alt bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_alt-thearn_alt[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
	
inspect hh_income_raw // almost split 50/50 negative v. positive
sum hh_income_raw, detail // i am now wondering - is this the better way to do it?
gen hh_chg_value=.
replace hh_chg_value = 0 if hh_income_raw <0
replace hh_chg_value = 1 if hh_income_raw >0 & hh_income_raw!=.
tab hh_chg_value
sum hh_income_raw if hh_chg_value==0, detail
sum hh_income_raw if hh_chg_value==1, detail

gen end_as_sole=0
replace end_as_sole=1 if earnings_ratio==1

gen partner_zero=0
replace partner_zero=1 if end_partner_earn==0
tab pathway partner_zero, row

** use the single / partnered I created before: single needs to be ALL YEAR
gen single_all=0
replace single_all=1 if partnered_t==0 & no_status_chg==1

gen partnered_all=0
replace partnered_all=1 if partnered_t==1 | single_all==0

gen partnered_no_chg=0
replace partnered_no_chg=1 if partnered_t==1 & no_status_chg==1

gen relationship=.
replace relationship=1 if start_marital_status==1 & partnered_all==1 // married
replace relationship=2 if start_marital_status==2 & partnered_all==1 // cohab
label values relationship marr

gen rel_status=.
replace rel_status=1 if single_all==1
replace rel_status=2 if partnered_all==1
label define rel 1 "Single" 2 "Partnered"
label values rel_status rel

gen rel_status_detail=.
replace rel_status_detail=1 if single_all==1
replace rel_status_detail=2 if partnered_no_chg==1
replace rel_status_detail=3 if pathway==5 // why was this 4 at one point (which was partner down) did I change this?
replace rel_status_detail=2 if partnered_all==1 & rel_status_detail==.

label define rel_detail 1 "Single" 2 "Partnered" 3 "Dissolved"
label values rel_status_detail rel_detail

// add BW at birth to get descriptives.
tab bw60_mom if firstbirth==1 & mom_panel==1
gen bw_at_birth = 0
replace bw_at_birth = 1 if bw60_mom==1 & firstbirth==1 & mom_panel==1

// add continuous BW to get descriptives
by SSUID PNUM: egen years_in_sipp = count(year)

by SSUID PNUM: egen years_eligible = count(year) if bw60!=.
bysort SSUID PNUM (years_eligible): replace years_eligible=years_eligible[1]

by SSUID PNUM: egen years_bw = count(year) if bw60==1
bysort SSUID PNUM (years_bw): replace years_bw=years_bw[1]
replace years_bw=0 if years_bw==.

gen always_bw = 0
replace always_bw = 1 if years_bw==years_eligible

sort SSUID PNUM year
browse SSUID PNUM year always_bw years_in_sipp years_eligible years_bw

* Get percentiles
//browse SSUID year bw60 bw60lag

sum thearn_alt if year==(year[_n+1]-1) & SSUID[_n+1]==SSUID  [aweight=wpfinwgt], detail // is this t-1? this is in demography paper
sum thearn_alt, detail // then this would be t?
sum thearn_alt if bw60lag==0, detail // is this t-1?
sum thearn_alt if bw60==1, detail // is this t? okay definitely not

xtile percentile = thearn_alt, nq(10)

forvalues p=1/10{
	sum thearn_alt if percentile==`p'
}

/*
1 0 		4942
2 4950 		18052
3 18055		28058
4 28061		38763
5 38769		51120
6 51136		65045
7 65051		82705
8 82724		107473
9 107478	151012
10 151072	2000316
*/

gen pre_percentile=. // okay duh a lot of missing because thearn_lag not there for everyone
replace pre_percentile=1 if thearn_lag>=0 & thearn_lag<= 4942
replace pre_percentile=2 if thearn_lag>= 4950 & thearn_lag<= 18052
replace pre_percentile=3 if thearn_lag>= 18055 & thearn_lag<= 28058
replace pre_percentile=4 if thearn_lag>= 28061	& thearn_lag<=38763
replace pre_percentile=5 if thearn_lag>= 38769 & thearn_lag<= 51120
replace pre_percentile=6 if thearn_lag>= 51136	& thearn_lag<=	65045
replace pre_percentile=7 if thearn_lag>= 65051	& thearn_lag<=	82705
replace pre_percentile=8 if thearn_lag>= 82724	& thearn_lag<=	107473
replace pre_percentile=9 if thearn_lag>= 107478	& thearn_lag<=151012
replace pre_percentile=10 if thearn_lag>= 151072 & thearn_lag<= 2000316

gen post_percentile=.
replace post_percentile=1 if thearn_alt>=0 & thearn_alt<= 4942
replace post_percentile=2 if thearn_alt>= 4950 & thearn_alt<= 18052
replace post_percentile=3 if thearn_alt>= 18055 & thearn_alt<= 28058
replace post_percentile=4 if thearn_alt>= 28061	& thearn_alt<=38763
replace post_percentile=5 if thearn_alt>= 38769 & thearn_alt<= 51120
replace post_percentile=6 if thearn_alt>= 51136	& thearn_alt<=	65045
replace post_percentile=7 if thearn_alt>= 65051	& thearn_alt<=	82705
replace post_percentile=8 if thearn_alt>= 82724	& thearn_alt<=	107473
replace post_percentile=9 if thearn_alt>= 107478	& thearn_alt<=151012
replace post_percentile=10 if thearn_alt>= 151072 & thearn_alt<= 2000316

gen percentile_chg = post_percentile-pre_percentile

* other income measures
gen income_change=.
replace income_change=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. // up
replace income_change=2 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. // down
label define income 1 "Up" 2 "Down"
label values income_change income

// drop if inlist(status_b1, 3,4) 

// topcode income change to stabilize outliers - use 1% / 99% or 5% / 95%? should I topcode here or once I restrict sample?
sum hh_income_raw_all, detail
gen hh_income_topcode=hh_income_raw_all
replace hh_income_topcode = `r(p5)' if hh_income_raw_all<`r(p5)'
replace hh_income_topcode = `r(p95)' if hh_income_raw_all>`r(p95)'

gen income_chg_top = hh_income_topcode / thearn_lag

// browse SSUID thearn_alt thearn_lag hh_income_raw_all hh_income_topcode hh_income_chg income_chg_top
sum hh_income_chg, detail
sum income_chg_top, detail

gen hh_income_pos = hh_income_raw_all 
replace hh_income_pos = hh_income_raw_all *-1 if hh_income_raw_all<0
gen log_income = ln(hh_income_pos) // ah does not work with negative numbers
gen log_income_change = log_income
replace log_income_change = log_income*-1 if hh_income_raw_all<0
browse hh_income_raw_all hh_income_pos log_income log_income_change

// adding info on HH composition (created file 10 in 2014 folder) 
merge 1:1 SSUID PNUM year using "$tempdir/household_lookup.dta"
drop if _merge==2
drop _merge

// mother employed at t0
gen employed_t0=0
replace employed_t0=1 if start_from_0==0

// keep if trans_bw60_alt2==1 & bw60lag==0 - want to get comparison to mothers who are NOT the primary earner

sum avg_hhsize if trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if rel_status_detail==1 & trans_bw60_alt2==1 & bw60lag==0 // single
sum avg_hhsize if rel_status_detail==2 & trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if rel_status_detail==3 & trans_bw60_alt2==1 & bw60lag==0
sum avg_hhsize if trans_bw60_alt2==0 & bw60lag==0

sum st_minorchildren if trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if rel_status_detail==1 & trans_bw60_alt2==1 & bw60lag==0 // single
sum st_minorchildren if rel_status_detail==2 & trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if rel_status_detail==3 & trans_bw60_alt2==1 & bw60lag==0
sum st_minorchildren if trans_bw60_alt2==0 & bw60lag==0

// want t0 info
browse SSUID PNUM year marital_status_t marital_status_t1 extended_hh trans_bw60_alt2 if bw60lag==0

sort SSUID PNUM year
gen marital_status_t0 = .
replace marital_status_t0 = marital_status_t1[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

gen extended_hh_t0 = .
replace extended_hh_t0 = extended_hh[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

tab marital_status_t1 if trans_bw60_alt2==1 & bw60lag==0, m
tab marital_status_t0 if trans_bw60_alt2==1 & bw60lag==0, m

tab extended_hh if trans_bw60_alt2==1 & bw60lag==0, m
tab extended_hh_t0 if trans_bw60_alt2==1 & bw60lag==0, m

browse SSUID PNUM year marital_status_t1 marital_status_t0 extended_hh extended_hh_t0 trans_bw60_alt2 if bw60lag==0
browse SSUID PNUM year partnered_t1 earnings earnings_lag earnings_sp earnings_a_sp trans_bw60_alt2 trans_bw60_alt2 if bw60lag==0
gen partner_earnings=.
replace partner_earnings = 0 if earnings_a_sp==0
replace partner_earnings = 1 if earnings_a_sp!=0 & earnings_a_sp!=.
tab partnered_t1 partner_earnings, m

gen partner_earnings_t0 = .
replace partner_earnings_t0 = partner_earnings[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

tab educ_gp, gen(educ_gp)
tab race_gp, gen(race_gp)
tab race, gen(race)
tab marital_status_t1, gen(marst)
tab marital_status_t0, gen(marst_0)
tab pathway, gen(pathway)

unique SSUID PNUM if trans_bw60_alt2==1 & bw60lag==0
unique SSUID PNUM if bw60lag==0


********************************************************************************
**# Descriptive statistics
********************************************************************************
putexcel set "$results/Breadwinner_Heterogeneity", sheet(Table1) replace
putexcel A1 = "Descriptive Statistics", border(bottom) hcenter bold
putexcel B1 = "Total Sample"
putexcel C1 = "Non-Primary-Earning Mothers"
putexcel D1 = "All Eligible Mothers"
putexcel E1 = "Transition Rate"

putexcel A2 = "Median HH income at time t-1"
putexcel A3 = "Mothers' median income at time t-1 (employed mothers only)"
putexcel A4 = "Race/ethnicity (time-invariant)"
putexcel A5 = "Non-Hispanic White", txtindent(4)
putexcel A6 = "Black", txtindent(4)
putexcel A7 = "Non-Hispanic Asian", txtindent(4)
putexcel A8 = "Hispanic", txtindent(4)
putexcel A9 = "Education (time-varying)"
putexcel A10 = "HS Degree or Less", txtindent(4)
putexcel A11 = "Some College", txtindent(4)
putexcel A12 = "College Plus", txtindent(4)
putexcel A13 = "Relationship Status (time-varying)"
putexcel A14 = "Married", txtindent(4)
putexcel A15 = "Cohabitating", txtindent(4)
putexcel A16 = "Single", txtindent(4)
putexcel A17 = "Potential Event Pathway"
putexcel A18 = "Mom Up, Unemployed", txtindent(4)
putexcel A19 = "Mom Up, Employed", txtindent(4)
putexcel A20 = "Mom Up Partner Down", txtindent(4)
putexcel A21 = "Partner Down", txtindent(4)
putexcel A22 = "Partner Exit", txtindent(4)
putexcel A23 = "Other HH Change", txtindent(4)
putexcel A24 = "TANF in Year Prior", txtindent(4)
putexcel A25 = "EITC in Year Prior", txtindent(4)

// Income 
* HH
sum thearn_lag if trans_bw60_alt2==1 & bw60lag==0, detail
putexcel B2=`r(mean)', nformat(###,###)
sum thearn_lag if trans_bw60_alt2==0 & bw60lag==0, detail
putexcel C2=`r(mean)', nformat(###,###)
sum thearn_lag if bw60lag==0, detail
putexcel D2=`r(mean)', nformat(###,###)

*Mother
sum earnings_lag if earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0, detail 
putexcel B3=`r(mean)', nformat(###,###)
sum earnings_lag if earnings_lag!=0 & trans_bw60_alt2==0 & bw60lag==0, detail 
putexcel C3=`r(mean)', nformat(###,###)
sum earnings_lag if earnings_lag!=0 & bw60lag==0, detail 
putexcel D3=`r(mean)', nformat(###,###)


// Distributions
* Race
local i=1

foreach var in race1 race2 race3 race4{
	local row = `i'+4
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_nobw = e(b)
	putexcel C`row' = matrix(`var'_nobw), nformat(#.##%)
	mean `var' if bw60lag==0 [aweight=scaled_weight]
	matrix `var'_all = e(b)
	putexcel D`row' = matrix(`var'_all), nformat(#.##%)
	local ++i
}
		

* Education

local i=1

foreach var in educ_gp1 educ_gp2 educ_gp3{
	local row = `i'+9
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_nobw = e(b)
	putexcel C`row' = matrix(`var'_nobw), nformat(#.##%)
	mean `var' if bw60lag==0 [aweight=scaled_weight]
	matrix `var'_all = e(b)
	putexcel D`row' = matrix(`var'_all), nformat(#.##%)
	local ++i
}
		
	
* Marital Status - December
local i=1

foreach var in marst1 marst2 marst3{
	local row = `i'+13
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_nobw = e(b)
	putexcel C`row' = matrix(`var'_nobw), nformat(#.##%)
	mean `var' if bw60lag==0 [aweight=scaled_weight]
	matrix `var'_all = e(b)
	putexcel D`row' = matrix(`var'_all), nformat(#.##%)
	local ++i
}

* Pathway into breadwinning

local i=1
// ft_partner_leave mt_mom ft_partner_down_only ft_partner_down_mom lt_other_changes

foreach var in pathway2 pathway3 pathway4 pathway5 pathway6 pathway7{
	local row = `i'+17
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight] // remove svy to see if matches paper 1
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_nobw = e(b)
	putexcel C`row' = matrix(`var'_nobw), nformat(#.##%)
	mean `var' if bw60lag==0 [aweight=scaled_weight]
	matrix `var'_all = e(b)
	putexcel D`row' = matrix(`var'_all), nformat(#.##%)
	local ++i
}

* Welfare receipt
local i=1
foreach var in tanf_lag eeitc{
	local row = `i'+23
	mean `var' if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight] // remove svy to see if matches paper 1
	matrix `var'_bw14 = e(b)
	putexcel B`row' = matrix(`var'_bw14), nformat(#.##%)
	mean `var' if trans_bw60_alt2==0 & bw60lag==0 [aweight=scaled_weight]
	matrix `var'_nobw = e(b)
	putexcel C`row' = matrix(`var'_nobw), nformat(#.##%)
	mean `var' if bw60lag==0 [aweight=scaled_weight]
	matrix `var'_all = e(b)
	putexcel D`row' = matrix(`var'_all), nformat(#.##%)
	local ++i
}

// BW Transition rate
* Race
local row1 "5 6 7 8"

forvalues r=1/4{
	local row: word `r' of `row1'
	sum trans_bw60_alt2 if race==`r' & bw60lag==0 [aweight=scaled_weight]
	putexcel E`row'=`r(mean)', nformat(#.##%)
}

* Education
local row1 "10 11 12"

forvalues e=1/3{
	local row: word `e' of `row1'
	sum trans_bw60_alt2 if educ_gp==`e' & bw60lag==0 [aweight=scaled_weight]
	putexcel E`row'=`r(mean)', nformat(#.##%)
}
	
	
* Marital Status - December
local row1 "14 15 16"

forvalues s=1/3{
	local row: word `s' of `row1'
	sum trans_bw60_alt2 if marital_status_t1==`s' & bw60lag==0 [aweight=scaled_weight]
	putexcel E`row'=`r(mean)', nformat(#.##%)
}

* Pathway into breadwinning
local row1 "18 19 20 21 22 23"

forvalues p=1/6{
	local row: word `p' of `row1'
	sum trans_bw60_alt2 if pathway==`p' & bw60lag==0 [aweight=scaled_weight]
	putexcel E`row'=`r(mean)', nformat(#.##%)
}

**# Sample comparisons
// t-tests comparing samples - is this possible because they are nested in each other? I guess I can compare transitioners from not? because teh all eligible mothers essentially reflects those mothers most. also they can't be weighted... is this problematic?
// For the equivalent of a two-sample t test with sampling weights (pweights), use the svy: mean
// command with the over() option, and then use lincom; see [R] mean and [SVY] svy postestimation.

svyset [pweight=scaled_weight]
tab educ_gp if trans_bw60_alt2==1 & bw60lag==0
tab educ_gp if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
svy: tab educ_gp if trans_bw60_alt2==1 & bw60lag==0

*Education
ttest educ_gp1 if bw60lag==0, by(trans_bw60_alt2)
ttest educ_gp2 if bw60lag==0, by(trans_bw60_alt2)
ttest educ_gp3 if bw60lag==0, by(trans_bw60_alt2)

svy: mean educ_gp1 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.educ_gp1@0bn.trans_bw60_alt2] - _b[c.educ_gp1@1.trans_bw60_alt2]

svy: mean educ_gp2 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.educ_gp2@0bn.trans_bw60_alt2] - _b[c.educ_gp2@1.trans_bw60_alt2]

svy: mean educ_gp3 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.educ_gp3@0bn.trans_bw60_alt2] - _b[c.educ_gp3@1.trans_bw60_alt2]

*Race
ttest race1 if bw60lag==0, by(trans_bw60_alt2) // white
ttest race2 if bw60lag==0, by(trans_bw60_alt2) // black
ttest race4 if bw60lag==0, by(trans_bw60_alt2) // hisp
ttest race3 if bw60lag==0, by(trans_bw60_alt2) // asian

svy: mean race1 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.race1@0bn.trans_bw60_alt2] - _b[c.race1@1.trans_bw60_alt2]

svy: mean race2 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.race2@0bn.trans_bw60_alt2] - _b[c.race2@1.trans_bw60_alt2]

svy: mean race4 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.race4@0bn.trans_bw60_alt2] - _b[c.race4@1.trans_bw60_alt2]

svy: mean race3 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.race3@0bn.trans_bw60_alt2] - _b[c.race3@1.trans_bw60_alt2]

*Marital status
ttest marst1 if bw60lag==0, by(trans_bw60_alt2) // Married
ttest marst2 if bw60lag==0, by(trans_bw60_alt2) // Cohab
ttest marst3 if bw60lag==0, by(trans_bw60_alt2) // Single

svy: mean marst1 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.marst1@0bn.trans_bw60_alt2] - _b[c.marst1@1.trans_bw60_alt2]

svy: mean marst2 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.marst2@0bn.trans_bw60_alt2] - _b[c.marst2@1.trans_bw60_alt2]

svy: mean marst3 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.marst3@0bn.trans_bw60_alt2] - _b[c.marst3@1.trans_bw60_alt2]

*Pathway
ttest pathway2 if bw60lag==0, by(trans_bw60_alt2) // mom up unemployed
ttest pathway3 if bw60lag==0, by(trans_bw60_alt2)
ttest pathway4 if bw60lag==0, by(trans_bw60_alt2)
ttest pathway5 if bw60lag==0, by(trans_bw60_alt2)
ttest pathway6 if bw60lag==0, by(trans_bw60_alt2)
ttest pathway7 if bw60lag==0, by(trans_bw60_alt2) // other HH change

svy: mean pathway2 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway2@0bn.trans_bw60_alt2] - _b[c.pathway2@1.trans_bw60_alt2]

svy: mean pathway3 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway3@0bn.trans_bw60_alt2] - _b[c.pathway3@1.trans_bw60_alt2]

svy: mean pathway4 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway4@0bn.trans_bw60_alt2] - _b[c.pathway4@1.trans_bw60_alt2]

svy: mean pathway5 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway5@0bn.trans_bw60_alt2] - _b[c.pathway5@1.trans_bw60_alt2]

svy: mean pathway6 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway6@0bn.trans_bw60_alt2] - _b[c.pathway6@1.trans_bw60_alt2]

svy: mean pathway7 if bw60lag==0, over(trans_bw60_alt2)
lincom _b[c.pathway7@0bn.trans_bw60_alt2] - _b[c.pathway7@1.trans_bw60_alt2]

*mother's employment variable as well (prob should integrate above eventually)
tab start_from_0 if trans_bw60_alt2==1 & bw60lag==0

tab trans_bw60_alt2 employed_t0 if bw60lag==0 [aweight=scaled_weight], row
tab employed_t0 if bw60lag==0 [aweight=scaled_weight]

tab employed_t0 trans_bw60_alt2 if bw60lag==0 [aweight=scaled_weight], row // transition rate

ttest employed_t0 if bw60lag==0, by(trans_bw60_alt2)
svy: mean employed_t0 if bw60lag==0, over(trans_bw60_alt2) coeflegend
lincom _b[c.employed_t0@0bn.trans_bw60_alt2] - _b[c.employed_t0@1.trans_bw60_alt2]

ttest earnings_lag if bw60lag==0 & earnings_lag!=0, by(trans_bw60_alt2)  

sum avg_hhsize if bw60lag==0 [aweight=scaled_weight]
sum avg_hhsize if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
ttest avg_hhsize if bw60lag==0, by(trans_bw60_alt2) 
svy: mean avg_hhsize if bw60lag==0, over(trans_bw60_alt2) coeflegend
lincom _b[c.avg_hhsize@0bn.trans_bw60_alt2] -  _b[c.avg_hhsize@1.trans_bw60_alt2]

sum st_minorchildren if bw60lag==0 [aweight=scaled_weight]
sum st_minorchildren if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
ttest st_minorchildren if bw60lag==0, by(trans_bw60_alt2) 
svy: mean st_minorchildren if bw60lag==0, over(trans_bw60_alt2) coeflegend
lincom _b[c.st_minorchildren@0bn.trans_bw60_alt2] -  _b[c.st_minorchildren@1.trans_bw60_alt2]

sum end_minorchildren if bw60lag==0 [aweight=scaled_weight]
sum end_minorchildren if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
ttest end_minorchildren if bw60lag==0, by(trans_bw60_alt2) 

tab extended_hh if bw60lag==0 [aweight=scaled_weight]
tab extended_hh if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
ttest extended_hh if bw60lag==0, by(trans_bw60_alt2) 
svy: mean extended_hh if bw60lag==0, over(trans_bw60_alt2) coeflegend
lincom _b[c.extended_hh@0bn.trans_bw60_alt2] -  _b[c.extended_hh@1.trans_bw60_alt2]

ttest thearn_lag if bw60lag==0, by(trans_bw60_alt2) 

********************************************************************************
**# Table 2: Summary of HH economic changes when mom becomes BW
********************************************************************************
putexcel set "$results/Breadwinner_Heterogeneity", sheet(Table2) modify

putexcel A2 = "Total"
putexcel A3 = "Education"
putexcel A4 = "HS or Less", txtindent(4) 
putexcel A5 = "Some College", txtindent(4) 
putexcel A6 = "College", txtindent(4) 
putexcel A7 = "Race"
putexcel A8 = "White", txtindent(4) 
putexcel A9 = "Black", txtindent(4) 
putexcel A10 = "Asian", txtindent(4) 
putexcel A11 = "Hispanic", txtindent(4) 
putexcel A12 = "Pathway"
putexcel A13 = "Mom Up, Unemployed", txtindent(4) 
putexcel A14 = "Mom Up, Employed", txtindent(4) 
putexcel A15 = "Mom Up Partner Down", txtindent(4) 
putexcel A16 = "Partner Down", txtindent(4) 
putexcel A17 = "Partner Left", txtindent(4) 
putexcel A18 = "Other HH Change", txtindent(4) 


/// split pathways by education
putexcel A19 = "Education x Pathway"
putexcel A20 = "HS x Mom Up, Unemployed", txtindent(4) 
putexcel A21 = "HS x Mom Up, Employed", txtindent(4) 
putexcel A22 = "HS x Mom Up Partner Down", txtindent(4) 
putexcel A23 = "HS x Partner Down", txtindent(4) 
putexcel A24 = "HS x Partner Left", txtindent(4) 
putexcel A25 = "HS x Other HH Change", txtindent(4) 

putexcel A26 = "Some College x Mom Up, Unemployed", txtindent(4) 
putexcel A27 = "Some College x Mom Up, Employed", txtindent(4) 
putexcel A28 = "Some College x Mom Up Partner Down", txtindent(4) 
putexcel A29 = "Some College x Partner Down", txtindent(4) 
putexcel A30 = "Some College x Partner Left", txtindent(4) 
putexcel A31 = "Some College x Other HH Change", txtindent(4) 

putexcel A32 = "College x Mom Up, Unemployed", txtindent(4) 
putexcel A33 = "College x Mom Up, Employed", txtindent(4) 
putexcel A34 = "College x Mom Up Partner Down", txtindent(4) 
putexcel A35 = "College x Partner Down", txtindent(4) 
putexcel A36 = "College x Partner Left", txtindent(4) 
putexcel A37 = "College x Other HH Change", txtindent(4) 

/// split pathways by race
putexcel A38 = "Race/ethnicity x Pathway"
putexcel A39 = "White x Mom Up, Unemployed", txtindent(4) 
putexcel A40 = "White x Mom Up, Employed", txtindent(4) 
putexcel A41 = "White x Mom Up Partner Down", txtindent(4) 
putexcel A42 = "White x Partner Down", txtindent(4) 
putexcel A43 = "White x Partner Left", txtindent(4) 
putexcel A44 = "White x Other HH Change", txtindent(4) 

putexcel A45 = "Black x Mom Up, Unemployed", txtindent(4) 
putexcel A46 = "Black x Mom Up, Employed", txtindent(4) 
putexcel A47 = "Black x Mom Up Partner Down", txtindent(4) 
putexcel A48 = "Black x Partner Down", txtindent(4) 
putexcel A49 = "Black x Partner Left", txtindent(4) 
putexcel A50 = "Black x Other HH Change", txtindent(4) 

putexcel A51 = "Asian x Mom Up, Unemployed", txtindent(4) 
putexcel A52 = "Asian x Mom Up, Employed", txtindent(4) 
putexcel A53 = "Asian x Mom Up Partner Down", txtindent(4) 
putexcel A54 = "Asian x Partner Down", txtindent(4) 
putexcel A55 = "Asian x Partner Left", txtindent(4) 
putexcel A56 = "Asian x Other HH Change", txtindent(4) 

putexcel A57 = "Hispanic x Mom Up, Unemployed", txtindent(4) 
putexcel A58 = "Hispanic x Mom Up, Employed", txtindent(4) 
putexcel A59 = "Hispanic x Mom Up Partner Down", txtindent(4) 
putexcel A60 = "Hispanic x Partner Down", txtindent(4) 
putexcel A61 = "Hispanic x Partner Left", txtindent(4) 
putexcel A62 = "Hispanic x Other HH Change", txtindent(4) 

// labels
putexcel B1 = "Distribution"
putexcel D1 = "Average HH Income Pre-Transition"
putexcel E1 = "Average HH Income Post"
putexcel F1 = "Average HH Income Change"
putexcel H1 = "% Income Up"
putexcel I1 = "Average Decrease (if decreased)"
putexcel J1 = "Average Increase (if increased)"
putexcel L1 = "Median HH Income Change"
putexcel M1 = "Median Decrease (if decreased)"
putexcel N1 = "Median Increase (if increased)"

// put in data: distributions

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
	sum educ_gp`e' if trans_bw60_alt2==1 & bw60lag==0
	putexcel B`row'=`r(mean)', nformat(#.##%)
}


local row1 "8 9 10 11"
forvalues r=1/4{
	local row: word `r' of `row1'
	sum race`r' if trans_bw60_alt2==1 & bw60lag==0
	putexcel B`row'=`r(mean)', nformat(#.##%)
}


local row1 "12 13 14 15 16 17 18"
forvalues p=2/7{
	local row: word `p' of `row1'
	sum pathway`p' if trans_bw60_alt2==1 & bw60lag==0
	putexcel B`row'=`r(mean)', nformat(#.##%)
}


forvalues e=1/3{
	forvalues p=2/7{
	local row = (`e' * 6) + `p' + 12
	sum pathway`p' if trans_bw60_alt2==1 & educ_gp==`e' & bw60lag==0
	putexcel B`row'=`r(mean)', nformat(#.##%)
	}
}

forvalues r=1/4{
	forvalues p=2/7{
	local row = (`r' * 6) + `p' + 31
	sum pathway`p' if trans_bw60_alt2==1 & race==`r' & bw60lag==0
	putexcel B`row'=`r(mean)', nformat(#.##%)
	}
}

// put in data: average change
tabstat thearn_lag thearn thearn_alt hh_income_raw if trans_bw60_alt2==1 & bw60lag==0
tabstat thearn_lag thearn thearn_alt hh_income_raw if trans_bw60_alt2==1 & educ_gp==1 & bw60lag==0
tabstat thearn_lag thearn thearn_alt hh_income_raw if trans_bw60_alt2==1 & race==2 & bw60lag==0
tabstat thearn_lag thearn thearn_alt hh_income_raw if trans_bw60_alt2==1 & race==2 & pathway==1 & bw60lag==0

local average "thearn_lag thearn_alt hh_income_raw"
local colu1 "D E F"

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
	local z=1
	foreach var in `average'{
		local col: word `z' of `colu1'
		sum `var' if trans_bw60_alt2==1 & educ_gp==`e' & bw60lag==0
		putexcel `col'`row'=`r(mean)', nformat(###,###)
		local ++z
	}
}


local row1 "8 9 10 11"
forvalues r=1/4{
	local row: word `r' of `row1'
	local z=1
	foreach var in `average'{
		local col: word `z' of `colu1'
		sum `var' if trans_bw60_alt2==1 & race==`r' & bw60lag==0
		putexcel `col'`row'=`r(mean)', nformat(###,###)
		local ++z
	}
}

local row1 "13 14 15 16 17 18"
forvalues p=1/6{
	local row: word `p' of `row1'
	local z=1
	foreach var in `average'{
		local col: word `z' of `colu1'
		sum `var' if trans_bw60_alt2==1 & pathway==`p' & bw60lag==0
		putexcel `col'`row'=`r(mean)', nformat(###,###)
		local ++z
	}
}

forvalues e=1/3{
	forvalues p=1/6{
	local row = (`e' * 6) + `p' + 13
	local z=1
	foreach var in `average'{
		local col: word `z' of `colu1'
		sum `var' if trans_bw60_alt2==1 & educ_gp==`e' & pathway==`p' & bw60lag==0
		putexcel `col'`row'=`r(mean)', nformat(###,###)
		local ++z
		}
	}
}

forvalues r=1/4{
	forvalues p=1/6{
	local row = (`r' * 6) + `p' + 32
	local z=1
	foreach var in `average'{
		local col: word `z' of `colu1'
		capture sum `var' if trans_bw60_alt2==1 & race==`r' & pathway==`p' & bw60lag==0 // there is one cell (Asian + Partner Left) with no observations, so trying to get it to ignore errors and keep running
		capture putexcel `col'`row'=`r(mean)', nformat(###,###)
		local ++z
		}
	}
}

// put in data: losses / gains
sum hh_chg_value if trans_bw60_alt2==1
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==0 
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==1
sum hh_chg_value if trans_bw60_alt2==1 & educ_gp==1
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==0 & educ_gp==1
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==1 & educ_gp==1

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
	sum hh_chg_value if trans_bw60_alt2==1 & educ_gp==`e' & bw60lag==0
	putexcel H`row'=`r(mean)', nformat(##.#%)
	sum hh_income_raw if trans_bw60_alt2==1 & educ_gp==`e' & hh_chg_value==0 & bw60lag==0
	putexcel I`row'=`r(mean)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & educ_gp==`e' & hh_chg_value==1 & bw60lag==0
	putexcel J`row'=`r(mean)', nformat(###,###)
}


local row1 "8 9 10 11"
forvalues r=1/4{
	local row: word `r' of `row1'
	sum hh_chg_value if trans_bw60_alt2==1 & race==`r' & bw60lag==0
	putexcel H`row'=`r(mean)', nformat(##.#%)
	sum hh_income_raw if trans_bw60_alt2==1 & race==`r' & hh_chg_value==0 & bw60lag==0
	putexcel I`row'=`r(mean)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & race==`r' & hh_chg_value==1 & bw60lag==0
	putexcel J`row'=`r(mean)', nformat(###,###)
}

local row1 "13 14 15 16 17 18"
forvalues p=1/6{
	local row: word `p' of `row1'
	sum hh_chg_value if trans_bw60_alt2==1 & pathway==`p' & bw60lag==0
	putexcel H`row'=`r(mean)', nformat(##.#%)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & hh_chg_value==0 & bw60lag==0
	capture putexcel I`row'=`r(mean)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & hh_chg_value==1 & bw60lag==0
	capture putexcel J`row'=`r(mean)', nformat(###,###)
}

forvalues e=1/3{
	forvalues p=1/6{
	local row = (`e' * 6) + `p' + 13
	sum hh_chg_value if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & bw60lag==0
	putexcel H`row'=`r(mean)', nformat(##.#%)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & hh_chg_value==0 & bw60lag==0
	capture putexcel I`row'=`r(mean)', nformat(###,###) 
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & hh_chg_value==1 & bw60lag==0
	capture putexcel J`row'=`r(mean)', nformat(###,###)
	}
}

forvalues r=1/4{
	forvalues p=1/6{
	local row = (`r' * 6) + `p' + 32
	capture sum hh_chg_value if trans_bw60_alt2==1 & pathway==`p' & race==`r' & bw60lag==0
	capture putexcel H`row'=`r(mean)', nformat(##.#%)
	capture sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & race==`r' & hh_chg_value==0 & bw60lag==0
	capture putexcel I`row'=`r(mean)', nformat(###,###) 
	capture sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & race==`r' & hh_chg_value==1 & bw60lag==0
	capture putexcel J`row'=`r(mean)', nformat(###,###)
	}
}

// put in data: medians
sum hh_income_raw if trans_bw60_alt2==1, detail
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==0, detail
sum hh_income_raw if trans_bw60_alt2==1 & hh_chg_value==1, detail

local row1 "4 5 6"
forvalues e=1/3{
	local row: word `e' of `row1'
	sum hh_income_raw if trans_bw60_alt2==1 & educ_gp==`e' & bw60lag==0, detail
	putexcel L`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & educ_gp==`e' & hh_chg_value==0 & bw60lag==0, detail
	putexcel M`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & educ_gp==`e' & hh_chg_value==1 & bw60lag==0, detail
	putexcel N`row'=`r(p50)', nformat(###,###)
}


local row1 "8 9 10 11"
forvalues r=1/4{
	local row: word `r' of `row1'
	sum hh_income_raw if trans_bw60_alt2==1 & race==`r' & bw60lag==0, detail
	putexcel L`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & race==`r' & hh_chg_value==0 & bw60lag==0, detail
	putexcel M`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & race==`r' & hh_chg_value==1 & bw60lag==0, detail
	putexcel N`row'=`r(p50)', nformat(###,###)
}

local row1 "13 14 15 16 17 18"
forvalues p=1/6{
	local row: word `p' of `row1'
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & bw60lag==0, detail
	putexcel L`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & hh_chg_value==0 & bw60lag==0, detail
	capture putexcel M`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & hh_chg_value==1 & bw60lag==0, detail
	capture putexcel N`row'=`r(p50)', nformat(###,###)
}

forvalues e=1/3{
	forvalues p=1/6{
	local row = (`e' * 6) + `p' + 13
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & bw60lag==0, detail
	putexcel L`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & hh_chg_value==0 & bw60lag==0, detail
	capture putexcel M`row'=`r(p50)', nformat(###,###)
	sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & educ_gp==`e' & hh_chg_value==1 & bw60lag==0, detail
	capture putexcel N`row'=`r(p50)', nformat(###,###)
	}
}

forvalues r=1/4{
	forvalues p=1/6{
	local row = (`r' * 6) + `p' + 32
	capture sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & race==`r' & bw60lag==0, detail
	capture putexcel L`row'=`r(p50)', nformat(###,###)
	capture sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & race==`r' & hh_chg_value==0 & bw60lag==0, detail
	capture capture putexcel M`row'=`r(p50)', nformat(###,###)
	capture sum hh_income_raw if trans_bw60_alt2==1 & pathway==`p' & race==`r' & hh_chg_value==1 & bw60lag==0, detail
	capture putexcel N`row'=`r(p50)', nformat(###,###)
	}
}

********************************************************************************
**# Descriptive statistics by pathway (for appendix)
********************************************************************************
putexcel set "$results/Breadwinner_Heterogeneity", sheet(Table3) modify
putexcel B1 = "Mom Up, Unemployed"
putexcel C1 = "Mom Up, Employed"
putexcel D1 = "Mom Up Partner Down"
putexcel E1 = "Partner Down"
putexcel F1 = "Partner Exit"
putexcel G1 = "Other HH Change"
putexcel H1 = "BW at birth"
putexcel I1 = "Always BW"

putexcel A5 = "Mothers employed at t0"
// putexcel A7 = "Education (time-varying)"
putexcel A6 = "HS Degree or Less", txtindent(4)
putexcel A7 = "Some College", txtindent(4)
putexcel A8 = "College Plus", txtindent(4)
// putexcel A11 = "Race/ethnicity (time-invariant)"
putexcel A9 = "Non-Hispanic White", txtindent(4)
putexcel A10 = "Black", txtindent(4)
putexcel A11 = "Hispanic", txtindent(4)
putexcel A12 = "Non-Hispanic Asian", txtindent(4)
// putexcel A16 = "Relationship Status (time-varying)"
putexcel A13 = "Married t0", txtindent(4)
putexcel A14 = "Cohabitating t0", txtindent(4)
putexcel A15 = "Single t0", txtindent(4)
putexcel A16 = "Married", txtindent(4)
putexcel A17 = "Cohabitating", txtindent(4)
putexcel A18 = "Single", txtindent(4)
putexcel A19 = "Household size"
putexcel A20 = "Number of children"
putexcel A21 = "% Extended households t0"
putexcel A22 = "% Extended households"
putexcel A23 = "TANF in Year Prior (t0)", txtindent(4)
putexcel A24 = "EITC in Year Prior (t0)", txtindent(4)


putexcel A25 = "Partner had earnings t0"
putexcel A26 = "Partner had earnings t"
putexcel A27 = "Mothers' earnings at t0 (employed mothers only)"
putexcel A28 = "HH earnings at t0"


local colu "B C D E F G"

local descriptives "employed_t0 educ_gp1 educ_gp2 educ_gp3 race1 race2 race4 race3 marst_01 marst_02 marst_03 marst1 marst2 marst3 avg_hhsize st_minorchildren extended_hh_t0 extended_hh tanf_lag eeitc"

// Distributions
forvalues p=1/6{
	local col: word `p' of `colu'
	local i=1
	foreach var in `descriptives'{
		local row = `i' + 4
		mean `var' if trans_bw60_alt2==1 & bw60lag==0 & pathway==`p' [aweight=scaled_weight]
		matrix `var' = e(b)
		putexcel `col'`row' = matrix(`var'), nformat(#.##%)
		local ++i
	}
}

forvalues p=1/6{
	local col: word `p' of `colu'
	mean partner_earnings_t0 if trans_bw60_alt2==1 & bw60lag==0 & pathway==`p' & inlist(marital_status_t0,1,2) [aweight=scaled_weight]
	matrix pe_0 = e(b)
	putexcel `col'25 = matrix(pe_0), nformat(#.##%)
	
	mean partner_earnings if trans_bw60_alt2==1 & bw60lag==0 & pathway==`p' & inlist(marital_status_t1,1,2) [aweight=scaled_weight]
	matrix pe = e(b)
	putexcel `col'26 = matrix(pe), nformat(#.##%)
}

// bw at birth - diff var / sample
local i=1
foreach var in `descriptives'{
	local row = `i' + 4
	mean `var' if bw_at_birth==1 [aweight=scaled_weight]
	matrix `var' = e(b)
	putexcel H`row' = matrix(`var'), nformat(#.##%)
	local ++i
}

// always BW - diff var / sample
local i=1
foreach var in `descriptives'{
	local row = `i' + 4
	mean `var' if always_bw==1 [aweight=scaled_weight]
	matrix `var' = e(b)
	putexcel I`row' = matrix(`var'), nformat(#.##%)
	local ++i
}

tab marital_status_t1 if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]
tab marital_status_t0 if trans_bw60_alt2==1 & bw60lag==0 [aweight=scaled_weight]

tab partner_earnings_t0 if trans_bw60_alt2==1 & bw60lag==0 & inlist(marital_status_t0,1,2) [aweight=scaled_weight]
tab partner_earnings if trans_bw60_alt2==1 & bw60lag==0 & inlist(marital_status_t1,1,2) [aweight=scaled_weight]

tab partner_earnings_t0 if bw_at_birth==1 & inlist(marital_status_t0,1,2) [aweight=scaled_weight]
tab partner_earnings if bw_at_birth==1 & inlist(marital_status_t1,1,2) [aweight=scaled_weight]

tab partner_earnings_t0 if always_bw==1 & inlist(marital_status_t0,1,2) [aweight=scaled_weight]
tab partner_earnings if always_bw==1 & inlist(marital_status_t1,1,2) [aweight=scaled_weight]


// Income 
local colu "B C D E F G"

forvalues p=1/6{
	local col: word `p' of `colu'
	*Mother
	capture sum earnings_lag if earnings_lag!=0 & trans_bw60_alt2==1 & bw60lag==0 & pathway==`p', detail  // earnings lag has to be 0 for pathway 1
	capture putexcel `col'27=`r(mean)', nformat(###,###)

	* HH
	sum thearn_lag if trans_bw60_alt2==1 & bw60lag==0 & pathway==`p', detail
	putexcel `col'28=`r(mean)', nformat(###,###)
}

sum earnings_lag if earnings_lag!=0 & bw_at_birth==1, detail  // earnings lag has to be 0 for pathway 1
putexcel H27=`r(mean)', nformat(###,###)
	
sum thearn_lag if bw_at_birth==1, detail
putexcel H28=`r(mean)', nformat(###,###)

sum earnings_lag if earnings_lag!=0 & always_bw==1, detail  // earnings lag has to be 0 for pathway 1
putexcel I27=`r(mean)', nformat(###,###)
	
sum thearn_lag if always_bw==1, detail
putexcel I28=`r(mean)', nformat(###,###)

********************************************************************************
**# Figures for JFEI
********************************************************************************
*Okay, so this is in JFEI, but I think I used the graph editor to change plottype to rarea. Okay i can recast duh kim
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000, width(2000) percent recast(rarea) xline(0,lcolor(black)) color(gray%60)), xlabel(-75000(5000)75000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(, labsize(small)) ytitle("Percent Distribution of Households") graphregion(fcolor(white))

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000, width(2000) percent recast(rarea) xline(0,lcolor(black)) color(gray%60)), xlabel(-70000(10000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(, labsize(small)) ytitle("Percent Distribution of Households") graphregion(fcolor(white)) ysize(6) xsize(8)

* Education
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

// twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-75000(5000)75000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(5)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(8)

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==2, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ysc(off) ylabel(0(15)15, labsize(small)) ytitle("") graphregion(fcolor(white)) ysize(4.5) xsize(6) // yscale(lstyle(none))

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & educ_gp==3, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small))ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)
/*
twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(1000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(1000) color(blue%30) recast(area)), ///
legend(order(1 "LTHS" 2 "College" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(4000) recast(area) color(red%30) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(4000) recast(area) color(blue%30)), ///
legend(order(1 "LTHS" 2 "College" )) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))
*/

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==1, percent width(4000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==2, percent width(4000) color(dkblue%30) recast(area)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & educ_gp==3, percent width(4000) color(blue%30) recast(area)), ///
legend(order(1 "LTHS" 2 "Some College" 3 "College" ) size(small) rows(1)) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) ylabel(, labsize(small)) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))


*Race
twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==1, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change")  ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==2, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)  

twoway (histogram hh_income_raw if hh_income_raw>=-75000 & hh_income_raw<=75000 & race_gp==3, width(4000) percent recast(rarea) xline(0,lcolor(black)) color(gray%40)), xlabel(-70000(70000)70000, labsize(small) angle(ninety) valuelabel) xtitle("Household Income Change") ysc(off) ylabel(0(15)15, labsize(small)) ytitle("Percent Distribution") graphregion(fcolor(white)) ysize(4.5) xsize(6)

twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==1, percent width(4000) color(red%30) recast(area) xline(0)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==2, percent width(4000) color(dkblue%30) recast(area)) ///
(histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & race_gp==3, percent width(4000) color(blue%30) recast(area)), ///
legend(order(1 "White" 2 "Black" 3 "Hispanic" ) size(small) rows(1)) xlabel(-50000(5000)50000, labsize(vsmall) angle(forty_five) valuelabel) ylabel(, labsize(small)) xtitle("Household Income Change") ytitle("Percent Distribution") graphregion(fcolor(white))

* Pathway
forvalues p=1/6{
	local pathway_`p': label (pathway) `p'
	twoway (histogram hh_income_raw if hh_income_raw>=-50000 & hh_income_raw<=50000 & pathway==`p', width(1000) percent recast(rarea) xline(0) color(gray%30)), xtitle("`pathway_`p''")
	graph export "$results\pathway_histogram_`p'.png", as(png) name("Graph") replace
}

local pathway_1: label (pathway) 1
display "`pathway_1'"


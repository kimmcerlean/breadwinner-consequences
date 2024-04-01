*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* economic_consequences.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* File used was created in ab_decomposition_equation.do

use "$tempdir/combined_bw_equation.dta", clear // created in step ab

// some sample restrictions
* restrict to just 2014
keep if survey_yr==2

* restrict to just eligible mothers - not breadwinner in year and have a second year of data to track them. need to retain prior year income first
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0
gen thearn_adj_lag = thearn_adj[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
	
browse SSUID PNUM year bw60 bw60lag trans_bw60_alt2 thearn_adj thearn_adj_lag hh_income_raw_all
// keep if bw60lag==0

// tab bw60 - that makes sense with our final transition rate
 
********************************************************************************
* Some variable things
********************************************************************************
 
// reclassify pathways

gen mom_earn_change=.
replace mom_earn_change=-1 if mom_lose_earn==1 | earn_change <0
replace mom_earn_change=0 if mom_gain_earn==0 & earnup8_all==0 & mom_lose_earn==0 & earn_change==0
replace mom_earn_change=1 if earnup8_all==1
replace mom_earn_change=0 if mom_earn_change==. // the very small mom ups - want to be considered no change
replace mom_earn_change=1 if mom_earn_change==0 & mt_mom==1 // BUT want the very small moms if ONLY mom's earnings went up, because there is nowhere else to put
browse SSUID PNUM year earn_change mom_gain_earn mom_lose_earn earnings_adj mom_earn_change earnup8_all

tab partner_lose mom_earn_change, row
tab educ_gp mom_earn_change if partner_lose==1, row
tab lt_other_changes mom_earn_change, row
tab ft_partner_down mom_earn_change, row

tab partner_lose mom_earn_change if trans_bw60_alt2==1, row
tab lt_other_changes mom_earn_change if trans_bw60_alt2==1, row
tab ft_partner_down mom_earn_change if trans_bw60_alt2==1, row
tab ft_partner_down_only mom_earn_change if trans_bw60_alt2==1, row

/* mom change: earn_change mom_gain_earn == specifically BECAME an earner
* other change: earn_change_hh earn_lose earn_change_sp partner_lose
browse SSUID PNUM year mom_gain_earn earn_change_hh earn_lose earn_change_sp partner_lose mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes
browse SSUID PNUM year mom_gain_earn  earn_change partner_lose ft_partner_leave
*/

* mt_mom // can stay
gen left_up=0
replace left_up=1 if ft_partner_leave==1 & mom_earn_change==1
gen left_no=0
replace left_no=1 if ft_partner_leave==1 & mom_earn_change==0
gen left_down=0
replace left_down=1 if ft_partner_leave==1 & mom_earn_change==-1

gen partner_up=0
replace partner_up=1 if ft_partner_down==1 & mom_earn_change==1
gen partner_no=0
replace partner_no=1 if ft_partner_down==1 & mom_earn_change==0
gen partner_down=0
replace partner_down=1 if ft_partner_down==1 & mom_earn_change==-1

gen other_up=0
replace other_up=1 if lt_other_changes==1 & mom_earn_change==1
gen other_no=0
replace other_no=1 if lt_other_changes==1 & mom_earn_change==0
gen other_down=0
replace other_down=1 if lt_other_changes==1 & mom_earn_change==-1

egen check_total = rowtotal(mt_mom left_up left_no left_down partner_up partner_no partner_down other_up other_no other_down)
tab check_total // no one should have more than 1 - great
tab check_total if trans_bw60_alt2==1 // should have 1 - great

* create 1 variable for ease
gen pathway=.
replace pathway=1 if mt_mom==1
replace pathway=2 if left_up==1
replace pathway=3 if left_no==1
replace pathway=4 if left_down==1
replace pathway=5 if partner_up==1
replace pathway=6 if partner_no==1
replace pathway=7 if partner_down==1
replace pathway=8 if other_up==1
replace pathway=9 if other_no==1
replace pathway=10 if other_down==1

label define pathway 1 "mt_mom" 2 "left_up" 3 "left_no" 4 "left_down" 5 "partner_up" 6 "partner_no" 7 "partner_down" 8 "other_up" 9 "other_no" 10 "other_down"
label values pathway pathway

tab pathway, m
tab pathway if trans_bw60_alt2==1, m

// partner status (for mom up only)
recode last_marital_status (1=1) (2=2) (3/5=3), gen(marital_status_t1)
label define marr 1 "Married" 2 "Cohabiting" 3 "Single"
label values marital_status_t1 marr

// okay final (for now) pathways
gen pathway_gp=.
replace pathway_gp=1 if mt_mom==1 & inlist(marital_status_t1,1,2) // mom up and partnered
replace pathway_gp=2 if mt_mom==1 & marital_status_t1==3 // mom up and single
replace pathway_gp=3 if inlist(pathway,2,5) // partner change - up
replace pathway_gp=4 if inlist(pathway,3,4,6,7) // partner change - no or down
replace pathway_gp=5 if pathway==8 // other change - up
replace pathway_gp=6 if inlist(pathway,9,10) // other change - no or down

label define pathway_gp 1 "Mom up - partnered" 2 "mom up - single" 3 "Partner Change - Up" 4 "Partner Change Only" 5 "Other Change - Up" 6 "Other Change - Only"
label values pathway_gp pathway_gp

tab pathway_gp, m
tab pathway pathway_gp
tab pathway_gp if trans_bw60_alt2==1, m


// need outcome variable
browse SSUID year end_hhsize end_minorchildren threshold thearn_adj
gen inc_pov = thearn_adj / threshold
gen inc_pov_lag = inc_pov[_n-1] if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1)
gen pov_lag=.
replace pov_lag=0 if inc_pov_lag <1.5
replace pov_lag=1 if inc_pov_lag>=1.5 & inc_pov_lag!=. // okay 1 is NOT in poverty

by SSUID PNUM (year), sort: gen inc_pov_change = ((inc_pov-inc_pov[_n-1])/inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1
by SSUID PNUM (year), sort: gen inc_pov_change_raw = (inc_pov-inc_pov[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==year[_n-1]+1

// 4 category outcome
gen inc_pov_summary2=.
replace inc_pov_summary2=1 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=2 if inc_pov_change_raw > 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=3 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov >=1.5
replace inc_pov_summary2=4 if inc_pov_change_raw < 0 & inc_pov_change_raw!=. & inc_pov <1.5
replace inc_pov_summary2=5 if inc_pov_change_raw==0

label define summary2 1 "Up, Above Pov" 2 "Up, Below Pov" 3 "Down, Above Pov" 4 "Down, Below Pov" 5 "No Change"
label values inc_pov_summary2 summary2

tab inc_pov_summary2 if trans_bw60_alt2==1, m // this matches our output table
tabstat thearn_adj if trans_bw60_alt2, by(inc_pov_summary2) stats(mean p50)
tabstat inc_pov if trans_bw60_alt2, by(inc_pov_summary2) stats(mean p50)

********************************************************************************
* Outcomes
********************************************************************************
// mix of pathways by race / class
// tab race pathway_gp, row // total
tab race pathway_gp if bw60lag==0, row // wait which of these is right total? alll? or all eligible? probably all eligible right? since that is who we care about
tab race pathway_gp if trans_bw60_alt2==1, row // just BW

// tab educ_gp pathway_gp, row // total
tab educ_gp pathway_gp if bw60lag==0, row // total
tab educ_gp pathway_gp if trans_bw60_alt2==1, row // just BW

//tab pathway_gp
tab pathway_gp if bw60lag==0, m // need missing because not all people experience an event DUH
tab pathway_gp if trans_bw60_alt2==1

tab pathway inc_pov_summary2 if trans_bw60_alt2==1, row nofreq
tab pathway_gp inc_pov_summary2 if trans_bw60_alt2==1, row nofreq

tab pov_lag inc_pov_summary2 if trans_bw60_alt2==1, row


// attempting models (see file ad for reference)
** Should I restrict sample to just mothers who transitioned into breadwinning for this step? Probably. or just subpop?
keep if trans_bw60_alt2==1 & bw60lag==0
keep if survey == 2014

recode inc_pov_summary2 (1=4) (2=3) (3=2) (4=1), gen(outcome)
label define outcome 1 "Down, Below Pov" 2 "Down, Above" 3 "Up, Below" 4 "Up, Above"
label values outcome outcome
tab inc_pov_summary2 outcome

ologit outcome i.pathway_gp
margins pathway_gp
predict down_b down_a up_b up_a

ologit outcome ib3.pathway_gp

ologit outcome i.pathway_gp i.educ_gp i.race, or // with controls?
margins pathway_gp
margins // will give me total

ologit outcome i.pathway_gp##i.educ_gp, or // interactions
margins pathway_gp#educ_gp

ologit outcome i.pathway_gp##i.race, or // interactions
margins pathway_gp#race

ologit outcome i.pathway i.educ_gp, or
margins i.educ_gp

ologit outcome i.pathway i.race, or
margins i.race

// which to use? 
mlogit outcome i.pathway_gp
margins pathway_gp



********************************************************************************
* Revisit the below - to compare to non-BW HHs (from rows 735 in file ac - Table 4)
********************************************************************************
// mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes

* Total - BUT had to experience an event
// sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]!=., detail  // pre 2014 all HHs
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]!=., detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]!=., detail  // pre 2014 -- HHs that don't become BW

// sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp!=., detail // post 2014 - all
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp!=., detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp!=., detail // post 2014 - not BW

// for each pathway
* Mom up only
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & mt_mom[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & mt_mom==1, detail // post 2014 - not BW

* Partner down only
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_only[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_only[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_only==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_only==1, detail // post 2014 - not BW

* Mom Up partner down
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_down_mom[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_down_mom==1, detail // post 2014 - not BW

* Partner left
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & ft_partner_leave[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & ft_partner_leave==1, detail // post 2014 - not BW

* other hh member
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & lt_other_changes[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & lt_other_changes[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & lt_other_changes==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & lt_other_changes==1, detail // post 2014 - not BW

/* old
* Mom up partnered (1)
sum thearn_adj if bw60==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==1, detail  // pre 2014 all HHs
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==1, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==1, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==1, detail // post 2014 - all
sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==1, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==1, detail // post 2014 - not BW


* Mom up single (2)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==2, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==2, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==2, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==2, detail // post 2014 - not BW

* Partner + Up (3)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==3, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==3, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==3, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==3, detail // post 2014 - not BW

* Other + Up (5)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==5, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==5, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==5, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==5, detail // post 2014 - not BW

* Partner Only (4)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==4, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==4, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==4, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==4, detail // post 2014 - not BW

* Other Only (6)
sum thearn_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==6, detail  // pre 2014 -- HHs that become BW
sum thearn_adj if bw60==0 & bw60[_n+1]==0 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==6, detail  // pre 2014 -- HHs that don't become BW

sum thearn_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==6, detail // post 2014 - BW
sum thearn_adj if bw60==0 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==6, detail // post 2014 - not BW
*/

** four category measure
tab inc_pov_summary2 if trans_bw60_alt2==1 & bw60lag==0, m // this matches our output table
tab inc_pov_summary2 if bw60==1 & bw60lag==0, m // this matches our output table -- became
tab inc_pov_summary2 if bw60==0 & bw60lag==0 & pathway_gp!=., m // this matches our output table -- did not become, but had to experience an event

tab pathway_gp if bw60==1 & bw60lag==0, m
tab pathway_gp inc_pov_summary2 if bw60==1 & bw60lag==0, row nofreq

tab pathway_gp if bw60==0 & bw60lag==0 //, m
tab pathway_gp inc_pov_summary2 if bw60==0 & bw60lag==0, row nofreq

* Change metrics (I think for histogram?)
by SSUID PNUM (year), sort: gen hh_income_chg = ((thearn_adj-thearn_adj[_n-1])/thearn_adj[_n-1]) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
by SSUID PNUM (year), sort: gen hh_income_raw = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & trans_bw60_alt2==1
browse SSUID PNUM year thearn_adj bw60 trans_bw60_alt2 hh_income_chg hh_income_raw
	
by SSUID PNUM (year), sort: gen hh_income_raw_all = ((thearn_adj-thearn_adj[_n-1])) if SSUID==SSUID[_n-1] & PNUM==PNUM[_n-1] & year==(year[_n-1]+1) & bw60lag==0

** comparing mom's gain to other's loss by pathway
*proxy for "other" earner:
gen earnings_oth_adj = thearn_adj - earnings_adj - earnings_sp_adj
browse thearn_adj earnings_adj earnings_sp_adj earnings_oth_adj

sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre - mom
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post - mom 

sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre - partner
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post - partner

sum earnings_oth_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2, detail  // pre - other
sum earnings_oth_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2, detail // post - other

* Mom up partnered (1)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==1, detail  // pre 2014 mom
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==1, detail // post 2014 - mom

* Mom up single (2)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==2, detail  // pre 2014 -- mom
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==2, detail // post 2014 - mom

* Partner + Up (3)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==3, detail  // pre 2014 mom
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==3, detail // post 2014 - mom

sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==3, detail  // pre 2014 partner
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==3, detail // post 2014 - partner

* Other + Up (5)
sum earnings_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==5, detail  // pre 2014 mom
sum earnings_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==5, detail // post 2014 - mom

sum earnings_oth_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==5, detail  // pre 2014 other
sum earnings_oth_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==5, detail // post 2014 - other

* Partner Only (4)
sum earnings_sp_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==4, detail  // pre 2014 partner
sum earnings_sp_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==4, detail // post 2014 - partner

* Other Only (6)
sum earnings_oth_adj if bw60==0 & bw60[_n+1]==1 & year==(year[_n+1]-1) & SSUID[_n+1]==SSUID & survey_yr==2 & pathway_gp[_n+1]==6, detail  // pre 2014 other
sum earnings_oth_adj if bw60==1 & bw60[_n-1]==0 & year==(year[_n-1]+1) & SSUID==SSUID[_n-1] & survey_yr==2 & pathway_gp==6, detail // post 2014 - other


/* old
* mom change: earn_change mom_gain_earn == specifically BECAME an earner
* other change: earn_change_hh earn_lose earn_change_sp partner_lose
browse SSUID PNUM year mom_gain_earn earn_change_hh earn_lose earn_change_sp partner_lose mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes
browse SSUID PNUM year mom_gain_earn  earn_change partner_lose ft_partner_leave

* mt_mom // can stay

gen partner_loss_only = ft_partner_down_only
replace partner_loss_only = 1 if partner_lose==1 & mom_gain_earn==0 & earn_change <=0
// then also replace if JUST partner left

gen partner_mom_change = ft_partner_down_mom
replace partner_mom_change = 1 if ft_partner_leave & (mom_gain_earn==1 | earn_change > 0)
// then also replace if partner left and mom changed

browse SSUID PNUM year mom_gain_earn  earn_change partner_lose ft_partner_leave partner_loss_only partner_mom_change

gen other_change_only = 0
replace other_change_only=1 if lt_other_changes & mom_gain_earn==0 & earn_change <=0

gen other_mom_change = 0
replace other_mom_change=1 if lt_other_changes & (mom_gain_earn==1 | earn_change > 0)
*/

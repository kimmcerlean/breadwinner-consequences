*-------------------------------------------------------------------------------
* BREADWINNER PROJECT
* consequences_decomp.do
* Kim McErlean
*-------------------------------------------------------------------------------
di "$S_DATE"

********************************************************************************
* DESCRIPTION
********************************************************************************
* This file....

use "$tempdir/bw_consequences.dta", clear // created in step ad

// variables: mt_mom ft_partner_down ft_partner_leave lt_other_changes
// create outcome as binary variables
tab mechanism, gen(mechanism)
rename mechanism1 default
rename mechanism2 reserve
rename mechanism3 empower

// svyset [pweight = wpfinwgt]

/*template
mean mt_mom if educ_gp==1
mean mt_mom if educ_gp==3
mean empower if mt_mom==1 & educ_gp==1
mean empower if mt_mom==1 & educ_gp==3

mean mt_mom if educ_gp==1
mean mt_mom if educ_gp==2
mean empower if mt_mom==1 & educ_gp==1
mean empower if mt_mom==1 & educ_gp==2

mean mt_mom if educ_gp==3
mean mt_mom if educ_gp==2
mean empower if mt_mom==1 & educ_gp==3
mean empower if mt_mom==1 & educ_gp==2
*/

putexcel set "$results/Consequences_decomposition", sheet(Sheet1) replace
putexcel A2:A7 = "Empower", merge vcenter
putexcel A8:A13 = "Default", merge vcenter
putexcel A18:A23 = "Reserve", merge vcenter
putexcel A25:A30 = "Empower", merge vcenter
putexcel A31:A36 = "Default", merge vcenter
putexcel A41:A46 = "Reserve", merge vcenter

putexcel B2 = ("LTHS") B3 = ("College") B4 = ("Some College") B5 = ("College") B6 = ("LTHS") B7 = ("Some College")
putexcel B8 = ("LTHS") B9 = ("College") B10 = ("Some College") B11 = ("College") B12 = ("LTHS") B13 = ("Some College")
putexcel B18 = ("LTHS") B19 = ("College") B20 = ("Some College") B21 = ("College") B22 = ("LTHS") B23 = ("Some College")

putexcel B25 = ("White") B26 = ("Black") B27 = ("White") B28 = ("Hispanic") B29 = ("Black") B30 = ("Hispanic")
putexcel B31 = ("White") B32 = ("Black") B33 = ("White") B34 = ("Hispanic") B35 = ("Black") B36 = ("Hispanic")
putexcel B41 = ("White") B42 = ("Black") B43 = ("White") B44 = ("Hispanic") B45 = ("Black") B46 = ("Hispanic")

putexcel C1 = "Mom Up", border(bottom)
putexcel D1 = "Mom Up and Outcome", border(bottom)
putexcel E1 = "Partner Down Mom Up", border(bottom)
putexcel F1 = "Partner Down Mom Up and Outcome", border(bottom)
putexcel G1 = "Partner Down", border(bottom)
putexcel H1 = "Partner Down and Outcome", border(bottom)
putexcel I1 = "Partner left", border(bottom)
putexcel J1 = "Partner left and Outcome", border(bottom)
putexcel K1 = "Other member change", border(bottom)
putexcel L1 = "Other member change and Outcome", border(bottom)
putexcel M1 = "Rate of Outcome", border(bottom)
putexcel N1 = "Total Difference", border(bottom)
putexcel O1 = "Alt Rate", border(bottom)
putexcel P1 = "Rate Difference", border(bottom)
putexcel Q1 = "Alt Comp", border(bottom)
putexcel R1 = "Composition Difference", border(bottom)
putexcel S1 = "Mom Component", border(bottom)
putexcel T1 = "Partner Down Mom Up Component", border(bottom)
putexcel U1 = "Partner Down Only Component", border(bottom)
putexcel V1 = "Partner Left Component", border(bottom)
putexcel W1 = "Other Component", border(bottom)

local colu1 "C E G I K C E G I K C E G I K"
local colu2 "D F H J L D F H J L D F H J L"
local i=1
local x=1

// education

foreach outcome in empower default reserve{
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		
		
		local row1=(`x'*`x')+(`x'*`x')
		local row2=(`x'*`x')+(`x'*`x')+1
		sum `var' if educ_gp==1
		putexcel `col1'`row1' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'`row2' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==1
		putexcel `col2'`row1' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==3
		putexcel `col2'`row2' = `r(mean)', nformat(#.##%)
	
		local row3=(`x'*`x')+(`x'*`x')+2
		local row4=(`x'*`x')+(`x'*`x')+3
		sum `var' if educ_gp==2
		putexcel `col1'`row3' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'`row4' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==2
		putexcel `col2'`row3'= `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==3
		putexcel `col2'`row4' = `r(mean)', nformat(#.##%)
		
		local row5=(`x'*`x')+(`x'*`x')+4
		local row6=(`x'*`x')+(`x'*`x')+5
		sum `var' if educ_gp==1
		putexcel `col1'`row5' = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==2
		putexcel `col1'`row6' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==1
		putexcel `col2'`row5' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & educ_gp==2
		putexcel `col2'`row6' = `r(mean)', nformat(#.##%)
		
		local ++i
		}
	local ++x
}


// race
local colu1 "C E G I K C E G I K C E G I K"
local colu2 "D F H J L D F H J L D F H J L"
local i=1
local x=1

foreach outcome in empower default reserve{
	foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
		local col1: word `i' of `colu1'
		local col2: word `i' of `colu2'
		
		
		local row1=(`x'*`x')+(`x'*`x')+23
		local row2=(`x'*`x')+(`x'*`x')+24
		sum `var' if race==1
		putexcel `col1'`row1' = `r(mean)', nformat(#.##%)
		sum `var' if race==2
		putexcel `col1'`row2' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==1
		putexcel `col2'`row1' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==2
		putexcel `col2'`row2' = `r(mean)', nformat(#.##%)
	
		local row3=(`x'*`x')+(`x'*`x')+25
		local row4=(`x'*`x')+(`x'*`x')+26
		sum `var' if race==1
		putexcel `col1'`row3' = `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'`row4' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==1
		putexcel `col2'`row3'= `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==4
		putexcel `col2'`row4' = `r(mean)', nformat(#.##%)
		
		local row5=(`x'*`x')+(`x'*`x')+27
		local row6=(`x'*`x')+(`x'*`x')+28
		sum `var' if race==2
		putexcel `col1'`row5' = `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'`row6' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==2
		putexcel `col2'`row5' = `r(mean)', nformat(#.##%)
		sum `outcome' if `var'==1 & race==4
		putexcel `col2'`row6' = `r(mean)', nformat(#.##%)
		
		local ++i
		}
	local ++x
}


// Calculating rates needed
forvalues r=2/46{
	putexcel M`r'=formula((C`r'*D`r')+(E`r'*F`r')+(G`r'*H`r')+(I`r'*J`r')+(K`r'*L`r')), nformat(#.##%)
}

local row "2 4 6 8 10 12 18 20 22 25 27 29 31 33 35 41 43 45"
local i=1

forvalues r=1/18{
	local row1: word `i' of `row'
	local row2 = `row1'+1
	putexcel O`row1'=formula((C`row1'*D`row2')+(E`row1'*F`row2')+(G`row1'*H`row2')+(I`row1'*J`row2')+(K`row1'*L`row2')), nformat(#.##%) // setting rate to other group
	putexcel Q`row1'=formula((C`row2'*D`row1')+(E`row2'*F`row1')+(G`row2'*H`row1')+(I`row2'*J`row1')+(K`row2'*L`row1')), nformat(#.##%) // setting composition to other group
	putexcel N`row1'=formula(M`row2'-M`row1'), nformat(#.##%) // total diff
	putexcel P`row1'=formula(O`row1'-M`row1'), nformat(#.##%) // rate diff
	putexcel R`row1'=formula(Q`row1'-M`row1'), nformat(#.##%) // comp diff
	local ++i
}


// need to figure out how to do the specific elements. might need to go back to the matrices. just difficult because it's not systematic like by race and class; i keep swapping reference groups
// try to decompose INCOME TO NEEDS?

putexcel set "$results/Consequences_decomposition", sheet(income_needs) modify
putexcel A2:A7 = "Income to Needs", merge vcenter
putexcel A8:A13 = "Income to Needs", merge vcenter

putexcel B2 = ("LTHS") B3 = ("College") B4 = ("Some College") B5 = ("College") B6 = ("LTHS") B7 = ("Some College")
putexcel B8 = ("White") B9 = ("Black") B10 = ("White") B11 = ("Hispanic") B12 = ("Black") B13 = ("Hispanic")

putexcel C1 = "Mom Up", border(bottom)
putexcel D1 = "Mom Up and Outcome", border(bottom)
putexcel E1 = "Partner Down Mom Up", border(bottom)
putexcel F1 = "Partner Down Mom Up and Outcome", border(bottom)
putexcel G1 = "Partner Down", border(bottom)
putexcel H1 = "Partner Down and Outcome", border(bottom)
putexcel I1 = "Partner left", border(bottom)
putexcel J1 = "Partner left and Outcome", border(bottom)
putexcel K1 = "Other member change", border(bottom)
putexcel L1 = "Other member change and Outcome", border(bottom)
putexcel M1 = "Rate of Outcome", border(bottom)
putexcel N1 = "Total Difference", border(bottom)
putexcel O1 = "Alt Rate", border(bottom)
putexcel P1 = "Rate Difference", border(bottom)
putexcel Q1 = "Alt Comp", border(bottom)
putexcel R1 = "Composition Difference", border(bottom)
putexcel S1 = "Mom Component", border(bottom)
putexcel T1 = "Partner Down Mom Up Component", border(bottom)
putexcel U1 = "Partner Down Only Component", border(bottom)
putexcel V1 = "Partner Left Component", border(bottom)
putexcel W1 = "Other Component", border(bottom)

local colu1 "C E G I K"
local colu2 "D F H J L"
local i=1
local x=1

// education


foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
		
		sum `var' if educ_gp==1
		putexcel `col1'2 = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'3 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==1, detail
		putexcel `col2'2 = `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==3, detail
		putexcel `col2'3 = `r(p50)', nformat(#.##%)
	
		sum `var' if educ_gp==2
		putexcel `col1'4= `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==3
		putexcel `col1'5 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==2, detail
		putexcel `col2'4= `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==3, detail
		putexcel `col2'5 = `r(p50)', nformat(#.##%)

		sum `var' if educ_gp==1
		putexcel `col1'6 = `r(mean)', nformat(#.##%)
		sum `var' if educ_gp==2
		putexcel `col1'7 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==1, detail
		putexcel `col2'6 = `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & educ_gp==2, detail
		putexcel `col2'7 = `r(p50)', nformat(#.##%)
		
		local ++i
}


// race
local colu1 "C E G I K"
local colu2 "D F H J L"
local i=1
local x=1

foreach var in mt_mom ft_partner_down_mom ft_partner_down_only ft_partner_leave lt_other_changes{
	local col1: word `i' of `colu1'
	local col2: word `i' of `colu2'
		
		sum `var' if race==1
		putexcel `col1'8 = `r(mean)', nformat(#.##%)
		sum `var' if race==2
		putexcel `col1'9 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==1, detail
		putexcel `col2'8 = `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==2, detail
		putexcel `col2'9 = `r(p50)', nformat(#.##%)
	
		sum `var' if race==1
		putexcel `col1'10= `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'11 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==1, detail
		putexcel `col2'10= `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==4, detail
		putexcel `col2'11 = `r(p50)', nformat(#.##%)

		sum `var' if race==2
		putexcel `col1'12 = `r(mean)', nformat(#.##%)
		sum `var' if race==4
		putexcel `col1'13 = `r(mean)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==2, detail
		putexcel `col2'12 = `r(p50)', nformat(#.##%)
		sum inc_pov if `var'==1 & race==4, detail
		putexcel `col2'13 = `r(p50)', nformat(#.##%)
		
		local ++i
}

// Calculating rates needed
forvalues r=2/13{
	putexcel M`r'=formula((C`r'*D`r')+(E`r'*F`r')+(G`r'*H`r')+(I`r'*J`r')+(K`r'*L`r')), nformat(#.##%)
}

local row "2 4 6 8 10 12"
local i=1

forvalues r=1/6{
	local row1: word `i' of `row'
	local row2 = `row1'+1
	putexcel O`row1'=formula((C`row1'*D`row2')+(E`row1'*F`row2')+(G`row1'*H`row2')+(I`row1'*J`row2')+(K`row1'*L`row2')), nformat(#.##%) // setting rate to other group
	putexcel Q`row1'=formula((C`row2'*D`row1')+(E`row2'*F`row1')+(G`row2'*H`row1')+(I`row2'*J`row1')+(K`row2'*L`row1')), nformat(#.##%) // setting composition to other group
	putexcel N`row1'=formula(M`row2'-M`row1'), nformat(#.##%) // total diff
	putexcel P`row1'=formula(O`row1'-M`row1'), nformat(#.##%) // rate diff
	putexcel R`row1'=formula(Q`row1'-M`row1'), nformat(#.##%) // comp diff
	local ++i
}



* Project: Impact of firm-level covid rescue policies
* Authors: Glenn Magerman & Dieter Van Esbroeck
* Version: 02/06/23

*--------------------------------
**# quarterly event study results
*--------------------------------

*-----------------------
**# 1. prepare variables
*-----------------------
use "generated_data/data_eventstudyquarterly", clear
xtset vat quarter

// create dummy for the first quarter a firm got support
gen temp = quarter if dummy_support==1
bysort vat (quarter): egen firstquartersupport = min(temp)

// fill in missing firstquarter treatments if any
bys vat (quarter): egen minfirstquartersupport=min(firstquartersupport)
replace firstquartersupport=minfirstquartersupport if missing(firstquartersupport)
	
// create variable indicating the quarter just before support
gen I_t0=quarter==firstquartersupport-1

// create variable indicating the difference of the quarter with the first quarter of support
gen diff=quarter-firstquartersupport

// create all relative time dummies to support used in regression
forv i=1/7 {
	gen I_post`i' =0
	replace I_post`i'=1 if diff==`i'-1
				
	gen I_pre`i' = 0
	replace I_pre`i'=1 if diff==-`i'-1
		
	}
drop diff

// create indicator of firms that never get support
gen untreated=missing(firstquartersupport)

// create industry-quarter fixed effects
egen indqFE=group(quarter nacerev2_recoded)

// save dataset for later use
save "tmp/estdata_eventstudy", replace

*-----------------------------
**# 2. regressions and results
*-----------------------------
// 2.1 event study, impact of support measures on productivity
use "tmp/estdata_eventstudy", clear

// check groups
tab quarter dummy_support

// event study regression
eststo : reghdfe lnsales_fte I_pre4 I_pre3 I_pre2 I_pre1 I_post1 I_post2 I_post3 I_post4 I_post5 I_post6 I_post7, absorb(vatFE=vat indFE=indqFE) cluster(vat)

// store coefficients
estimates store lnsales_fte_coef
keep if e(sample)
regsave using "tmp/reg_lnsales_fte", ci level(95) replace

// create graph with results	
use "tmp/reg_lnsales_fte", clear
drop if var=="_cons"
drop if stderr ==0
gen t=.
forv k=1/7 {
	replace t = -`k' if var=="I_pre`k'"
	replace t = `k' if var=="I_post`k'"
}

// figure 3
twoway (scatter coef t) (rspike ci_lower ci_upper t, legend(label(1 "Coefficient")) legend(label(2 "95% CI"))), yline(0) xlabel(-4(1)7) ylabel(-0.10(0.05)0.10) xtitle("") graphregion(fcolor(white)) name("lnsales_fte", replace) 
*graph export "results/EER-D-22-01148_Figure_3.eps", replace

// 2.2 event study controlling for the furlough scheme
use "tmp/estdata_eventstudy", clear

// check groups
tab quarter dummy_support

// event study regression
eststo : reghdfe lnsales_fte I_pre4 I_pre3 I_pre2 I_pre1 I_post1 I_post2 I_post3 I_post4 I_post5 I_post6 I_post7 furl_ratio_ev, absorb(vatFE=vat indFE=indqFE) cluster(vat)

// store coefficients
estimates store lnsales_fte_coef
keep if e(sample)
regsave using "tmp/reg_lnsales_fte", ci level(95) replace
	
// create graph with results	
use "tmp/reg_lnsales_fte", clear
drop if var=="_cons"
drop if stderr ==0
gen t=.
forv k=1/7 {
	replace t = -`k' if var=="I_pre`k'"
	replace t = `k' if var=="I_post`k'"
}
drop if var == "furl_ratio_ev"

// figure 7
twoway (scatter coef t) (rspike ci_lower ci_upper t, legend(label(1 "Coefficient")) legend(label(2 "95% CI"))), yline(0) xlabel(-4(1)7) ylabel(-0.10(0.05)0.10) xtitle("") graphregion(fcolor(white)) name("lnsales_fte", replace) 
*graph export "results/EER-D-22-01148_Figure_7.eps", replace

clear

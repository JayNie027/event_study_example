
clear all 

cd "D:\ThomasJun\dif-dif-event"

use bacon_example, clear

/* 
the data comes from Stevenson and Wolfers 2006 by way of Clarke and Schythe 2020 who use 
it as an example to demostrate Goodman-Bacon effects.
This data is a balanced panel from 1964 through 1996 of the United States no fault divorce reforms and
female suicide rates.

_nfd: the year the law implemented for states 
pcinc asmrh cases are controls 
 */
 
* create the lag/lead for treated states
* fill in control obs with 0
* This allows for the interaction between `treat` and `time_to_treat` to occur for each state.
* Otherwise, there may be some NAs and the estimations will be off.
g time_to_treat = year - _nfd
replace time_to_treat = 0 if missing(_nfd)
* this will determine the difference
* btw controls and treated states
g treat = !missing(_nfd)

* Stata won't allow factors with negative values, so let's shift
* time-to-treat to start at 0, keeping track of where the true -1 is
summ time_to_treat
g shifted_ttt = time_to_treat - r(min)
summ shifted_ttt if time_to_treat == -1
local true_neg1 = r(mean)

* Regress on our interaction terms with FEs for group and year,
* clustering at the group (state) level
* use ib# to specify our reference group
reghdfe asmrs ib`true_neg1'.shifted_ttt pcinc asmrh cases, a(stfips year) vce(cluster stfips)

***************************************************	Plots ******************************************
* Pull out the coefficients and SEs
g coef = .
g se = .

levelsof shifted_ttt, l(times)
foreach t in `times' {
	replace coef = _b[`t'.shifted_ttt] if shifted_ttt == `t'
	replace se = _se[`t'.shifted_ttt] if shifted_ttt == `t'
}

* Make confidence intervals
g ci_top = coef+1.96*se
g ci_bottom = coef - 1.96*se

* Limit ourselves to one observation per quarter
* now switch back to time_to_treat to get original timing
keep time_to_treat coef se ci_*
duplicates drop

sort time_to_treat

* Create connected scatterplot of coefficients
* with CIs included with rcap
* and a line at 0 both horizontally and vertically
summ ci_top
local top_range = r(max)
summ ci_bottom
local bottom_range = r(min)

twoway (sc coef time_to_treat, connect(line)) ///
	(rcap ci_top ci_bottom time_to_treat)	///
	(function y = 0, range(time_to_treat)) ///
	(function y = 0, range(`bottom_range' `top_range') horiz), ///
	xtitle("Time to Treatment") caption("95% Confidence Intervals Shown")
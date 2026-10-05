* Corporate Governance & Firm Performance - Panel Analysis
* Author: AmaaBel
* Sample: 69 firms (2020-2022)
* Models: Pooled OLS, FE, RE, PCSE, Robust/Clustered SE
 
clear all
set more off

* --- 1. Setup Panel ---
gen year = year(Date)
egen id = group(Name_of_stock)
xtset id year

* --- 2. Panel Effect: Breusch-Pagan LM Test ---
* H0: No panel effect (Pooled OLS sufficient)
* H1: Panel-specific effects exist
xtreg ROA FLID GD BOD_ind FA FS Lev Audit_q, re
xttest0
* If p<0.05 -> reject H0 -> panel effects exist -> go to Hausman

* --- 3. Hausman Test: FE vs RE ---
xtreg ROA FLID GD BOD_ind FA FS Lev Audit_q, fe
estimates store fixed
xtreg ROA FLID GD BOD_ind FA FS Lev Audit_q, re
estimates store random
hausman fixed random
* H0: RE appropriate (p>0.05)
* H1: FE appropriate (p<0.05)

* Interpretation Example:
* chibar2(01)=14.65, p=0.0001 -> Reject H0 -> panel effects exist
* chi2(12)=10.91, p=0.1428 -> Fail to reject H0 -> RE appropriate

* --- 4. Descriptive: Overall, Between, Within ---
xtsum ROA FLID GD BOD_ind FA FS Lev Audit_q

foreach var in ROA TQ FLID GD BOD_ind FA FS Lev Audit_q {
display "=== Summary for `var' ==="
summarize `var', detail
}

* Jarque-Bera Normality
foreach var in ROA TQ FLID GD BOD_ind FA FS Lev Audit_q {
display "=== Jarque-Bera for `var' ==="
sktest `var'
* or: jb6 `var' if you have user command
}

* --- 5. Correlations ---
* Between-firm (cross-sectional)
preserve
collapse (mean) ROA TQ FLID GD BOD_ind FA FS Lev Audit_q, by(id)
corr ROA TQ FLID GD BOD_ind FA FS Lev Audit_q
restore

* Within-firm (after removing heterogeneity)
* xtcorr is not official, use manual:
* Spearman for non-normal data
spearman ROA TQ FLID GD BOD_ind FA FS Lev Audit_q

* Overall correlation
pwcorr ROA TQ FLID GD BOD_ind FA FS Lev Audit_q, sig obs star(all)

* --- 6. Transformations ---
foreach v in ROA TQ FLID GD BOD_ind FA FS Lev Audit_q {
egen `v'_std = std(`v')
}

* Note: log only if variable >0 ! ROA can be negative, so check first
* gen log_ROA = log(ROA) if ROA>0

* Winsorizing (deal with outliers)
* ssc install winsor
winsor ROA, gen(wins_ROA) p(0.01) highonly
winsor ROA, gen(wins_ROA2) p(0.01)

* --- 7. Regression Models ---
* OLS Robust
reg ROA FLID GD BOD_ind FA FS Lev Audit_q, vce(robust)
reg ROA FLID GD BOD_ind FA FS Lev Audit_q, vce(hc3)

* Panel RE with Robust & Clustered SE (RECOMMENDED)
xtreg ROA_std FLID_std GD_std BOD_ind_std FA_std FS_std Lev_std Audit_q_std, re vce(robust)
xtreg ROA_std FLID_std GD_std BOD_ind_std FA_std FS_std Lev_std Audit_q_std, re vce(cluster id)

* FE clustered
xtreg ROA FLID GD BOD_ind FA FS Lev Audit_q, fe vce(cluster id)

* Panel-Corrected SE (for cross-sectional dependence)
xtpcse ROA_std FLID_std GD_std BOD_ind_std FA_std FS_std Lev_std Audit_q_std, correlation(ar1)

* --- 8. Diagnostics ---
xtserial ROA FLID GD BOD_ind FA FS Lev Audit_q
estat hettest
estat imtest, white

* Project: Air Pollution Analysis - Malaysia (DOSM / DOE data)
* Author: AmaaBel | UKM Alumni | Economist
* Description: Panel econometrics for PM2.5 determinants
* Tools: Stata 17 - xtscc, mmqreg, heatplot
*******************************************************************************/

clear all
set more off

*--- 1. SETUP & DECLARE PANEL ---
* ssc install heatplot, xtscc, mmqreg - uncomment if needed
* ssc install xttest3, xtserial

import delimited "your_data.csv", clear
xtset Stationid Date

*--- 2. EXPLORATORY ANALYSIS ---
* Boxplot over years
graph box PM25, over(year) nooutsides title("PM2.5 Concentration by Year")
graph export "boxplot_PM25_year.png", replace

* Correlation Heatmap
correlate PM25 SO2 NO2 CO O3
matrix R = r(C)
heatplot R, cuts(-1 -0.6 -0.2 0 0.2 0.6 1) colors(Blues) values(format(%4.2f)) ///
aspectratio(1) ramp(left space(3) labels(-0.8 "Strong negative" 0 "No corr" 0.8 "Strong positive")) ///
title("Correlation Heatmap")

*--- 3. DATA TRANSFORMATION ---
* Wind direction to sin/cos to avoid circularity problem
gen WD_sin = sin(WD * _pi / 180)
gen WD_cos = cos(WD * _pi / 180)

* Lagged PM2.5
gen L_PM25 = L.PM25

*--- 4. BASELINE MODELS & DIAGNOSTICS ---
* POLS with diagnostics
reg PM25 L_PM25 SO2 NO2 CO O3
estat hettest
xtserial PM25 L_PM25 SO2 NO2 CO O3

* FE vs RE
xtreg PM25 SO2 NO2 O3 CO, fe
estimates store fixed
xtreg PM25 SO2 NO2 O3 CO, re
estimates store random
hausman fixed random

* FE with clustered SE + heteroskedasticity & serial correlation tests
xtreg PM25 L.PM25 SO2 NO2 O3 CO, fe vce(cluster Stationid)
xttest3
xtserial PM25 L.PM25 SO2 NO2 O3 CO

* Driscoll-Kraay for cross-sectional dependence (robust)
xtscc PM25 L.PM25 SO2 NO2 CO O3, fe
xtscc PM25 L.PM25 SO2 NO2 CO O3 i.year, fe

*--- 5. MAIN MODEL: MMQR - Machado & Santos Silva (2019) ---
mmqreg PM25 L_PM25 SO2 NO2 O3 CO TEMP HUMID WS WD_sin WD_cos, ///
absorb(Stationid year) q(10 20 30 40 50 60 70 80 90) cluster(Stationid)

*--- 6. WALD TESTS FOR QUANTILE HETEROGENEITY ---
* Test if coefficients are equal across quantiles
test [qtile_10]L_PM25 = [qtile_20]L_PM25 = [qtile_30]L_PM25 = [qtile_40]L_PM25 = [qtile_50]L_PM25 = [qtile_60]L_PM25 = [qtile_70]L_PM25 = [qtile_80]L_PM25 = [qtile_90]L_PM25
test [qtile_10]SO2 = [qtile_20]SO2 = [qtile_30]SO2 = [qtile_40]SO2 = [qtile_50]SO2 = [qtile_60]SO2 = [qtile_70]SO2 = [qtile_80]SO2 = [qtile_90]SO2
test [qtile_10]NO2 = [qtile_20]NO2 = [qtile_30]NO2 = [qtile_40]NO2 = [qtile_50]NO2 = [qtile_60]NO2 = [qtile_70]NO2 = [qtile_80]NO2 = [qtile_90]NO2

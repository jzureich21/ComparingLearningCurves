
clear all

//------------------------------------------------------------------------------
//PARAMETERS
set seed 24092021 //current date at the start of the project
local Directory "C:\Users\Jacob Zureich\Dropbox\Misc\BlogPost_Learning" // <== change this for your computer
local NumTrials = 10
local NumPeople = 200


//------------------------------------------------------------------------------
//CREATING THE DATASET
set obs `NumPeople'
gen Person = _n
gen IV = [runiform() >= .5]
expand `NumTrials' 
bys Person: gen Trial = _n

label define IVl 0 "Left" 1 "Right" 
label values IV IVl

//explicitly specifying the mean of each point in the learning curve
matrix Means = (10, 70, 84, 89, 93, 96, 98, 99, 99.5, 100 \ 10, 10.5, 11, 12, 14, 17, 21, 36, 63, 100 \ 10, 20, 30, 40, 50, 60, 70, 80, 90, 100)
gen Performance =.
forvalues a = 1/`NumTrials' {
	replace Performance = rnormal(Means[1, `a'], 2) if IV == 0 & Trial == `a' //var=2 was arbitrary
	replace Performance = rnormal(Means[3, `a'], 2) if IV == 1 & Trial == `a'
}

//------------------------------------------------------------------------------
//GRAPHING SETTINGS
cd "`Directory'"
set scheme plotplainblind //s2color s1mono
grstyle init
grstyle color background white
grstyle yesno draw_major_hgrid no
graph set window fontface "Times New Roman"



//------------------------------------------------------------------------------
//FIGURE 1
local Thickness "medthick"
local Color1 "navy%100"
local Color2 "maroon%100"
local LowessType "bwidth(.2)" //.8 is default
twoway (scatter Performance Trial if IV == 0, mlcolor(`Color1') mfcolor(white)) || ////
       (lowess Performance Trial if IV == 0, lpattern(solid) lcolor(`Color1') lwidth(`Thickness') mfcolor(white) `LowessType'), ////
	   name(Left) legend(off) ytitle("Performance") title({bf:Left}, color(`Color1'))
twoway (scatter Performance Trial if IV == 1, mlcolor(`Color2') mfcolor(white)) || ////
       (lowess Performance Trial if IV == 1, lpattern(solid) lcolor(`Color2') lwidth(`Thickness') mfcolor(white) `LowessType'), ////
	   name(Right) legend(off) title({bf:Right}, color(`Color2'))
	   
gr combine Left Right, ycommon
graph export "Graphs_Left&Right.tif", replace 


//------------------------------------------------------------------------------
//FIGURE 2
preserve
gen Half2 = [Trial >= 6] + 1
collapse (mean) Performance, by(Person IV Half2)
twoway (scatter Performance Half2 if IV == 0, mlcolor(`Color1') mfcolor(white)) || ////
       (lowess Performance Half2 if IV == 0, lpattern(solid) lcolor(`Color1') mfcolor(white) `LowessType'), ////
	   name(Left_Halves) legend(off) ytitle("Performance") xtitle("Half") title({bf:Left}, color(`Color1')) xtick(1(1)2) xlabel(1(1)2)
twoway (scatter Performance Half2 if IV == 1, mlcolor(`Color2') mfcolor(white)) || ////
       (lowess Performance Half2 if IV == 1, lpattern(solid) lcolor(`Color2') mfcolor(white) `LowessType'), ////
	   name(Right_Halves) legend(off) xtitle("Half") title({bf:Right}, color(`Color2')) xtick(1(1)2) xlabel(1(1)2)
gr combine Left_Halves Right_Halves, ycommon
graph export "Graphs_Left&Right_Halves.tif", replace //width(3000)


//------------------------------------------------------------------------------
//STATS FOR FIGURE 2 (2ND HALF MINUS 1ST HALF)
reg Performance Half2##IV, vce(cluster Person)
margins, dydx(Half2) at(IV=(0 1))
restore


//------------------------------------------------------------------------------
//STATS FOR THE LINEAR TRENDS
reg Performance c.Trial##c.IV, vce(cluster Person)
margins, dydx(c.Trial) at(IV=(0 1))




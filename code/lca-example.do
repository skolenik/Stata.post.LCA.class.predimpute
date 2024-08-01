* example for the presentation

clear
input y1 y2 y3 Prob
	0 0 0 0.096
	0 0 1 0.084
	0 1 0 0.104
	0 1 1 0.116
	1 0 0 0.224
	1 0 1 0.096
	1 1 0 0.176
	1 1 1 0.104
end

gsem (y1 y2 y3 <-) [fw=Prob*1000], lclass(C 1) logit nodvheader nolog
estat lcmean
estat lcgof
qui gsem (y1 y2 y3 <-) [fw=Prob*1000], lclass(C 2) logit nodvheader nolog
estat lcmean
estat lcgof

predict post_1, classposterior class(1)
predict post_2, classposterior class(2)
list, sep(0) 

// postlca_class_predpute, lcimpute(lclass) addm(50) seed(20103)

expand Prob*1000
postlca_class_predpute, lcimpute(lclass) addm(50) seed(97054)
mi describe

mi estimate: mean y* , over(lclass)

// earlier: imputation on the 8 observations directly, went badly

mi xeq 1/50: mean y* , over(lclass)

cap noi mi estimate: mean y* [fw=Prob*1000], over(lclass)
cap noi mi estimate: reg y1 i.lclass

webuse nhanes2.dta, clear
qui svy , subpop(if hlthstat<8) : gsem (heartatk diabetes highbp <-, logit) ///
	(hlthstat <-, ologit) , lclass(C 2) nolog  startvalues(randomid, draws(5) seed(101)) 
est tab . , keep(highbp:1.C highbp:2.C heartatk:1.C heartatk:2.C)
	
postlca_class_predpute, lcimpute(lclass) addm(62) seed(9752)
mi estimate , dftable : prop race, over(lclass) 


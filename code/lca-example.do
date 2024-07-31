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

postlca_class_predpute, lcimpute(lclass) addm(50) seed(20103)
mi describe

local safelist 1 3 4 5 7 12 14 15 18 21 22 25 26 28 29 30 32 35 40 42 46 48 49 50

mi estimate, imp(`safelist'): mean y* [fw=Prob*1000], over(lclass)

cap noi mi estimate: mean y* [fw=Prob*1000], over(lclass)
cap noi mi estimate: reg y1 i.lclass



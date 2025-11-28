* Stas' internal: cd ../paper

version 19

cap log close
set rmsg off

sjlog using example_lca1, replace
frame change default
cap frame gsem_lca1: clear
cap frame drop gsem_lca1 
frame create gsem_lca1
frame change gsem_lca1

webuse gsem_lca1.dta, clear
describe
gsem (accident play insurance stock <-), logit lclass(C 2)
sjlog close, replace

sjlog using example_lca1_lcamean, replace
set rmsg on
estat lcprob
estat lcmean
set rmsg off
sjlog close, replace

sjlog using example_lca1_predpute, replace
set rmsg on
postlca_class_predpute, lcimpute(lclass) addm(10) seed(12345)
mi estimate : prop lclass
mi estimate : mean accident, over(lclass)
set rmsg off
sjlog close, replace

sjlog using example_lca1_modal, replace
webuse gsem_lca1.dta, clear
quietly gsem (accident play insurance stock <-), logit lclass(C 2)
predict post_1, class(1) classposterior
gen byte lclass_modal = 2 - (post_1 > 0.50)
mean post_1 lclass_modal
mean accident, over(lclass_modal)
sjlog close, replace

sjlog using nhanes2, replace
frame change default
cap frame nhanes2: clear
cap frame drop nhanes2
frame create nhanes2
frame change nhanes2

webuse nhanes2.dta, clear
svyset
svy , subpop(if hlthstat<8) : ///
	gsem ///
		(heartatk diabetes highbp <-, logit) ///
		(hlthstat <-, ologit) /// 
	, lclass(C 2) nolog  startvalues(randomid, draws(5) seed(101)) 
set rmsg on	
estat lcprob
estat lcmean
set rmsg off	
sjlog close, replace

sjlog using example_nhanes2_predpute, replace
set rmsg on
postlca_class_predpute, lcimpute(lclass) addm(10) seed(5678)
mi estimate : prop lclass
mi estimate : prop hlthstat if hlthstat < 8, over(lclass)
mi estimate : prop race, over(lclass)
set rmsg off
sjlog close, replace


sjlog using example_nhanes2_dftable10, replace
mi estimate , dftable : prop race, over(lclass) 
sjlog close, replace

sjlog using example_nhanes2_dftable62, replace
webuse nhanes2.dta, clear
qui svy , subpop(if hlthstat<8) : ///
	gsem ///
		(heartatk diabetes highbp <-, logit) ///
		(hlthstat <-, ologit) /// 
	, lclass(C 2) nolog  startvalues(randomid, draws(5) seed(101)) 
postlca_class_predpute, lcimpute(lclass) addm(62) seed(9752)
mi estimate , dftable : prop race, over(lclass) 
sjlog close, replace

sjlog using example_nhanes2_dftable62gh, replace
mi estimate , dftable : prop hlthstat if hlthstat < 8, over(lclass) 
sjlog close, replace

exit

* read all the simulation files
frame change default
cap frame simul_results: drop _all
cap frame drop simul_results
frame create simul_results
frame change simul_results

* identify and read all the files
local resultfiles : dir "../code" files "postlca-simul-*.dta"
foreach f in `resultfiles' {
    append using "../code/`f'"
}

sjlog using simul_failures, replace
tabulate method
sjlog close, replace

cap drop touse3
replace seed = rep if seed == .
bysort rep seed (method) : gen byte touse3 = (_N==3)
assert inlist(touse3, 0, 1)

* class probablities are biased
sjlog using simul_class1pr, replace
mean class1pr if touse3, over(n_method)
sjlog close, replace

* std errors are too small
sjlog using simul_class1pr_se, replace
bysort method (rep): sum class1pr if touse3
mean class1se if touse3, over(n_method)
sjlog close, replace

* variable in the model: target 0.3
sjlog using simul_y1cl2pr, replace
mean y1cl2pr if touse3 & y1cl2pr>0.01 & y1cl2pr<0.99, over(n_method)
sjlog close, replace

sjlog using simul_y1cl2pr_se, replace
bysort method (rep): sum y1cl2pr if touse3 & y1cl2pr>0.01 & y1cl2pr<0.99
mean y1cl2se if touse3 & y1cl2pr>0.01 & y1cl2pr<0.99, over(n_method)
sjlog close, replace

* variable in the model: target 0.5
sjlog using simul_y4cl1pr, replace
mean y4cl1pr if touse3 & y4cl1pr>0.01 & y4cl1pr<0.99, over(n_method)
sjlog close, replace

sjlog using simul_y4cl1pr_se, replace
bysort method (rep): sum y4cl1pr if touse3 & y4cl1pr>0.01 & y4cl1pr<0.99
mean y4cl1se if touse3 & y4cl1pr>0.01 & y4cl1pr<0.99, over(n_method)
sjlog close, replace

* variable not in the model: target 1
sjlog  using simul_y6cl1pr, replace
mean y6cl1pr if touse3, over(n_method)
sjlog close, replace

sjlog using simul_y6cl1pr_se, replace
bysort method (rep): sum y6cl1pr if touse3
mean y6cl1se if touse3, over(n_method)
sjlog close, replace

* variable not in the model: target sqrt(3) == 1.73
sjlog using simul_y6cl3pr, replace
mean y6cl3pr if touse3, over(n_method)
sjlog close, replace

sjlog using simul_y6cl3pr_se, replace
bysort method (rep): sum y6cl3pr if touse3
mean y6cl3se if touse3, over(n_method)
sjlog close, replace

*! v.0.1.0 postlca_class_predpute -- multiple imputation of latent classes after LCA
*! Stas Kolenikov https://github.com/skolenik/Stata.post.LCA.class.predimpute


* (iv) predictions	
forvalues k=1/$bigC {
	predict cl${bigC}post_`k', class(`k') classposterior
}

* (vi) imputations
* (vi.a) cumulative class probabilities
gen double cum_clprob_0 = 0 if !mi(cl${bigC}post_1)
forvalues k=1/$bigC {
	local k1 = `k'-1
	gen double cum_clprob_`k' = cum_clprob_`k1' + cl${bigC}post_`k' 
}

* (vi.b) imputation parameters
gen byte lclass = .
mi set wide
mi register imputed lclass
mi set M = 40
mi svyset [pweight=wgt], strata(lrptype)

* (vi.c) imputed variables
set seed 86030
est restore class${bigC}_v2_svy
forvalues m=1/`: char _dta[_mi_M]' {
	tempvar u_`m'
	gen `u_`m'' = uniform()
	quietly {
		forvalues k=1/$bigC {
			local k1 = `k'-1
			replace _`m'_lclass = `k' if cum_clprob_`k1' < `u_`m'' & `u_`m'' <= cum_clprob_`k' & e(sample)
		}
	}
}

* (vi.d) verify that the imputations are technically clean
mi update	
	
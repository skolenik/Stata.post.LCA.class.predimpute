*! v.0.1.0 postlca_class_predpute -- multiple imputation of latent classes after LCA
*! Stas Kolenikov https://github.com/skolenik/Stata.post.LCA.class.predimpute


program define postlca_class_predpute, rclass

	version 16

	syntax namelist(max=1 name=classvar id="latent class var"), /// 
		addm(int) [seed(real 0) ]

	* (i) check command
	if "`e(cmd)'" != "gsem" | "`e(lclass)'" == "" {
		di as err "gsem, lclass() LCA results not found"
		exit (301)
	}
	if colsof( e(lclass_k_levels)) > 1 {
		di as err "only one class variable is allowed"
		exit (198)
	}

	* (ii) defaults
	if `seed' != 0 {
		set seed `seed'
	}


	* (iii) # of classes
	local num_classes = el(e(lclass_k_levels), 1, 1)

	* (iv) predictions	
	forvalues k=1/`num_classes' {
		tempvar cl`num_classes'post_`k'
		predict `cl`num_classes'post_`k'', class(`k') classposterior
	}

	* (vi) imputations
	* (vi.a) cumulative class probabilities
	tempvar cum_clprob_0
	gen double `cum_clprob_0' = 0 if !mi(`prefix'`num_classes'post_1)
	forvalues k=1/`num_classes' {
		local k1 = `k'-1
		tempvar cum_clprob_`k'
		gen double `cum_clprob_`k'' = `cum_clprob_`k1'' + `cl`num_classes'post_`k'' 
	}

	* (vi.b) imputation parameters
	gen byte `classvar' = .
	mi set wide
	mi register imputed `classvar'
	mi set M = `addm'
	qui svyset
	if "`r(settings)'" != ", clear" {
		mi svyset `r(settings)'
	}

	* (vi.c) imputed variables
	forvalues m=1/`: char _dta[_mi_M]' {
		tempvar u_`m'
		gen double `u_`m'' = uniform()
		quietly {
			forvalues k=1/`num_classes' {
				local k1 = `k'-1
				replace _`m'_l`classvar' = `k' if ///
					`cum_clprob_`k1'' < `u_`m'' & `u_`m'' <= `cum_clprob_`k'' & e(sample)
			}
		}
	}

	* (vi.d) verify that the imputations are technically clean
	mi update	

	return add

end // of postlca_class_predpute

exit

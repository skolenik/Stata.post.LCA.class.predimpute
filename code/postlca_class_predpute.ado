*! v.0.1.0 postlca_class_predpute -- multiple imputation of latent classes after LCA
*! Stas Kolenikov https://github.com/skolenik/Stata.post.LCA.class.predimpute

/* START HELP FILE
title[a command to impute latent classes following gsem LCA]

desc[
 {cmd:postlca_class_predpute} produces multiply imputed latent class indicators.
]
opt[lcimpute() specifies the name of the latent class variable to be imputed.]
opt[addm() specifies the number of imputations to created.]
opt[seed() random number seed]

example[
 {webuse gsem_lca1.dta, clear}
 {gsem (accident play insurance stock <-), logit lclass(C 2)}
 {estat lcamean}
 {postlca_class_predpute, lcimpute(lclass) addm(10) seed(12345)}
 {mi estimate : mean accident, over(lclass)}
]

example[
 {webuse nhanes2, clear}
 {svy: gsem ( heartatk diabetes <-, logit) ( hlthstat <-, ologit) (hdresult <-, regress), lclass(C 2)}
 {* estat lcamean -- takes forever}
 {postlca_class_predpute, lcimpute(lclass) addm(10) seed(34567)}
 {mi estimate : mean bp*, over(lclass)}
]

author[Stas Kolenikov]
institute[NORC]
email[skolenik@gmail.com]

return[]

freetext[The variable whose name is provided in {lcimpute()} option
will be created but it will be missing for the entire sample.
Researchers should utilize the machinery of multiple imputation
for all analyses with the imputed latent classes.]

seealso[
{help mi_intro} Multiple imputation in Stata

{help sem_estat_lcmean} Class means for variables in the model

]


The help file is mostly automated with 

    makehlp, file(postlca_class_predpute) replace

END HELP FILE */

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
	qui svyset
	local svysettings `r(settings)'


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
	gen double `cum_clprob_0' = 0 if !mi(`cl`num_classes'post_1')
	forvalues k=1/`num_classes' {
		local k1 = `k'-1
		tempvar cum_clprob_`k'
		gen double `cum_clprob_`k'' = `cum_clprob_`k1'' + `cl`num_classes'post_`k'' 
	}

	* (vi.b) imputation parameters
	nobreak {
		gen byte `classvar' = .
		mi set wide
		mi register imputed `classvar'
		mi set M = `addm'
		if "`svysettings'" != ", clear" {
			mi svyset `svysettings'
		}

		* (vi.c) imputed variables
		forvalues m=1/`: char _dta[_mi_M]' {
			tempvar u_`m'
			gen double `u_`m'' = uniform()
			quietly {
				forvalues k=1/`num_classes' {
					local k1 = `k'-1
					replace _`m'_`classvar' = `k' if ///
						`cum_clprob_`k1'' < `u_`m'' & `u_`m'' <= `cum_clprob_`k'' & e(sample)
				}
			}
		}

		* (vi.d) verify that the imputations are technically clean
		mi update
	}	

	* (x) just in case mi update returns anything
	return add

end // of postlca_class_predpute

exit

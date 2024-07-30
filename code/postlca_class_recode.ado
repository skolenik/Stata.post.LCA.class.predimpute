*! v 0.1.0 swap classes after LCA -- Stas Kolenikov
program define postlca_class_recode

	version 16
	
	syntax anything(name=recode_classes equalok) [if] [in], [noise(real 0.05) loglevel(int 0)] 

	* (i) check command
	if "`e(cmd)'" != "gsem" | "`e(lclass)'" == "" {
		di as err "gsem, lclass() LCA results not found"
		exit (301)
	}
	if colsof( e(lclass_k_levels)) > 1 {
		di as err "only one class variable is allowed"
		exit (198)
	}
	marksample touse
	
	* (ii) 
	di _n "{txt}Predicting the modal class after LCA..."
	local num_classes = el(e(lclass_k_levels),1,1)

	tempvar best_pclass pred_class
    qui gen byte `pred_class' = .
	qui gen double `best_pclass' = 0 if `touse'
	
	forvalues c=1/`num_classes' {
		tempvar pclass`c'
		local pclass_varlist `pclass_varlist' `pclass`c''
		predict double `pclass`c'' if `touse', classposterior class(`c')
		
		qui replace `best_pclass' = `pclass`c'' if `touse' & (`best_pclass' < `pclass`c'')
		qui replace `pred_class' = `c' if `touse' & reldif(`best_pclass', `pclass`c'') < 100*c(epsdouble)
		
		if `loglevel' > 0 li `pred_class' `best_pclass' `pclass_varlist' if mod(_n,20)==0
	}
    
	* (iii)
	di "{txt}Recoding the classes..."
	recode `pred_class' `recode_classes'

	* (iii.a) deterministic imputation often ends up with too few classes
	qui levelsof `pred_class' if !mi(`pred_class')
	if `: word count `e(levels)'' < `num_classes' {
		di "{txt}Adding noise..."
		qui replace `pred_class' = ceil(runiform()*`num_classes') if runiform()<`noise'
		tab `pred_class'
	}
	* (iii.b) swap the e(b) names
	tempname b0
	mat `b0'=e(b)
	* (iii.c) reset the class estimates
	forvalues c=2/`num_classes' {
		mat `b0'[1,`c']=0
	}
	* (iii.d) swap the e(b) values
	local b0cnames : colfullnames `b0'
	local b0cnames : subinstr local b0cnames "bn.`e(lclass)'" ".`e(lclass)'", all
	local b0cnames : subinstr local b0cnames "b.`e(lclass)'" ".`e(lclass)'", all
	foreach statement of local recode_classes {
		gettoken par rest : statement, parse("(")
		assert "`par'"=="("
		gettoken main par : rest, parse(")")
		assert "`par'"==")"
		gettoken from rest : main, parse("=")
		gettoken eq to: rest, parse("=") 
		assert "`eq'"=="="
		confirm number `from'
		confirm number `to'
		
		local b0cnames : subinstr local b0cnames ":`from'.`e(lclass)'" ":subst`to'.`e(lclass)'", all
		if `loglevel' > 0 di "`b0cnames'"
	}
	local b0cnames : subinstr local b0cnames ":subst" ":", all
	mat colnames `b0' = `b0cnames'
	
	* (iv) 
	di "{txt}Re-running LCA..."
	* (iv.a) parse startvalues out of the command line
	local 0 `e(cmdline)'
	syntax anything(name=lclass_syntax), [startvalues(str) from(str) *]
	
	`lclass_syntax', `options' startvalues(classid `pred_class') from(`b0', skip)
	
end // of postlca_class_recode

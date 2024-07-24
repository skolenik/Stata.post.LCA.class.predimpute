* Simulation for postlca_class_predpute

* (i) Simulate data
cap program drop simulate_lca_sample
program define simulate_lca_sample

    syntax , n(integer) [ seed(integer 0) classprob(namelist min=1) ]

    drop _all 

    if "`seed'" != "0" {
        set seed `seed'
    }

    if "`classprob'" == "" {
        * this will be a matrix
        tempname classprob
        matrix `classprob' = (    ///
            0.7, 0.8, 0.5, 0.5, 0.8 \  ///
            0.3, 0.5, 0.4, 0.3, 0.4 \  ///
            0.6, 0.6, 0.7, 0.7, 0.3    ///
        )
    }

    set obs `n'

    gen byte class = floor( (_n-1) / (_N/2.5) ) + 1

    * outcome probabilities
    forvalues k=1/5 {
        gen byte y`k' = runiform() < `classprob'[class, `k']
    }

    gen double y6 = sqrt(class) + rnormal()

end // of simulate

* (ii) helper functions
cap pro drop postlca_deterministic
program define postlca_deterministic, rclass

    syntax // nothing

	if "`e(cmd)'" != "gsem" | "`e(lclass)'" == "" {
		di as err "gsem, lclass() LCA results not found"
		exit (301)
	}

    tempname lca    
    est store `lca'

    predict pclass1, classposterior class(1)
    predict pclass2, classposterior class(2)
    predict pclass3, classposterior class(3)

    gen byte pred_class = cond(pclass1 > pclass2 & pclass1 > pclass3, 1, ///
                        cond(pclass2 > pclass1 & pclass2 > pclass3, 2, 3))

    // class post
    mean ibn.pred_class
    local classpost (`=_b[1.pred_class]') (`=_se[1.pred_class]') ///
        (`=_b[2.pred_class]') (`=_se[2.pred_class]') ///
        (`=_b[3.pred_class]') (`=_se[3.pred_class]')

    // long ypost
    mean y* , over(pred_class)
    forvalues k=1/6 {
        forvalues c=1/3 {
            local ypost `ypost' (`=_b[c.y`k'@`c'.pred_class]') (`=_se[c.y`k'@`c'.pred_class]')
        }
    }

    est restore `lca'
    cap est drop `lca'

    return local topost "`classpost' `ypost' (.) (.)"

end // of postlca_deterministic

cap pro drop postlca_mi
program define postlca_mi, rclass

    syntax , m(integer)

	if "`e(cmd)'" != "gsem" | "`e(lclass)'" == "" {
		di as err "gsem, lclass() LCA results not found"
		exit (301)
	}

    tempname lca    
    est store `lca'

    // class post
    mi estimate , imp(1/5) post esampvaryok errorok nowarning : prop lclass, coeflegend
    local classpost (`=_b[1.lclass]') (`=_se[1.lclass]') ///
        (`=_b[2.lclass]') (`=_se[2.lclass]') ///
        (`=_b[3.lclass]') (`=_se[3.lclass]')    

    // ypost
    mi estimate , imp(1/`m') post esampvaryok errorok nowarning : mean y*, over(lclass) coeflegend
    forvalues k=1/6 {
        forvalues c=1/3 {
            local ypost `ypost' (`=_b[c.y`k'@`c'.lclass]') (`=_se[c.y`k'@`c'.lclass]')
        }
    }

    local e_df_min_mi = e(df_min_mi)
    local e_fmi_max_mi = e(fmi_max_mi)

    est restore `lca'
    cap est drop `lca'

    return local topost "`classpost' `ypost' (`e_df_min_mi') (`e_fmi_max_mi')" 

end // of postlca_mi5 

* (iii) try once
simulate_lca_sample, n(10000) seed(1234)
    
gsem (y1 y2 y3 y4 y5 <-), logit lclass(C 3) startvalues(classid class) difficult iter(50)

postlca_deterministic
di "`r(topost)'"

postlca_class_predpute, lcimpute(lclass) addm(50) seed(12345)

postlca_mi, m(5)
di "`r(topost)'"

postlca_mi, m(50)
di "`r(topost)'"

* (iii) best initial values
cap mat li b0
if _rc {
    clear
    simulate_lca_sample, n(1e6) seed(1234)
    gsem (y1 y2 y3 y4 y5 <-), logit lclass(C 3) startvalues(classid class) difficult ///
        tech(bhhh 50 dfp 20 bfgs 20 nr 100) iter(100) nonrtolerance
    mat b0 = e(b)
}

* (iv) Post set up

cap postclose topost
forvalues i=1/6 {
    forvalues j=1/3 {
        local ypost `ypost' y`i'cl`j'pr y`i'cl`j'se
    }
}

postfile topost ///
    int(rep) str12(method) ///
    double(class1pr class1se class2pr class2se class3pr class3se) ///
    double(`ypost') ///
    double(df_min_mi fmi_max_mi) ///
    using P:/COMMON/StasK/post.lca/postlca_simul, replace

* (v) simulate
timer clear 11
local reps = 50
forvalues r=1/`reps' {

    if `r'==1 _dots 0 0, reps(`reps') title("Simulation replications")

    timer on 11

    quietly {
        * (v.a) simulate the sample
        simulate_lca_sample, n(1000) seed(`r')
        
        * (v.b) run LCA
        cap ///
            gsem (y1 y2 y3 y4 y5 <-), logit lclass(C 3) nolog from(b0) ///
                startvalues(jitter 0.1, draws(10)) iter(100) difficult tech(bhhh 50 dfp 20 bfgs 20 nr 10) nonrtolerance 

        local rc_gsem = _rc
        if `rc_gsem' == 0 {

            * (v.c) deterministic
            cap postlca_deterministic
            local rc_post = _rc
            cap post topost (`r') ("deterministic") `r(topost)'
            local rc_post = _rc + `rc_post'

            * (v.d) imputed
            postlca_class_predpute, lcimpute(lclass) addm(50) seed(`r'`r')

            * (v.e) M=5
            cap postlca_mi, m(5)
            local rc_post = _rc + `rc_post'
            cap post topost (`r') ("predpute_5") `r(topost)'
            local rc_post = _rc + `rc_post'

            * (v.f) M=50    
            cap postlca_mi, m(50)
            local rc_post = _rc + `rc_post'
            cap post topost (`r') ("predpute_50") `r(topost)'
            local rc_post = _rc + `rc_post'
        }
        else if `_rc_gsem' == 1 exit 1
    }
    _dots `r' `=`rc_gsem'+`rc_post'', reps(`reps')

    timer off 11
}

* (vi) done with simulations
postclose topost
timer list 11

exit

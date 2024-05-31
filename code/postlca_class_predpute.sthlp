{smcl}
{* *! version 1.0 31 May 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "postlca_class_predpute##syntax"}{...}
{viewerjumpto "Description" "postlca_class_predpute##description"}{...}
{viewerjumpto "Options" "postlca_class_predpute##options"}{...}
{viewerjumpto "Remarks" "postlca_class_predpute##remarks"}{...}
{viewerjumpto "Examples" "postlca_class_predpute##examples"}{...}
{p2colset 1 15 17 2}{...}
{p2col:{bf:postlca_class_predpute} {hline 2}} impute latent classes following gsem LCA{p_end}

{marker syntax}{...}
{title:Syntax}
{p}{p_end}
{p 8 17 2}
{cmdab:postlca_class_predpute}
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Required }

{synopt:{opt lcimpute(varname)}}  specifies the name of the latent class variable to be imputed. {p_end}

{synopt:{opt addm(#)}}  specifies the number of imputations to created. {p_end}

{syntab:Optional}
{synopt:{opt seed(#)}} specifies the random number seed.{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
Following latent class analysis with Stata's official
{help gsem_lclass_options:gsem},
{cmd:postlca_class_predpute} produces multiply imputed latent class indicators
for the purposes of subsequent analyses where classes are involved 
as an explanatrory or a tabulation variable.
The variable whose name is provided in {cmd:lcimpute()} option
will be created but it will be missing for the entire sample.
Researchers should utilize the machinery of {help mi_estimate:multiple imputation}
for all analyses with the imputed latent classes.


{marker examples}{...}
{title:Examples}

{pstd}Official documentation example{p_end}
{phang2}{cmd:. webuse gsem_lca1.dta, clear}{p_end}
{phang2}{cmd:. gsem (accident play insurance stock <-), logit lclass(C 2)}{p_end}
{phang2}{cmd:. estat lcamean}{p_end}
{phang2}{cmd:. postlca_class_predpute, lcimpute(lclass) addm(10) seed(12345)}{p_end}
{phang2}{cmd:. mi estimate : mean accident, over(lclass)}{p_end}

{pstd}LCA with complex sample weights and variables outside of the model{p_end}
{phang2}{cmd:. webuse nhanes2, clear}{p_end}
{phang2}{cmd:. svy: gsem ( heartatk diabetes <-, logit) ( hlthstat <-, ologit) (hdresult <-, regress), lclass(C 2)}{p_end}
{phang2}{cmd:. * estat lcamean -- takes forever}{p_end}
{phang2}{cmd:. postlca_class_predpute, lcimpute(lclass) addm(10) seed(34567)}{p_end}
{phang2}{cmd:. mi estimate : mean bp*, over(lclass)}{p_end}

{title:Stored results}

{pstd}{cmd:postlca_class_predpute} does not store anything.{p_end}

{title:Author}
{p}

Stas Kolenikov, NORC.

https://github.com/skolenik/Stata.post.LCA.class.predimpute

{title:See Also}

{pstd}Related commands:{p_end}

{phang2}{help mi_intro:mi}: Multiple imputation in Stata{p_end}

{phang2}{help gsem_postestimation:gsem postestimation}: 
Latent class postestimation{p_end}



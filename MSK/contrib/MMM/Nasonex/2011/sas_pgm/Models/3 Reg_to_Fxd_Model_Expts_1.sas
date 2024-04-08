
/***************************************************************************
3. Explore OLS Regression to Fixed Effects Models Experiments
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1;

data mdl1;
  set rx.MODEL_DATA_v1;
  *pflunrxsh = pflunrx / pmktnrx;
  * Create indicator variables for yearmo;
  t1 = (yearmo="200908"); t2 = (yearmo="200909"); t3 = (yearmo="200910"); t4 = (yearmo="200911");
  t5 = (yearmo="200912"); t6 = (yearmo="201001"); t7 = (yearmo="201002"); t8 = (yearmo="201003");
  t9 = (yearmo="201004"); t10 = (yearmo="201005"); t11 = (yearmo="201006"); t12 = (yearmo="201007");
  t13 = (yearmo="201008"); t14 = (yearmo="201009"); t15 = (yearmo="201010"); t16 = (yearmo="201011");
  t17 = (yearmo="201012"); t18 = (yearmo="201101"); t19 = (yearmo="201102"); t20 = (yearmo="201103");
  t21 = (yearmo="201104"); t22 = (yearmo="201105"); t23 = (yearmo="201106"); t24 = (yearmo="201107");
run;
proc contents data=mdl1 varnum; run;
/*
* STORE AS PERMANENT DATASET;
data rx.MODEL_DATA_v1; set mdl1; run;
*/

%macro rtfopen(filename);
  options ls=75 ps=3000 nodate nocenter nonumber;
  ODS LISTING CLOSE;
  ODS RTF FILE="&PATH.\&filename." STYLE=JOURNAL BODYTITLE;
%mend rtfopen;
%macro rtfclose();
  ODS RTF CLOSE;
  ODS LISTING;
%mend rtfclose;

/*
STEP 1: OLS Regression exploration for some preliminary models.
  The basic assumption here is that the repeated observations for a given DMA 
  are independent. This assumption gives parameter standard errors that are less than
  true standard errors.
*/
options nolabel;
proc sort data=mdl1; by dma yearmo; run;
ODS OUTPUT PARAMETERESTIMATES=e2;
%rtfopen(step1_ols_ref.rtf)
proc reg data=mdl1 outest=out_est_2 tableout outsscp=sscp_2;
  model_a: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_b: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_c: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                           pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_d: model pnasnrx = t1 - t24 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
run;
quit;
%rtfclose();

*/RSQUARE VIF COLLIN CLB ALPHA=0.10;
PROC EXPORT DATA=e2
  OUTFILE= "&PATH.\step1_ols_reg_est.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "est";
RUN;

/*
STEP 2: Obtain Robust Standard Error estimates that correct for dependence 
    among the repeated observations. Also known as Huber-White standard errors,
    sandwich estimates, or empirical standard errors.
*/
%rtfopen(step2_robust_se.rtf)
proc sort data=mdl1; by dma yearmo; run;
proc genmod data=mdl1;
  class dma yearmo;
  model_a: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=ind;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_b: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=ind;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_c: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=ind;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_d: model pnasnrx = t1 - t24 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=ind;
run;
%rtfclose();

/*
STEP 3: Generalized Estimating Equations (GEE) 
 For linear models this is equivalent to feasible generalized least squares.
 The attraction of this method is that it produces EFFICIENT estimates of the 
 coefficients (i.e., the true standard errors will be optimally small). GEE does this by
 taking the over-time correlations into account when producing the estimates.
Note: Code is similar to above, except we introduce a "error correlation structure" in the
repeated statement. Option CORRW asks SAS to write out the estimated correlations
for the error term.
*/
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(step3_gee.rtf)
proc genmod data=mdl1;
  class dma yearmo;
  model_a1: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=UN CORRW;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_a2: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=EXCH CORRW;
run;

proc genmod data=mdl1;
  class dma yearmo;
  model_b1: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=UN CORRW;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_b2: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=AR(1) CORRW;
run;

proc genmod data=mdl1;
  class dma yearmo;
  model_c1: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=UN CORRW;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_c2: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=EXCH CORRW;
run;

proc genmod data=mdl1;
  class dma yearmo;
  model_d1: model pnasnrx = t1 - t24 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=UN CORRW;
run;
proc genmod data=mdl1;
  class dma yearmo;
  model_d2: model pnasnrx = t1 - t24 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50;
  repeated subject= dma / type=EXCH CORRW;
run;
%rtfclose();

/*
STEP 4: Random Effects Model  
 Expand the basic model by adding DMA specific error term to the model (Alpha(i)).
 This error term represents all differences between DMAs that are stable over time
 and not otherwise accounted for by time-invariant variables (like mc_nrp). It can be said to
 represent "unobserved heterogeneity". 
Assumption:
 This error term is normally distributed with mean 0 and a constant variance and is 
 uncorrelated with any other independent or error terms. 
Random effects models do nothing to control for unobservable variables because it 
is assumed to be uncorrelated with other variables.
Advantage is that it allows us to test if there are variations across DMAs even
after being accounted for other independent variables (i.e., like lag_nrx and population normalization).
NOTE: The Random Intercept model specification would lead to a model that is same as 
GEE with EXCH error structure (PROC GENMOD with REPEATED error structure as EXCH).
The Random Effects model allows us to test if variance of alpha(i) is zero. 
This is equivalent to testing for dependence among the observations. 
*/
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(step4_Random_Effects.rtf);
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_a: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_b: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept grpnas_60/ subject=dma;
run; *random intercept and grpnas_60;

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_c: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_d: model pnasnrx = t1 - t23 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept / subject=dma;
run;
%rtfclose();

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept lag_pnasnrx/ subject=dma;
run; *random intercept and lag_pnasnrx;

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept t1 - t23 / subject=dma;
run; *random intercept and time indicators;

/*
STEP 5: Fixed Effects Model  
 Expand the basic model by adding DMA specific CONSTANT term to the model (Alpha(i)).
 PROC GLM builds a simple fixed effects model. ABSORB statement centers all variables based on
 corresponding means for each DMA. In effect, this differences out DMA specific stable characteristics 
  (i.e., DMA specific constants).
Note: TSCSREG uses random effects model, but reports Haussmen test that compares
   Fixed Effect vs. Random Effects model. Lower p values indicates that Random Effects
   models should be rejected. 
*/
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(step5_Fixed_Effects.rtf);
proc glm data=mdl1;
  absorb dma;
  model_af1: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=mdl1;
  absorb dma;
  class semester;
  model_af2: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semester/ solution;
run; quit;
proc tscsreg data=mdl1;
  id dma yearmo;
  model_at1: model pnasnrx = workdays gen_all_launch lag_pnasnrx 
                           flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / ranone;
run;


proc glm data=mdl1;
  absorb dma;
  model_bf1: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
run; quit;
proc glm data=mdl1;
  absorb dma;
  class semester;
  model_bf2: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ 
         grpnas_60*semester/ solution;
run; quit;
proc tscsreg data=mdl1;
  id dma yearmo;
  model_bt1: model pnasnrx = t1 - t23 lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/  / ranone;
run;


proc glm data=mdl1;
  absorb dma;
  model_cf1: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/  / solution;
run; quit;
proc glm data=mdl1;
  absorb dma;
  class semester;
  model_cf2: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/  
         grpnas_60*semester/ solution;
run; quit;
proc tscsreg data=mdl1;
  id dma yearmo;
  model_ct1: model pnasnrx = t1 - t23 lag_pnasnrx pmktnrx pflunrxsh  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/  / ranone;
run;

proc glm data=mdl1;
  absorb dma;
  model_df1: model pnasnrx = t1 - t23 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
run; quit;
proc glm data=mdl1;
  absorb dma;
  class semester;
  model_df2: model pnasnrx = t1 - t23 mc_nrp  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/   
         grpnas_60*semester/ solution;
run; quit;
proc tscsreg data=mdl1;
  id dma yearmo;
  model_ct1: model pnasnrx = t1 - t23   
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/   / ranone;
run;
%rtfclose();

/*
STEP 6: Fixed Effects Model USING HYBRID METHOD  
 Hybrid method allows for giving fixed effects estimates as well as allows for
  testing parameter estimates for random vs. fixed effects for each parameter.
*/
* PREPARE MEANS AND DIFFERENCES for independent variables;
proc sort data=mdl1; by dma yearmo; run;
proc means data=mdl1 nway noprint;
  class dma;
  var workdays gen_all_launch mc_nrp lag_pnasnrx 
      flut_short_ind pmktnrx pflunrxsh
      detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
      t1 - t24;
  output out=meanfile 
    mean= m_workdays m_gen_all_launch m_mc_nrp m_lag_pnasnrx 
      m_flut_short_ind m_pmktnrx m_pflunrxsh
      m_detmd_30 m_sammd_80 m_grpnas_60 m_grpomn_60 m_grpotc_60 m_onl_score_50 
      m_t1 - m_t24;
data mdl1_hybrid;
  merge mdl1 meanfile;
  by dma;
  d_workdays = workdays - m_workdays; 
  d_gen_all_launch = gen_all_launch - m_gen_all_launch;
  d_mc_nrp = mc_nrp - m_mc_nrp; 
  d_lag_pnasnrx = lag_pnasnrx - m_lag_pnasnrx; 
  d_flut_short_ind = flut_short_ind - m_flut_short_ind; 
  d_pmktnrx = pmktnrx - m_pmktnrx; 
  d_pflunrxsh = pflunrxsh - m_pflunrxsh;
  d_detmd_30 = detmd_30 - m_detmd_30; 
  d_sammd_80 = sammd_80 - m_sammd_80; 
  d_grpnas_60 = grpnas_60 - m_grpnas_60; 
  d_grpomn_60 = grpomn_60 - m_grpomn_60; 
  d_grpotc_60 = grpotc_60 - m_grpotc_60; 
  d_onl_score_50 = onl_score_50 - m_onl_score_50;
  array ar_tind(*) t1 - t24;
  array ar_tind_m(*) m_t1 - m_t24;
  array ar_tind_d(*) d_t1 - d_t24;
  DO J=1 TO DIM(ar_tind);
     ar_tind_d(J) = ar_tind(J) - ar_tind_m(J);
  END;
  drop j;
run;

* Hybrid Models;
%rtfopen(step6_Hybrid_Models.rtf);
proc mixed data=mdl1_hybrid covtest noclprint; *empirical; 
  class dma yearmo;
  model_ah1: model pnasnrx = d_workdays m_workdays d_gen_all_launch m_gen_all_launch 
        d_mc_nrp m_mc_nrp d_lag_pnasnrx m_lag_pnasnrx 
        d_flut_short_ind m_flut_short_ind d_pmktnrx m_pmktnrx d_pflunrxsh m_pflunrxsh
        d_detmd_30 m_detmd_30 d_sammd_80 m_sammd_80 
        d_grpnas_60 m_grpnas_60  d_grpomn_60 m_grpomn_60 
        d_grpotc_60 m_grpotc_60 d_onl_score_50 m_onl_score_50   
         / solution;
  random intercept / subject=dma;
  contrast 'det' d_detmd_30 1 m_detmd_30 -1;
  contrast 'sam' d_sammd_80 1 m_sammd_80 -1;
  contrast 'grpnas' d_grpnas_60 1 m_grpnas_60 -1;
  contrast 'grpomn' d_grpomn_60 1 m_grpomn_60 -1;
  contrast 'grpotc' d_grpotc_60 1 m_grpotc_60 -1;
run;

proc mixed data=mdl1_hybrid covtest noclprint; *empirical; 
  class dma yearmo;
  model_bh1: model pnasnrx =  d_t1 - d_t23 m_t1 - m_t23 
        d_mc_nrp m_mc_nrp d_lag_pnasnrx m_lag_pnasnrx 
        d_detmd_30 m_detmd_30 d_sammd_80 m_sammd_80 
        d_grpnas_60 m_grpnas_60  d_grpomn_60 m_grpomn_60 
        d_grpotc_60 m_grpotc_60    
         / solution;
  random intercept / subject=dma;
  contrast 'det' d_detmd_30 1 m_detmd_30 -1;
  contrast 'sam' d_sammd_80 1 m_sammd_80 -1;
  contrast 'grpnas' d_grpnas_60 1 m_grpnas_60 -1;
  contrast 'grpomn' d_grpomn_60 1 m_grpomn_60 -1;
  contrast 'grpotc' d_grpotc_60 1 m_grpotc_60 -1;
run;

proc mixed data=mdl1_hybrid covtest noclprint; *empirical; 
  class dma yearmo;
  model_dh1: model pnasnrx =  d_t1 - d_t23 m_t1 - m_t23 
        d_mc_nrp m_mc_nrp  
        d_detmd_30 m_detmd_30 d_sammd_80 m_sammd_80 
        d_grpnas_60 m_grpnas_60  d_grpomn_60 m_grpomn_60 
        d_grpotc_60 m_grpotc_60    
         / solution;
  random intercept / subject=dma;
  contrast 'det' d_detmd_30 1 m_detmd_30 -1;
  contrast 'sam' d_sammd_80 1 m_sammd_80 -1;
  contrast 'grpnas' d_grpnas_60 1 m_grpnas_60 -1;
  contrast 'grpomn' d_grpomn_60 1 m_grpomn_60 -1;
  contrast 'grpotc' d_grpotc_60 1 m_grpotc_60 -1;
run;
%rtfclose();

* adhoc models;
proc glm data=mdl1;
  absorb dma;
  model_af1: model pnasnrx = workdays gen_all_launch mc_nrp /*lag_pnasnrx 
                           flut_short_ind */ pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;

proc mixed data=mdl1 covtest noclprint; 
  class dma semester yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept / subject=dma;
  random grpnas_60 / subject=semester;
run; *random intercept and grpnas_60;






proc mixed data=mdl1_hybrid covtest noclprint; *empirical; 
  class dma yearmo;
  model_bh1: model pnasnrx =  d_t1 - d_t23 m_t1 - m_t23 
        d_mc_nrp m_mc_nrp /*d_lag_pnasnrx m_lag_pnasnrx */
        d_detmd_30 m_detmd_30 d_sammd_80 m_sammd_80 
        d_grpnas_60 m_grpnas_60  d_grpomn_60 m_grpomn_60 
        d_grpotc_60 m_grpotc_60    
         / solution;
  random d_lag_pnasnrx/ subject=dma;
  contrast 'det' d_detmd_30 1 m_detmd_30 -1;
  contrast 'sam' d_sammd_80 1 m_sammd_80 -1;
  contrast 'grpnas' d_grpnas_60 1 m_grpnas_60 -1;
  contrast 'grpomn' d_grpomn_60 1 m_grpomn_60 -1;
  contrast 'grpotc' d_grpotc_60 1 m_grpotc_60 -1;
run;

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept pflunrx/ subject=dma;
run; *random intercept and grpnas_60;

data mdl2;
  set mdl1;
  pothnrx = pmktnrx - pnasnrx;
  pothnrxsh = pothnrx/pmktnrx;
run;
/*
* STORE AS PERMANENT DATASET;
data rx.MODEL_DATA_v1; set mdl2; run;
*/

proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept/ subject=dma;
run; 
proc mixed data=mdl2 covtest noclprint; 
  class dma yearmo;
  model_b3: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpotc_60 /*onl_score_50*/ / solution;
  random intercept/ subject=dma;
run; 
proc glm data=mdl2;
  absorb dma;
  model_bf1: model pnasnrx = t1 - t23 mc_nrp /*lag_pnasnrx*/ pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 /*onl_score_50*/ / solution;
run; quit;


proc orthoreg data=mdl1_hybrid;
  model_bh1: model pnasnrx =  d_t1 - d_t23 
        d_lag_pnasnrx d_
        d_detmd_30 d_sammd_80 
        d_grpnas_60  d_grpomn_60  d_grpotc_60;    
run;
quit;
proc reg data=mdl2 outest=out_est_2 tableout outsscp=sscp_2;
  model_a: model pnasnrx = workdays gen_all_launch mc_nrp /*lag_pnasnrx*/ 
                           pothnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_b: model pnasnrx = t1 - t24 mc_nrp /*lag_pnasnrx*/ pothnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
run;
quit;

proc reg data=mdl2 outest=out_est_2 tableout outsscp=sscp_2;
  model_a: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx
                           pothnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_a2: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx
                           pmktnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_a3: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx
                           pmktnrx pflunrxsh 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_a4: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx
                           pmktnrx pflunrxsh 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_a5: model pnasnrx = t1 - t23 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;

  model_b: model pnasnrx = t1 - t24 mc_nrp /*lag_pnasnrx*/ pothnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
run;
quit;

*Later, print these results;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_a1_ri: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_a2_ri: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx 
                          pothnrx  
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;

/*
GET PRINCIPAL COMPONENTS BETWEEN LAG_PNASNRX and POTHNRX
*/
proc sort data=mdl2; by dma yearmo; run;
proc princomp data=mdl2 out=pc1;
  var lag_pnasnrx pothnrx;
run;
proc means data=pc1; var lag_pnasnrx pothnrx prin1 prin2; run;
* note that pincipal components in output dataset (pc1) are standardized (mean 0 snd sd=1?);



/*
EXPLORE models with pothnrx (pothnrx = pmktnrx-pnasnrx)
*/
ODS OUTPUT PARAMETERESTIMATES=e2;
%rtfopen(mdlrerun_with_othnrx.rtf);
proc reg data=pc1 outest=out_est_2 tableout outsscp=sscp_2;
  model_ao0: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_ao1: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx 
                           pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_ao2: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx 
                           pothnrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_ao3: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp  
                           prin1 prin2
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_ao4: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp  
                           prin1 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;

  model_bo0: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_bo1: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_bo2: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_bo3: model pnasnrx = t1 - t24 mc_nrp prin1 prin2 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model_bo4: model pnasnrx = t1 - t24 mc_nrp prin1 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
run;
quit;

*/RSQUARE VIF COLLIN CLB ALPHA=0.10;
/*
PROC EXPORT DATA=e2
  OUTFILE= "&PATH.\step1_ols_reg_est.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "est_2";
RUN;
*/
/* RANDOM INTERCEPTS MODELS */
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_ao1: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo0: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo1: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo2: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;
proc mixed data=pc1 covtest noclprint empirical; 
  class dma yearmo;
  model_bo3: model pnasnrx = t1 - t24 mc_nrp prin1 prin2 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept / subject=dma;
run;

/* FIXED EFFECTS MODEL */
proc sort data=pc1; by dma yearmo; run;
proc glm data=pc1;
  absorb dma;
  model_ao1: model pnasnrx = workdays mar apr sep dec gen_all_launch mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=pc1;
  absorb dma;
  model_bo0: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=pc1;
  absorb dma;
  model_bo1: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=pc1;
  absorb dma;
  model_bo2: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=pc1;
  absorb dma;
  model_bo3: model pnasnrx = t1 - t24 mc_nrp prin1 prin2 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
proc glm data=pc1;
  absorb dma;
  model_bo1b: model pnasnrx = t1 - t24 mc_nrp pothnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
run; quit;
%rtfclose();




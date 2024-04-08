
/***************************************************************************
Explore OLS Regression Experiments
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;

data mdl1;
  set rx.MODEL_DATA_v1;
  pflunrxsh = pflunrx / pmktnrx;
run;
proc contents data=mdl1 varnum; run;
/*
* STORE AS PERMANENT DATASET;
data rx.MODEL_DATA_v1; set mdl1; run;
*/

/*
OLS Regression exploration for some preliminary models
*/
%let vList1 = workdays jan -- nov time_idx time_idx_sq time_idx_cu 
              flut_short_ind gen_all_launch 
              mc_nrp lag_pnasnrx pmktnrx pflunrx ;
%let vList2 = detmd_30 sammd_80 vcrmd_50 ;
%let mdlvars = grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score;
proc sort data=mdl1; by dma yearmo; run;
ODS OUTPUT PARAMETERESTIMATES=e2;
proc reg data=mdl1 outest=out_est_2 tableout outsscp=sscp_2;
  model1: model pnasnrx = &vList1. &vList2. &mdlvars. / vif ss2;
  model2: model pnasnrx = &vList1. &vList2.  grpnas_30 grpnas_30_sq grpomn_30 grpotc_30 onl_score / vif ss2;
  model3: model pnasnrx = &vList1. &vList2. grpnas_80 grpnas_80_sq grpomn_80 grpotc_80 onl_score / vif ss2;
  model4: model pnasnrx = &vList1. &vList2. grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model5: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx pmktnrx pflunrx
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model6: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx pmktnrx pflunrx
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpotc_60 onl_score_50 / vif ss2;
  model7: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx pflunrx
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model8: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx flut_short_ind pflunrx
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model9: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx flut_short_ind pmktnrx
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model10: model pnasnrx = workdays jan -- nov time_idx time_idx_sq time_idx_cu 
         flut_short_ind gen_all_launch mc_nrp lag_pnasnrx pmktnrx pflunrx / vif ss2;
  model11: model pnasnrx = workdays jan -- nov time_idx time_idx_sq time_idx_cu 
         flut_short_ind gen_all_launch mc_nrp lag_pnasnrx pmktnrx / vif ss2;
  model12: model pnasnrx = workdays jan -- nov time_idx time_idx_sq time_idx_cu 
         flut_short_ind gen_all_launch mc_nrp lag_pnasnrx pflunrx / vif ss2;
  model6b: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx pmktnrx pflunrx
         detmd_30 sammd_80 grpnas_60 grpotc_60 onl_score_50 / vif ss2;
  model6c: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx pmktnrx pflunrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model6d: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx flut_short_ind pmktnrx pflunrxsh
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model8b: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx flut_short_ind pflunrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;
  model9b: model pnasnrx = workdays gen_all_launch mc_nrp lag_pnasnrx flut_short_ind pmktnrx
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / vif ss2;

run;
quit;

*/RSQUARE VIF COLLIN CLB ALPHA=0.10;

PROC EXPORT DATA=e2
  OUTFILE= "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\reg_trial_est_1.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "est";
RUN;

/*
Score the datasets to understand if how prediction is affected by mktnrx and flunrx variables.
*/
proc means data=mdl1 nway mean std sum noprint;
  class yearmo;
  var workdays jan -- nov time_idx time_idx_sq time_idx_cu 
              flut_short_ind gen_all_launch mc_nrp 
      grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx lag_pnasnrx pmktnrx pflunrx pvernrx pomnnrx  
      detmd sammd vcrmd mc_nrp 
      detmd_30 sammd_30 vcrmd_30 grpnas_30 grpnas_30_sq grpomn_30 grpotc_30 grpadv_30
	  detmd_50 sammd_50 vcrmd_50 grpnas_50 grpnas_50_sq grpomn_30 grpotc_30 grpadv_30
      detmd_60 sammd_60 vcrmd_60 grpnas_60 grpnas_60_sq grpomn_60 grpotc_60 grpadv_60
      detmd_80 sammd_80 vcrmd_80 grpnas_80 grpnas_80_sq grpomn_80 grpotc_80 grpadv_80 ;
  output out = yearmo_means(drop=_type_ _freq_) mean= ; 
run;

proc score data=yearmo_means score=out_est_2 out=partial_scored_data
  type=parms PREDICT;
  var workdays jan -- nov time_idx time_idx_sq time_idx_cu 
              flut_short_ind gen_all_launch 
              mc_nrp lag_pnasnrx pmktnrx pflunrx;
run;

PROC EXPORT DATA=partial_scored_data
  OUTFILE= "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\reg_trial_partial_scored_1.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "partial_scored";
RUN;


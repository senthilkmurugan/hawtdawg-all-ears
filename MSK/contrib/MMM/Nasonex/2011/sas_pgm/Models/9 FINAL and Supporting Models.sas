
/***************************************************************************
9. FINAL and Supporting Models

Final Model: Random Intercepts model achieved indirectly through SP(EXP(TIME) covariance structure for repated measures.
In theory, this model has independent random intercepts and independent measurement error components.

Supporting Models:
S1. Full interations random intercepts model: to verify how promotional estimates changes during sem1 and sem2 for all promotions.
S2. Interaction model that differentiate 2011 vs other time periods: To answer if 2011 45 seconds GRPs have different impact.
S3. Fixed effects (Allison's) model that gets less biased estimates: To see if our RI model estimates are biased for TV GRP's
S4. Semi Parametric GAM model: To differentiate the sem1 and sem2 Nasonex GRP responsiveness and see the presence of any non-linear structure.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\FINAL;

* rtf output macros;
%macro rtfopen(filename);
  options ls=75 ps=3000 nodate nocenter nonumber;
  ODS LISTING CLOSE;
  ODS RTF FILE="&PATH.\&filename." STYLE=JOURNAL BODYTITLE;
%mend rtfopen;
%macro rtfclose();
  ODS RTF CLOSE;
  ODS LISTING;
%mend rtfclose;

data fnl_mdl_data;
  set rx.MODEL_DATA_v1;
  rtime = time_idx - 6;
run;
proc contents data=fnl_mdl_data varnum; run;
proc sort data=fnl_mdl_data; by dma yearmo; run;

/* store as permanent data set
data rx.FINAL_MODEL_DATA;
  set fnl_mdl_data;
run;
*/


/*****************************************************************************
MEANS AND STD DEVIATIONS FOR FINAL MODEL DATASET (with no utlier DMA's 626 and 798)
*******************************************************************************/
data fnl_mdl_data;
  set rx.FINAL_MODEL_DATA;
run;
/*MEANS*/
* BY Month;
proc sort data=fnl_mdl_data; by yearmo; run;
proc means data=fnl_mdl_data(where=(outlier_dma_ind=0)) nway mean std sum noprint;
  by yearmo;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx detmd sammd vcrmd mc_nrp 
      detmd_40 sammd_50 grpnas_50 grpomn_70 grpotc_60 grpnas_50_semS1 grpnas_50_semS2 t1 - t24 lag_pnasnrx semS1 semS2 spring fall ;
  output out = mn_fnl_month_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_fnl_month_means(keep=yearmo nasnrx_mean -- fall_mean) mn_fnl_month_std(keep=yearmo nasnrx_stddev -- fall_stddev) mn_fnl_month_sum(keep=yearmo nasnrx_sum -- fall_sum);
  set mn_fnl_month_1;
  output mn_fnl_month_means;   output mn_fnl_month_std;   output mn_fnl_month_sum;
run;

*OVERALL;
proc means data=fnl_mdl_data(where=(outlier_dma_ind=0)) nway mean std sum noprint;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx detmd sammd vcrmd mc_nrp 
      detmd_40 sammd_50 grpnas_50 grpomn_70 grpotc_60 grpnas_50_semS1 grpnas_50_semS2 t1 - t24 lag_pnasnrx semS1 semS2 spring fall ;
  output out = mn_fnl_all_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_fnl_all_means(keep=nasnrx_mean -- fall_mean) mn_fnl_all_std(keep=nasnrx_stddev -- fall_stddev) mn_fnl_all_sum(keep=nasnrx_sum -- fall_sum);
  set mn_fnl_all_1;
  output mn_fnl_all_means;   output mn_fnl_all_std;   output mn_fnl_all_sum;
run;

/******* FOR ALL DMA's (Including Outlier DMA's) ***********/
/*MEANS*/
* BY Month;
proc sort data=fnl_mdl_data; by yearmo; run;
proc means data=fnl_mdl_data nway mean std sum noprint;
  by yearmo;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx detmd sammd vcrmd mc_nrp 
      detmd_40 sammd_50 grpnas_50 grpomn_70 grpotc_60 grpnas_50_semS1 grpnas_50_semS2 t1 - t24 lag_pnasnrx semS1 semS2 spring fall ;
  output out = mn_full_month_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_full_month_means(keep=yearmo nasnrx_mean -- fall_mean) mn_full_month_std(keep=yearmo nasnrx_stddev -- fall_stddev) mn_full_month_sum(keep=yearmo nasnrx_sum -- fall_sum);
  set mn_full_month_1;    
  output mn_full_month_means;   output mn_full_month_std;   output mn_full_month_sum;
run;

*OVERALL;
proc means data=fnl_mdl_data nway mean std sum noprint;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx detmd sammd vcrmd mc_nrp 
      detmd_40 sammd_50 grpnas_50 grpomn_70 grpotc_60 grpnas_50_semS1 grpnas_50_semS2 t1 - t24 lag_pnasnrx semS1 semS2 spring fall ;
  output out = mn_full_all_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_full_all_means(keep=nasnrx_mean -- fall_mean) mn_full_all_std(keep=nasnrx_stddev -- fall_stddev)  mn_full_all_sum(keep=nasnrx_sum -- fall_sum);
  set mn_full_all_1;
  output mn_full_all_means;   output mn_full_all_std;   output mn_full_all_sum;
run;

/*
Export data to excel.
*/
%LET FILENAME=RAW_FINAL_MEANS_1.XLS;
%MACRO ExcelExport(indata,sheet_nm);
  PROC EXPORT DATA=&indata. OUTFILE="&PATH.\&FILENAME."  DBMS=EXCEL REPLACE; SHEET="&sheet_nm";  RUN;
%MEND ExcelExport;
%ExcelExport(mn_fnl_month_means,mn_fnl_month_means); %ExcelExport(mn_fnl_month_std,mn_fnl_month_std); %ExcelExport(mn_fnl_month_sum,mn_fnl_month_sum);
%ExcelExport(mn_fnl_all_means,mn_fnl_all_means); %ExcelExport(mn_fnl_all_std,mn_fnl_all_std); %ExcelExport(mn_fnl_all_sum,mn_fnl_all_sum);

%ExcelExport(mn_full_month_means,mn_full_month_means); %ExcelExport(mn_full_month_std,mn_full_month_std); %ExcelExport(mn_full_month_sum,mn_full_month_sum);
%ExcelExport(mn_full_all_means,mn_full_all_means); %ExcelExport(mn_full_all_std,mn_full_all_std); %ExcelExport(mn_full_all_sum,mn_full_all_sum);

/*  OVERALL MEANS
Variable              N            Mean         Std Dev         Minimum         Maximum
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
grpnas_50_semS1    4992     147.6041835     165.2160737               0     646.2445163
grpnas_50_semS2    4992      71.2645201     103.8620040               0     438.8991875
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
*/

/********************************************************
FINAL MODEL:
Random Intercepts model.
Note: Direct representation of RI model gives G matrix that is not positive definite and leads to the estimation of variance component for RI as 
close to 0. In effect, for internal computations this is like a model without RI component.
The spatial exponential covariance structure also has G as non positive definite. It predicts covariance parameters for 
  RI, Theta in spatial exponential structure and measurement error. The prediction leads to close to 0 theta but a valid
RI and Measurement Error components. Theta being clos to 0 leads to a 0 (or unpredicted) off diagonal elements in the resulting
covariance structure for repeated measures. In other words, this prediction indirectly leads to an RI model with independent structures
for RI and Measurement error components.
Observation of final conditional residuals (residuals taking into effect both fixed and random effects) of the model leads to 
a residual covariance structure (across time) with narrow bands across diagonal and correlations after 12 months (i.e., seasonal covariance).
This kind of structure could not be captured by most available repeated measurements covariance structures. Though UNRestricted (with SSCP)
option and Toeplitz structures may accomodate these covariance structure in theory, due to limited observations, there seems to be
some stability issues in covariance parameter estimates (as evidenced through manual look at covariance parameter and residual analysis 
after building such models). To mitigate the issues, "empirical" option was used to get an appropriate standard errors of parameter estimates
that take into account the resulting covariances in the residuals.
Influential observations: After conducting Influential Diagnstics, two DMA's 626 and 798 (both with very low Market rank) were removed
from the data. So the final model was built based on 208 DMA's and 24 months of observations (Aug/09 to Jul/11).

Why RI and not Fixed Effects model? The model was extended using Alison's idea on Fixed Effects model where only within DMA variations 
are used to get the best possible unbiased estimate. In this process we loose a lot of between variations that often leads to 
non-significant or very low estimates for other promotions like details and samples. FE models have a reasonable low impact changes on GRPs 
when compared to RI (Hausmann test of Hybrid Models). A decision was made to go with RI model and capture overall significane levels (though slightly biased)
for different promotional parameters and not loosing much accuracy on GRP estimates (though we see some small bias in NAS sem2 estimate when compared against 
FE and RI models of same parameters).
*********************************************************/
options nolabel;
proc sort data=fnl_mdl_data; by dma yearmo; run;
%rtfopen(FINAL_AND_SUPPORTING_MODEL_OUTPUTS.rtf);

* Outlier DMA's 626 and 798 are filtered out for final model; 
proc mixed data=fnl_mdl_data(where=(outlier_dma_ind=0))  covtest noclprint empirical; 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 
      / solution outpred=pred_FNL ;
   RANDOM intercept / subject=dma s;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
  
  contrast 'nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256; * significant;
  contrast 'diff' grpnas_50*semS1 1 grpnas_50*semS2 -1; * significant;
  contrast 'wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256; * significant;

  estimate 'e_nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256 / cl; 
  estimate 'e_diff' grpnas_50*semS1 1 grpnas_50*semS2 -1 / cl; 
  estimate 'e_wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256 / cl; 
run;
%LET FILENAME=RAW_FINAL_SUPPORTING_MODEL_ESTIMATES_1.XLS;
%ExcelExport(fit1,FNL_MDL_FIT);
%ExcelExport(fixed1,FNL_MDL_FIXED_EST);
%ExcelExport(random1,FNL_MDL_RAND_EST);

/*********************************************************
Supporting Models
*********************************************************/
/*
S1. Full interations random intercepts model: to verify how promotional estimates changes during sem1 and sem2 for all promotions.
*/
proc mixed data=fnl_mdl_data(where=(outlier_dma_ind=0))  covtest noclprint empirical; 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx*semS1 lag_pnasnrx*semS2  
                   detmd_40*semS1 detmd_40*semS2 sammd_50*semS1 sammd_50*semS2 grpomn_70*semS1 grpomn_70*semS2 grpotc_60*semS1 grpotc_60*semS2 
                   grpnas_50*semS1 grpnas_50*semS2 
      / solution outpred=pred_S1 ;
   RANDOM intercept / subject=dma s;
   *REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output fitstatistics=fitS1 solutionf=fixedS1 solutionr=randomS1;
  
  contrast 'nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256; * significant;
  contrast 'diff' grpnas_50*semS1 1 grpnas_50*semS2 -1; * significant;
  contrast 'wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256; * significant;
  estimate 'e_nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256 / cl; 
  estimate 'e_diff' grpnas_50*semS1 1 grpnas_50*semS2 -1 / cl; 
  estimate 'e_wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256 / cl; 
run;
%LET FILENAME=RAW_FINAL_SUPPORTING_MODEL_ESTIMATES_1.XLS;
%ExcelExport(fitS1,SUPP1_MDL_FIT);
%ExcelExport(fixedS1,SUPP1_MDL_FIXED_EST);
%ExcelExport(randomS1,SUPP1_MDL_RAND_EST);

/*
S2. Interaction model that differentiate 2011 vs other time periods: To answer if 2011 45 seconds GRPs have different impact.
*/
data trial2;
  set fnl_mdl_data;
  if sem2011_S1 = 1 then do; yr_11=1;yr_0910 = 0; end; else do; yr_11=0;yr_0910=1; end;
run;
proc mixed data=trial2(where=(outlier_dma_ind=0))  covtest noclprint empirical; 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*yr_0910  grpnas_50*yr_11 
      / solution outpred=pred_S2 ;
   RANDOM intercept / subject=dma s;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output fitstatistics=fitS2A solutionf=fixedS2A solutionr=randomS2A;
  
  contrast 'diff' grpnas_50*yr_0910 1 grpnas_50*yr_11 -1; 
  estimate 'e_diff' grpnas_50*yr_0910 1 grpnas_50*yr_11 -1 / cl; 
run;
%LET FILENAME=RAW_FINAL_SUPPORTING_MODEL_ESTIMATES_1.XLS;
%ExcelExport(fixedS2A,SUPP2A_MDL_FIXED_EST);
%ExcelExport(randomS2A,SUPP2A_MDL_RAND_EST);

proc mixed data=trial2(where=(outlier_dma_ind=0))  covtest noclprint empirical; 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 
                   grpnas_50*sem2009_S2  grpnas_50*sem2010_S1  grpnas_50*sem2010_S2 grpnas_50*sem2011_S1 
      / solution outpred=pred_S2 ;
   RANDOM intercept / subject=dma s;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output fitstatistics=fitS2B solutionf=fixedS2B solutionr=randomS2B;
run;
%LET FILENAME=RAW_FINAL_SUPPORTING_MODEL_ESTIMATES_1.XLS;
%ExcelExport(fixedS2B,SUPP2B_MDL_FIXED_EST);
%ExcelExport(randomS2B,SUPP2B_MDL_RAND_EST);

/*
S3. Fixed effects (Allison's) model that gets less biased estimates: To see if our RI model estimates are biased for TV GRP's
*/
proc glm data=fnl_mdl_data(where=(outlier_dma_ind=0));
  absorb dma;
  model pnasnrx = t1 - t23 lag_pnasnrx /*pothnrxsh*/
         detmd_40 sammd_50 grpomn_70 grpotc_60 
          grpnas_50*semS1 grpnas_50*semS2
      / solution;
  ods output parameterestimates=fxdeffS3A;
run; quit;
*model with competitor NRx share;
proc glm data=fnl_mdl_data(where=(outlier_dma_ind=0));
  absorb dma;
  model pnasnrx = t1 - t23 lag_pnasnrx pothnrxsh
         detmd_40 sammd_50 grpomn_70 grpotc_60 
          grpnas_50*semS1 grpnas_50*semS2
      / solution;
  ods output parameterestimates=fxdeffS3B;
run; quit;
%LET FILENAME=RAW_FINAL_SUPPORTING_MODEL_ESTIMATES_1.XLS;
%ExcelExport(fxdeffS3A,SUPP3A_MDL_EST);
%ExcelExport(fxdeffS3B,SUPP3B_MDL_EST);

/*
S4. Semi Parametric GAM model: To differentiate the sem1 and sem2 Nasonex GRP responsiveness and see the presence of any non-linear structure.
*/
* Build Scoring Dataset;
proc summary data=fnl_mdl_data(where=(outlier_dma_ind=0));
var t1 - t24 mc_nrp lag_pnasnrx 
         detmd_40 sammd_50 grpnas_60 grpomn_70 grpotc_60 onl_score_50 grpnas_50
         grpnas_50_semS1  grpnas_50_semS2  
         sems1 sems2 spring fall; 
output out=sm_mdl_data_1 mean=;
run;
data score_data(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 600 by 10;
    grpnas_50 = i;
	semS1=1; semS2=0; grpnas_50_semS1=grpnas_50; grpnas_50_semS2=0; output;
	semS1=0; semS2=1; grpnas_50_semS1=0; grpnas_50_semS2=grpnas_50; output;
  end;
run;
proc sort data=score_data; by semS2 grpnas_50; run;

ods graphics on;
proc gam data=fnl_mdl_data(where=(outlier_dma_ind=0)) plots(unpack)=components(commonaxes additive clm); 
  model pnasnrx = param(t1 - t23 mc_nrp lag_pnasnrx detmd_40 sammd_50  grpomn_70 grpotc_60) 
          spline(grpnas_50_semS1,df=4) spline(grpnas_50_semS2,df=4) 
          /*spline(grpnas_50_semS1) spline(grpnas_50_semS2) */
        / method = GCV ;
  ods output gam.ParameterEstimates = gam_par_est;
  score data=score_data out=score_gam_out;
run;
ods graphics off;
data score_gam_out_2;
  set score_gam_out;
  retain gp_pnasnrx_ini_0;
  if grpnas_50 = 0 then do;
      gp_pnasnrx_ini_0 = p_pnasnrx; 
  end;
  gp_incr_pnasNRx = p_pnasnrx  - gp_pnasnrx_ini_0;
run;

%ExcelExport(gam_par_est,SUPP4_GAM_LINEAR_EST);
%ExcelExport(score_gam_out_2,SUPP4_SCORED_OUTPUT);

%rtfclose();





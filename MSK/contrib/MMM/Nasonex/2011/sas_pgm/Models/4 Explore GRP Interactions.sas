
/***************************************************************************
4. Explore periodic GRP impacts through selected RI model.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\GRPInteractions;

data mdl1;
  set rx.MODEL_DATA_v1;
run;
proc contents data=mdl1 varnum; run;

data mdl2;
  set mdl1;
  * semester indicators;
  sem2009_S2 = (semester="2009_S2"); sem2010_S1 = (semester="2010_S1");
  sem2010_S2 = (semester="2010_S2"); sem2011_S1 = (semester="2011_S1");
  semS1 = (sem2010_S1+sem2011_S1 > 0); semS2 = (sem2009_S2+sem2010_S2 > 0);
  * spring, fall period flags;
  spring = (mar+apr+may > 0);  fall = (sep+oct > 0);
  * cubic and other terms for nas grp;
  grpnas_60_cu = grpnas_60_sq * grpnas_60;
  grpnas_60_sqrt = sqrt(grpnas_60);
run;
proc sort data=mdl2; by dma yearmo; run;

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
* Revised Random Intercept Model - Explore seasonal NAS GRP interactions;
*/
options nolabel;
%rtfopen(Revised_Model_periodic_GRP_impacts.rtf);
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*sem2011_S1/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS1/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS2/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*spring/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*fall/ solution;
  random intercept / subject=dma;
run;
%rtfclose();

/*
 Previous Structure Random Intercept Model - Explore seasonal NAS GRP interactions;
*/
%rtfopen(Prev_Model_periodic_GRP_impacts.rtf);
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_p: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*sem2011_S1/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_p: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS1/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_p: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*semS2/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_p: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*spring/ solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_p: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         grpnas_60*fall/ solution;
  random intercept / subject=dma;
run;
%rtfclose();


/* further explore revised model interactions */
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 
         detmd_30*semS2 sammd_80*semS2 grpnas_60*semS2 grpomn_60*semS2 
         grpotc_60*semS2 onl_score_50*semS2 lag_pnasnrx*semS2 / solution outpm=res_f1;;
  random intercept / subject=dma;
run;
PROC EXPORT DATA=res_f1(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_fm_int";
RUN;

PROC LOESS DATA=res_f1;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f1;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f1;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-3 TO 3 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;

/*
Interactions Trial 2.
*/
options nolabel;
%rtfopen(Rev_Mdl_addl_periodic_GRP_impacts_v2.rtf);
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 grpnas_60*semS1 grpnas_60*semS2
         / solution;
  random intercept / subject=dma;
  contrast 'grp_sem_tot'  grpnas_60*semS1 1 grpnas_60*semS2 1;
  contrast 'grp_sem_dif'  grpnas_60*semS1 1 grpnas_60*semS2 -1;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 grpnas_60 grpnas_60*spring grpnas_60*fall
         / solution;
  random intercept / subject=dma;
run;

proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx*semS1 lag_pnasnrx*semS2 
         detmd_30*semS1 detmd_30*semS2 sammd_80*semS1 sammd_80*semS2 grpomn_60*semS1 grpomn_60*semS2 
         grpotc_60*semS1 grpotc_60*semS2 onl_score_50 grpnas_60*semS1 grpnas_60*semS2
         / solution;
  random intercept / subject=dma;
run;
%rtfclose();

/* further explore residuals of model with sem1 and sem2 interactions */
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50          
         grpnas_60*semS1 grpnas_60*semS2 / solution outpm=res_f2;
  random intercept / subject=dma;
run;
PROC EXPORT DATA=res_f2(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals_v2.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_fm_s1s2";
RUN;

PROC LOESS DATA=res_f2;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f2;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-3 TO 3 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_f2 
  OUTFILE= "&PATH.\explore_mdl_residuals_v2.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "loess_res_fm_s1s2";
RUN;


/*
GRPNAS with higher order polynomials and orthogonal transformations (Legendre Functions).

Legendre Functions (Orthogonal Functions):
A variable "x" could be translated to following orthogonal functions
Order 1: x
Order 2: 0.5*(3*x*x - 1)
Order 3: 0.5*(5*x*x*x - 3*x)
for more orders and details, refer to: http://en.wikipedia.org/wiki/legandre_polynomials
*/
options nolabel;
%rtfopen(Polynomial_GRP_impacts.rtf);
*sq;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq  grpomn_60 grpotc_60 onl_score_50 
         / solution;
  random intercept / subject=dma;
run;
*cu;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpnas_60_sq grpnas_60_cu grpomn_60 grpotc_60 onl_score_50 
         / solution;
  random intercept / subject=dma;
run;

data mdl2;
  set mdl2;
  * legendre polynomials;
  L1_grpnas_60 = grpnas_60;
  L2_grpnas_60 = 0.5*(3*grpnas_60*grpnas_60 - 1);
  L3_grpnas_60 = 0.5*(5*grpnas_60*grpnas_60*grpnas_60 - 3*grpnas_60);
run;

*Legendre - Order 2;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 L1_grpnas_60 L2_grpnas_60 
         / solution;
  random intercept / subject=dma;
run;
*Legendre - Order 3;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80  grpomn_60 grpotc_60 onl_score_50 L1_grpnas_60 L2_grpnas_60 L3_grpnas_60
         / solution;
  random intercept / subject=dma;
run;

* Log transformation;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 loggrpnas_60 
         / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_logpnasnrx 
         logdetmd_30 logsammd_80 loggrpomn_60 loggrpotc_60 loggrpnas_60 
         / solution;
  random intercept / subject=dma;
run;
%rtfclose();

* further lograthimic tests;
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_r: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 loggrpomn_60 loggrpotc_60 onl_score_50 loggrpnas_60 
         / solution;
  random intercept / subject=dma;
run;
proc mixed data=mdl2 covtest noclprint ;*empirical; 
  class dma yearmo;
  model_r: model pnasnrx = lag_logpnasnrx 
         logdetmd_30 logsammd_80 loggrpomn_60 loggrpotc_60 loggrpnas_60 
         / solution;
  *random intercept / subject=dma;
run;



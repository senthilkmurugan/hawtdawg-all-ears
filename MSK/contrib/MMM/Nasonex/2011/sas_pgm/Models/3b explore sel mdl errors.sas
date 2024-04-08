
/***************************************************************************
3b. Explore error structures of candidate RI model.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Residuals;

data mdl1;
  set rx.MODEL_DATA_v1;
run;
proc contents data=mdl1 varnum; run;
data mdl2; set mdl1; run;

/*
1. Candidate Full model to explore further.
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo0: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_f1;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_f1;
run;
PROC EXPORT DATA=res_f1(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_fullmdl";
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
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_f1 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "loess_res_fullmdl";
RUN;

PROC LOESS DATA=res_f1;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f1_2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f1_2;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;


/*
2. Full model  - NAS GRP.
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_boa: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_f2;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_f2;
run;
PROC EXPORT DATA=res_f2(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_nogrp";
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
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_f2 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "lo_res_nogrp";
RUN;

PROC LOESS DATA=res_f2;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f2_2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f2_2;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;

/*
3. Full model  - NAS GRP - t1 to t24.
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_boa: model pnasnrx = mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_f3;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_f3;
run;
PROC EXPORT DATA=res_f3(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_nogrp_not";
RUN;

PROC LOESS DATA=res_f3;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f3;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f3;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_f3 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "lo_res_nogrp_not";
RUN;

PROC LOESS DATA=res_f3;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f2_3;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f2_3;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;

/*
4. Prev model - with mar apr sep dec.
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_boa: model pnasnrx = workdays mar apr sep dec mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_p1;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_p1;
run;
PROC EXPORT DATA=res_p1(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_prevmdl";
RUN;

PROC LOESS DATA=res_p1;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_p1;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_p1;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "PREV Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_p1 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "lo_res_prevmdl";
RUN;

PROC LOESS DATA=res_p1;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_p1_2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_p1_2;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "PREV Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;

/*
5. Full model + Competitor NRx.
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_boa: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx pothnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_fo1;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_fo1;
run;
PROC EXPORT DATA=res_fo1(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_fm_withothnrx";
RUN;

PROC LOESS DATA=res_fo1;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_fo1;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_fo1;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_fo1 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "lo_res_withothnrx";
RUN;

PROC LOESS DATA=res_fo1;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_fo1_2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_fo1_2;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "PREV Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;

/*
6. FULL MODEL - [t1 to t24]
*/
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo0: model pnasnrx = mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution outpm=res_f6;
  random intercept / subject=dma;
  ODS OUTPUT FITSTATISTICS=fit_f6;
run;
PROC EXPORT DATA=res_f6(keep=dma yearmo time_idx grpnas_60 pnasnrx pred resid)
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "res_fm_not";
RUN;

PROC LOESS DATA=res_f6;
     MODEL resid=grpnas_60/SMOOTH=.1;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f6;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f6;
   PLOT depvar*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*grpnas_60 / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=0 TO 450 BY 50; * grpnas_60 scale;
   LABEL GRPNAS_60="ADSTOCK";
   FORMAT GRPNAS_60 F5.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Adstock "; TITLE2 "Error Diagnostics";
RUN;
QUIT;
PROC EXPORT DATA=lo_stat_f6 
  OUTFILE= "&PATH.\explore_mdl_residuals.xls"
  DBMS=EXCEL97 REPLACE;
  SHEET = "loess_res_fm_not";
RUN;

PROC LOESS DATA=res_f6;
     MODEL resid=time_idx/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=lo_stat_f6_2;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "Error Diagnostics";
RUN;
PROC GPLOT DATA=lo_stat_f6_2;
   PLOT depvar*time_idx / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   PLOT2 pred*time_idx / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=-1 TO 1 BY 0.5; * original residual scale; 
   AXIS2 ORDER=7 TO 30 BY 1; * time scale;
   LABEL time_idx="TIME INDEX";
   FORMAT time_idx F2.0 DEPVAR F4.1 PRED F4.1;
   TITLE "Full Model: Residuals vs. Time "; TITLE2 "Error Diagnostics";
RUN;
QUIT;



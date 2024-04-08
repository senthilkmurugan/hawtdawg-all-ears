**********************************************************************;
* BASED UPON CODE FROM THE SAS CLASS "LONGITUDINAL DATA ANALYSIS W/  *;
* DISCRETE AND CONTINUOUS RESPONSES", THIS PROGRAM PRODUCES GRAPHICAL*;
* OUTPUT TO AID IN SELECTION OF AN APPROPRIATE COVARIANCE MATRIX     *;
* STRUCTURE FOR PROC MIXED ANALYSIS WITH REPEATED MEASURES.          *;
*                                                                    *;
* - 24 MONTHS OF SINGULAIR DATA ENDING DEC07 SUPPLIES THE TEST CASE  *;
* - POINT TO LOCATION OF VARIOGRAMMACRO AND VARIANCEMACRO PROGRAMS'  *;
*   PRIOR TO RUNNING AS THESE PROGRAMS ARE %INCLUDED IN THIS PROGRAM *;
* - UPDATE MACRO CALL, %LET STATEMENTS (TITLE,IVAR, DVAR, NMKTS,     *;
*   NMONTHS AND PATH) AND ANALYTIC DATASET NAME, BEFORE EXECUTION.   *;
* - INSURE THAT RTIME VARIABLE IS MONTH NUMBER IN FRONTWARDS ORDER   *;
*   STARTING WITH 1 AND ENDING WITH NMONTHS (UPDATE IN TEMPORARY     *;
*   ANALYTIC DATASET IF REQUIRED).                                   *;
*                                                                    *;
* - DESCRIPTIVE AND DIAGNOSTIC OUTPUT INCLUDES:                      *;
*   + HISTOGRAMS FOR THE IVAR AND EACH CANDIDATE DVAR WITH NORMAL    *;
*     OVERLAY                                                        *;
*   + SPAGHETTI CHART SHOWING TREND LINE FOR EACH SUBJECT OVER TIME W*;
*     OVERLAY OF AVERAGE TREND LINE ACROSS SUBJECTS                  *;
*   + SAMPLE VARIOGRAM DEPICTING DEGREE OF AUTOCORRELATION, PROCESS  *;
*     VARIANCE AND MEASUREMENT ERROR, IF ANY, OVER TIME              *;
*   + AUTOCORRELATION PLOT SHOWING PATTERN OF RESIDUAL COVARIANCES   *;
*     FOR PAIRS OF OBSERVATIONS BY DISTANCE IN TIME                  *;
*   + PLOT OF FIT CRITERIA (AIC, AICC, BIC) FOR CANDIDATE COVARIANCE *;
*     STRUCTURES GIVEN SATURATED (FULL) FIXED EFFECTS MODEL (ALL     *;
*     CANDIDATE IVS INCLUDED)                                        *;
**********************************************************************;

/*
Nov-09-2011: Code modified for 2011 Nasonex DTC analysis.
*/
/* 
This code has variograms for the selected model after xploring the half life's.
   objective is to see if the models could be improved by choosing an error covaiance structure for repeated measures. 
*/

/*PROC GREPLAY NOFS IGOUT=WORK.GSEG; DELETE _ALL_; RUN; QUIT;*/

%INCLUDE "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\sas_pgm\Models\Variograms\library\VARIOGRAMMACRO.SAS";
%INCLUDE "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\sas_pgm\Models\Variograms\library\VARIANCEMACRO.SAS";

LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

data mdl1;
  set rx.MODEL_DATA_v1;
run;
proc sort data=mdl1; by dma yearmo; run;

/*
proc mixed data=mdl2 covtest noclprint empirical; 
  class dma yearmo;
  model_bo0: model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpnas_60 grpomn_60 grpotc_60 onl_score_50 / solution;
  random intercept lag_pnasnrx / subject=dma;
run;
*/

%let vList1 = t1 - t24 mc_nrp lag_pnasnrx;
%let vList2 = detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2;

%MACRO PICKCOV(PROD);

*LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2010 profit plan\SAS datasets";
*LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\MSPJV\2009 PROFIT PLAN\&PROD.\SAS DATASETS\THRU DEC07";

%LET TITLE=&PROD DESCRIPTIVES AND DIAGNOSTICS FOR MIXED (DATA THRU Jul11);
%LET CLVAR= market rtime;  
%LET DVAR=pnasnrx;*OUTCOME VARIABLE;
%LET IVAR= &vlist1. &vlist2.;  
%LET NMKTS=210; *NUMBER OF DMAS IN ANALYTIC DATASET;
%LET NMONTHS=24; *NUMBER OF MONTHS TO BE ANALYZED;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Variograms\SelectedModel; *LOCATION FOR SAMPLE VARIOGRAM AND AUTOCORR PLOTS;
%LET MDLDSET=mdl1;

/*PROC CONTENTS DATA=out.mdl2; VARNUM; 
TITLE "DISPLAY CONTENTS OF ANALYTIC DATASET"; TITLE2 "&TITLE"; RUN;*/

DATA ANALYTIC(rename=(dma=market)); SET &mdldset;
  if yearmo >= "200908"; * consider 24 months from 200908 to 201107;
  * create a rtime variable that starts from 1 and increments by 1 upto the last month;
  rtime = time_idx - 6; * time var already has coded time, but starts with 7;
  * rename dma var to market;
  *replace dma = market; 
RUN;

proc freq data=analytic; tables yearmo*rtime / list missing; run;

PROC SORT DATA=ANALYTIC; BY MARKET RTIME; RUN;
/*
* BEGIN LOOP BY SPECIALTY;
PROC PRINT DATA=ANALYTIC (OBS=5); 
TITLE "PRINT FIRST 5 OBS "; TITLE2 "&TITLE"; RUN;

PROC UNIVARIATE DATA=ANALYTIC;
	VAR &DVAR &IVAR;
	HISTOGRAM/NORMAL;
	TITLE "DESCRIBE DV AND CANDIDATE IVS "; TITLE2 "&TITLE";
RUN;

PROC MEANS DATA=ANALYTIC; VAR RTIME; 
TITLE "EXPLORE TIME VARIABLE (RTIME) "; TITLE2 "&TITLE"; RUN;

GOPTIONS RESET=ALL;
FILENAME ODSOUT "&PATH";
ODS HTML BODY="&PROD SPAGHETTI CHART ...HTML" PATH=ODSOUT;
PROC GPLOT DATA=ANALYTIC;
   PLOT &DVAR*RTIME=MARKET/NOLEGEND;
   PLOT2 &DVAR*RTIME;
   SYMBOL1 V=NONE REPEAT=&NMKTS I=JOIN COLOR=CYAN;
   SYMBOL2 V=NONE I=SM60S COLOR=BLUE WIDTH=3;
   TITLE "DMA PROFILES OF POP NRMLZD NRX "; TITLE2 "&TITLE";
RUN;
QUIT;
ODS HTML CLOSE;
*/
OPTIONS MPRINT MERGENOBY=WARN;
TITLE "VARIOGRAM MACRO OUTPUT"; TITLE2 "&TITLE"; RUN;
%VARIOGRAM (DATA=ANALYTIC,RESVAR=&DVAR,CLSVAR=&CLVAR,EXPVARS=&IVAR,
			ID=MARKET,TIME=RTIME,MAXTIME=&NMONTHS);

TITLE "VARIANCE MACRO OUTPUT"; TITLE2 "&TITLE"; RUN;
%VARIANCE (DATA=ANALYTIC,ID=MARKET,
		   RESVAR=&DVAR,CLSVAR=&CLVAR,EXPVARS=&IVAR,
		   SUBJECTS=210,MAXTIME=&NMONTHS);

*SMOOTH NONPARAMETRIC CURVE (VARIOGRAM OVER TIME)*;
*VARIOGRAM VALUES ARE 1/2 SQUARED DIFFERENCES BETWEEN RESIDUALS FOR *;
*OBSERVATIONS DIFFERENT DISTANCES APART (WITHIN INDIV PTS AND BTWN PTS)*;
PROC LOESS DATA=VARIOPLOT;
     MODEL VARIOGRAM=TIME_INTERVAL/SMOOTH=.5;*DEGREE=2;
     ODS OUTPUT OUTPUTSTATISTICS=STAT;
	 TITLE "SMOOTH CURVE OVER 1/2 SQD DIFFS BTWN RESIDS BY DISTANCE"; TITLE2 "&TITLE";
RUN;

PROC MEANS DATA=STAT; VAR DEPVAR PRED TIME_INTERVAL; 
TITLE "DESCRIBE DEPVAR, PREDICTED VALUE AND TIME_INTERVALS"; TITLE2 "&TITLE"; RUN; 

DATA _NULL_; SET AVERAGE_VARIANCE;
	CALL SYMPUT('AVGVAR',STRIP(AVERAGE)); RUN; QUIT;

GOPTIONS RESET=ALL;
FILENAME ODSOUT "&PATH";
ODS HTML BODY="NAS SAMPLE VARIOGRAM ...HTML" PATH=ODSOUT;
PROC GPLOT DATA=STAT;
   PLOT DEPVAR*TIME_INTERVAL / VAXIS=AXIS1 HAXIS=AXIS2 VREF=&AVGVAR;
   PLOT2 PRED*TIME_INTERVAL / VAXIS=AXIS1 HAXIS=AXIS2;
   SYMBOL VALUE=STAR COLOR=CYAN;
   SYMBOL2 V=NONE I=SM70S COLOR=BLUE WIDTH=3;
   AXIS1 ORDER=0 TO 100 BY 10; * VARIOGRAM (DEPVAR) SCALE FOR PCPS (scale 70); 
   AXIS2 ORDER=1 TO &NMONTHS BY 1; * RTIME SCALE;
   LABEL TIME_INTERVAL="TIME INTERVAL";
   FORMAT TIME_INTERVAL F3.1 DEPVAR F4.1 PRED F4.1;
   TITLE "SAMPLE VARIOGRAM OF MIXED DATA "; TITLE2 "&TITLE";
RUN;
QUIT;
ODS HTML CLOSE;

DATA STAT;
   SET STAT;
   AUTOCORR=1-(PRED/&AVGVAR);
RUN;

PROC MEANS DATA=STAT; VAR AUTOCORR TIME_INTERVAL; 
TITLE "DESCRIBE AUTOCORRELATION ACROSS TIME"; TITLE2 "&TITLE"; RUN;

GOPTIONS RESET=ALL;
FILENAME ODSOUT "&PATH";
ODS HTML BODY="NAS AUTOCORR PLOT ...HTML" PATH=ODSOUT;
PROC GPLOT DATA=STAT;
   PLOT AUTOCORR*TIME_INTERVAL / VAXIS=AXIS1 HAXIS=AXIS2 VREF=0;
   SYMBOL V=NONE I=SM60S;
   AXIS1 ORDER=-1 TO 1 BY .1;
   AXIS2 ORDER=0 TO &NMONTHS BY 1;
   LABEL TIME_INTERVAL="TIME INTERVAL" AUTOCORR="AUTOCORRELATION";
   FORMAT TIME_INTERVAL F3.1 AUTOCORR F4.1;
   TITLE "AUTOCORR PLOT OF MIXED DATA "; TITLE2 "&TITLE";
RUN;
QUIT;
ODS HTML CLOSE;

*ODS LISTING CLOSE;
PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
	MODEL &DVAR=&IVAR  / solution;
   *RANDOM intercept / subject=market;
   REPEATED rtime/ TYPE=CS SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=CSMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR  / solution;
	*RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=UN SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=UNSTMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR  / solution;
	*RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=UN SUBJECT=MARKET rcorr sscp;
   ODS OUTPUT FITSTATISTICS=UNSSCPMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=SP(POW)(RTIME) SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=POWMODEL;
RUN;

PROC MIXED DATA=ANALYTIC maxiter=1000 covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=SP(LIN)(RTIME) SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=LINMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=EXPMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=SP(GAU)(RTIME) SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=GAUMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET rtime;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED rtime/ TYPE=SP(SPH)(RTIME) SUBJECT=MARKET rcorr;
   ODS OUTPUT FITSTATISTICS=SPHMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET RTIME;
    MODEL &DVAR=&IVAR / solution;
	*RANDOM intercept / subject=market;
    REPEATED RTIME/ TYPE=AR(1) SUBJECT=MARKET rcorr;
    ODS OUTPUT FITSTATISTICS=ARMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET RTIME;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED RTIME/ TYPE=AR(1) SUBJECT=MARKET rcorr;
    ODS OUTPUT FITSTATISTICS=ARMODEL2;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET RTIME;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED RTIME/SUBJECT=MARKET TYPE=ARMA(1,1) rcorr;
    ODS OUTPUT FITSTATISTICS=ARMAMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET RTIME;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED RTIME/ TYPE=TOEP SUBJECT=MARKET rcorr;
    ODS OUTPUT FITSTATISTICS=TOEMODEL;
RUN;

PROC MIXED DATA=ANALYTIC covtest;
	CLASS MARKET RTIME;
    MODEL &DVAR=&IVAR / solution;
	RANDOM intercept / subject=market;
    REPEATED RTIME/ TYPE=TOEP(5) SUBJECT=MARKET rcorr;
    ODS OUTPUT FITSTATISTICS=TOE5MODEL;
RUN;

*ODS LISTING;

DATA MODEL_FIT;
   LENGTH MODEL $ 7 TYPE $ 4;
   SET CSMODEL (IN=CS)
       /*UNSTMODEL (IN=UN)*/
	   UNSSCPMODEL (IN=UNSSCP)
       POWMODEL (IN=POW)
       EXPMODEL (IN=EXP)
	   LINMODEL (IN=LIN)
       GAUMODEL (IN=GAU)
       SPHMODEL (IN=SPH)
	   ARMODEL (IN=AR)
	   ARMODEL2 (IN=AR2)
	   TOEMODEL (IN=TOE)
	   ARMAMODEL (IN=ARMA)
	   TOE5MODEL (IN=TOE5); 
   IF SUBSTR(DESCR,1,1) IN ('A','B');
   IF SUBSTR(DESCR,1,3) = 'AIC' THEN TYPE='AIC';
   IF SUBSTR(DESCR,1,4) = 'AICC' THEN TYPE='AICC';
   IF SUBSTR(DESCR,1,3) = 'BIC' THEN TYPE='BIC';
   IF CS THEN MODEL='CS';
   *IF UN THEN MODEL='UN';
   IF UNSSCP THEN MODEL='UNSSCP';
   IF POW THEN MODEL='SPPOW';
   IF LIN THEN MODEL='SPLIN';
   IF EXP THEN MODEL='SPEXP';
   IF GAU THEN MODEL='SPGAU';
   IF SPH THEN MODEL='SPSPH';
   IF AR THEN MODEL='AR1';
   IF AR2 THEN MODEL='AR1M2';
   IF TOE THEN MODEL='TOEP';
   IF ARMA THEN MODEL='ARMA11';
   IF TOE5 THEN MODEL='TOEP5';

RUN;

* C2DEMO05B;
GOPTIONS RESET=ALL;
FILENAME ODSOUT "&PATH";
ODS HTML BODY="NAS FIT CHART ...HTML" PATH=ODSOUT;
PROC GPLOT DATA=MODEL_FIT;
   PLOT VALUE*MODEL=TYPE;
   SYMBOL1 VALUE=STAR COLOR=BLUE;
   SYMBOL2 VALUE=CIRCLE COLOR=RED;
   SYMBOL3 VALUE=DOT COLOR=GREEN;
   LABEL MODEL='COVARIANCE STRUCTURE';
   TITLE "MODEL FIT STATS BY COV STRUCTURE "; TITLE2 "&TITLE";
RUN;

QUIT;
ODS HTML CLOSE;

%MEND;
%PICKCOV(NAS);



/*
Explore residual error structures of selected models
outp gives residuals from all fixed and random effects.
outpm gives residuals from only fixed effects.
*/

proc sort data=analytic; by dma rtime; run;
proc mixed data=analytic;
   class market rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                     detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 / outp=res_outp_1 outpm=res_outpm_1 s;
   RANDOM intercept / subject=market;
   *REPEATED rtime/ TYPE=AR(1) SUBJECT=MARKET;
run;
proc mixed data=analytic;
   class market rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 / outp=res_outp_2 outpm=res_outpm_2 s;
   RANDOM intercept / subject=market;
   REPEATED rtime/ TYPE=AR(1) SUBJECT=MARKET rcorr;
run;
proc mixed data=analytic;
   class market rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 / outp=res_outp_3 outpm=res_outpm_3 s;
   RANDOM intercept / subject=market;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=MARKET rcorr;
run;
proc mixed data=analytic;
   class market rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 / outp=res_outp_4 outpm=res_outpm_4 s;
   *RANDOM intercept / subject=market;
   REPEATED rtime/ TYPE=UN SUBJECT=MARKET rcorr sscp;
run;

* means and stddev of residuals;
proc means data=res_outp_1; var resid; run; * outpm_1 has same values; *mn=0 sd=5.79;
proc means data=res_outp_2; var resid; run; * outpm_2 has same values; *mn=0 sd=5.8;
proc means data=res_outp_3; var resid; run; *mn=0 sd=5.05;
proc means data=res_outpm_3; var resid; run; * residuals from fixed effects only.; *mn=0 sd=8.6;
proc means data=res_outp_4; var resid; run; * outpm_4 has same values.; *mn=0 sd=5.79;



* get correlation across time;
proc transpose data=res_outp_1(keep=market rtime resid) out=tr_res_outp_1(drop=_name_ _label_);
by market; id rtime; var resid; run;
proc transpose data=res_outp_2(keep=market rtime resid) out=tr_res_outp_2(drop=_name_ _label_);
by market; id rtime; var resid; run;
proc transpose data=res_outp_3(keep=market rtime resid) out=tr_res_outp_3(drop=_name_ _label_);
by market; id rtime; var resid; run;
proc transpose data=res_outpm_3(keep=market rtime resid) out=tr_res_outpm_3(drop=_name_ _label_);
by market; id rtime; var resid; run;
proc transpose data=res_outp_4(keep=market rtime resid) out=tr_res_outp_4(drop=_name_ _label_);
by market; id rtime; var resid; run;



proc corr data=tr_res_outp_1 outp=corr_1; var _1 - _24; run; *not an AR structure. Reasonaly correlated across time;
proc corr data=tr_res_outp_2 outp=corr_2; var _1 - _24; run;  * only removes a minor amount of correlation from above. Not an appropriate structure.;
proc corr data=tr_res_outp_3 outp=corr_3; var _1 - _24; run; * though correlations across time are seen, this seems much better than the first model. Explore further.;
proc corr data=tr_res_outpm_3 outp=corr_fe3; var _1 - _24; run; * this option produces very high correlation across time.;
proc corr data=tr_res_outp_4 outp=corr_4; var _1 - _24; run; * though correlations across time are seen, this seems much better than the first model. Explore further.;

/*
Export data to excel.
*/
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Variograms\SelectedModel; *LOCATION FOR SAMPLE VARIOGRAM AND AUTOCORR PLOTS;
%MACRO ExcelExport(indata,sheet_nm);
  PROC EXPORT DATA=&indata. OUTFILE="&PATH.\resid_corrs_1.XLS"
	  DBMS=EXCEL REPLACE;
	  SHEET="&sheet_nm";
  RUN;
%MEND ExcelExport;

%ExcelExport(corr_1,fmi_corr_1);
%ExcelExport(corr_2,fmi_ar1_corr_2);
%ExcelExport(corr_3,fmi_sppow_corr_3);
%ExcelExport(corr_fe3,fmi_sppow_fxd_corr_3b);
%ExcelExport(corr_4,fmi_unsscp_corr_4);







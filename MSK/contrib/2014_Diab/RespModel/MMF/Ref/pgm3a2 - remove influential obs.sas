PROC PRINTTO LOG="\\WPUSHH01\DINFOPLN\Marketing Mix PI\MMF 2012\MMF\ZVTTOT\PGM3a2.LOG" NEW
             PRINT="\\WPUSHH01\DINFOPLN\Marketing Mix PI\MMF 2012\MMF\ZVTTOT\PGM3a2.LST" NEW;

**************************************************************;
*** REMOVE INFLUENTIAL OBS DETERMINED IN PGM3A1.SAS;
*** USED 3 METHODS: HIGH RESID, HIGH COOKD, & HIGH DFB_TESTFLG;
**************************************************************;
* 2-6-12 ADDED INTERACTIN TERMS TO MODEL DATA SET IN CASE NEEDED FOR MODELING LATER IN PROCESS;

*************************************************;
*** read cutoffs in from excel and apply to data ;
*************************************************;
%LET PROD=ZVTTOT;
%let title_prod=ZVTTOT;   /* USE PRODUCTS ACTUAL NAME RATHER THAN GRAIL NAME */
%let title_no=2; RUN;
*LIBNAME MMF "\\WPUSHH01\DINFOPLN\MARKETING MIX PI\MMF 2012\MMF\&PROD";
LIBNAME MMF "C:\E\MMF 2012\&PROD";
%LET PATH=\\WPUSHH01\DINFOPLN\MARKETING MIX PI\MMF 2012\MMF\&PROD; RUN;

proc import datafile="&PATH\INFL OBS CUTOFFS &PROD."
	out=Cutoffs dbms=excel REPLACE;
run;
Proc sort data=MMF.Results out=Results;
by helcode;
run;
Proc sort data=Cutoffs;
by helcode;
run;
data combined;
merge Results Cutoffs;
by helcode;
run;

DATA INF_RESID;  SET Combined (WHERE=(ABS_POIRESID>VALRES));  RUN; 
DATA INF_COOKD;  SET Combined (WHERE=(COOKD>VALCOOK));  RUN;
DATA INF_DFBET;  SET Combined (WHERE=(ABS_DFB_TESTFLG>VALDFB));  RUN;
  
DATA INFL_OBS;
  MERGE INF_RESID (IN=R) INF_COOKD (IN=C) INF_DFBET (IN=D);
  BY UNIQUE_ID;
  INRESID=R;
  INCOOKD=C;
  INDFBET=D;
  RUN;

PROC FREQ DATA=INFL_OBS;
TABLE INRESID INCOOKD INDFBET INRESID*INCOOKD*INDFBET / LIST MISSING;
TITLE2 'COMPARE INFL OBS METHODS';  RUN;

DATA MMF.INFLUENTIAL_OBS;
SET INFL_OBS (WHERE=(INRESID=1 OR INCOOKD=1 OR INDFBET=1));
RUN;

PROC FREQ DATA=MMF.INFLUENTIAL_OBS;  TABLES HELCODE*TESTFLG / LIST MISSING;
TITLE2 'INFLUENTIAL OBS REMOVED FROM DATA SET';  RUN;


** CREATE INTERACTION TERMS IN CASE THEY ARE NEEDED LATER WHEN MODELING;
DATA MMF.MODEL;
 MERGE Combined(IN=A) MMF.INFLUENTIAL_OBS(IN=I KEEP=UNIQUE_ID);
 BY UNIQUE_ID;
 IF A AND NOT I;
 TESTDET = TESTFLG*DET_POSTMEAN;
 TESTSAM = TESTFLG*SAM_POSTMEAN;
 TESTMFP = TESTFLG*MFP_POSTMEAN;
 RUN;

PROC FREQ DATA=MMF.MODEL;  TABLES HELCODE*TESTFLG / LIST MISSING;
TITLE2 'REVISED # OF T/C AFTER REMOVAL OF INFLUENTIAL OBSERVATIONS';  RUN;


**********************************************;
*** PLOT AFTER REMOVE INFLUENTIAL OBSERVATIONS;
**********************************************;
FILENAME ODSOUT "&PATH";
   ODS HTML BODY="&PROD._POST_INFLDIAGNSTC.HTML" PATH=ODSOUT;
SYMBOL INTERPOL=NONE VALUE=DOT HEIGHT=0.1;
FOOTNOTE " ";
PROC GPLOT DATA=MMF.MODEL;
BY HELCODE;
PLOT PROD_POSTMEAN*(DET_POSTMEAN SAM_POSTMEAN CLASS_PREMEAN_LOG PROD_PREMEAN_LOG);
TITLE2 'PLOTS AFTER INFLUENTIAL OBSERVATION REMOVAL';
RUN;  QUIT;


*********************************************************************;
*** PLOT AVG MONTHLY NRX FOR TEST & CNTL - CHECK VALIDITY OF MATCHING;
*********************************************************************;
PROC MEANS DATA=MMF.MODEL NOPRINT NWAY;
CLASS HELCODE TESTCAND;
VAR PROD_PRE3 PROD_PRE2 PROD_PRE1 PROD_EVENT PROD_POST:
    CLASS_PRE3 CLASS_PRE2 CLASS_PRE1 CLASS_EVENT CLASS_POST:;
OUTPUT OUT=MMF.PGM3A2(DROP=_TYPE_ _FREQ_) MEAN=;  RUN;

RUN;  QUIT;
ODS HTML CLOSE;

data temp_graph;
input testcand comparison test_with_event;
cards;
-0.5 . .
;
run; 

/* For Axis Value ... */
proc sql;
create table min1 as
	select min(PROD_PRE3),min(PROD_PRE2),min(PROD_PRE1),min(PROD_EVENT),min(PROD_POST3),min(PROD_POST2),min(PROD_POST1)
	from MMF.PGM3A2;
quit;

proc sql noprint;
	create table max1 as select
	max(PROD_PRE3),max(PROD_PRE2),max(PROD_PRE1),max(PROD_EVENT),max(PROD_POST3),max(PROD_POST2),max(PROD_POST1)
	from MMF.PGM3A2;
quit;

proc transpose data=min1 out=min_table;
run;
proc transpose data=max1 out=max_table;
run;

proc sql noprint;
select min(col1) into :min_out from min_table;
quit;
%put &min_out.;

proc sql noprint;
select max(col1) into :max_out from max_table;
quit;

%let MAX_OUT=%SYSFUNC(ROUND(%sysEVALF(&MAX_OUT+1),1));
%let MIN_OUT=%SYSFUNC(ROUND(%sysEVALF(&MIN_OUT-1),1));

%put &min_out;
%put &max_out;

%let BY_VAR1=%SYSFUNC(ROUND(%sysevalf(&max_out-&MIN_out),1));
%let by_var=%sysfunc(round(%sysevalf(&by_var1/6),1));
%put &min_final;
%put &max_final;
%PUT BY_VAR1=&BY_VAR1;
%PUT BY_VAR=&BY_VAR;

/* Creating macro variable for counting the no. of helcodes*/
Proc sql noprint;
select count(distinct(Helcode)) into :N from MMF.PGM3A2;
quit;
%put &N.;

PROC GREPLAY NOFS IGOUT=WORK.nrxcat;
    DELETE _ALL_;
RUN;
QUIT;
FILENAME ODSOUT "&PATH";
ODS HTML FILE="MMF NRX Graphs.XLS" PATH=ODSOUT;

%macro gph(hel_code);
options mprint mlogic mcompile merror;

data graphs;
    set MMF.PGM3A2;
    keep HELCODE TESTCAND PROD_PRE3 PROD_PRE2 PROD_PRE1 PROD_EVENT PROD_POST1 PROD_POST2 PROD_POST3;
    if helcode="&hel_code";
run;

data graphs;
    set graphs;
    if sum(of _numeric_) lt 0 then delete;
run;

data graphs;
    set graphs;
	    if _n_=0 then call symput("exec","0");
    else call symput("exec","1");
run;

%if "&exec"="1" %then %do;
proc transpose data=graphs out=trans_graph;
run;

data trans_graph(drop=_name_);
    retain testcand -4;
    set trans_graph;
    testcand=testcand+1;
    rename col1=Comparison col2=Test_With_Event;
run;

/* Adding data to draw graph */

data trans_graph;
    set trans_graph temp_graph;
run;

proc sql;
	select min(testcand),max(testcand)
	into :min_out1,:max_out1 from trans_graph;
	
quit;

proc sort data=trans_graph;
by descending testcand;
run;

/* TITLE CREATION */

TITLE1 COLOR=BLACK h=25pt f=zapfb 'Monthly NRx for Test & Comparison Physicians';

/*title2 "&hel_code";*/

%let prod1=%scan(&title_prod.,1,"/");
%let prod2=%scan(&title_prod.,2,"/");
%let prod2=&prod2.;
%put prod2=&prod2;
%let title_no=&title_no.;
%put title_no=&title_no;


%if &prod2.= %then %do;
	title&title_no.  h=25pt f=zapfb "&prod1."  m=(+.5, +1) f=special "R" m=(+0,-1) h=25pt f=zapfb " - &hel_code." 
f=special " " "%sysfunc(byte(185))";
%end;
%if &prod2. ne  %then %do;
	title&title_no. m=(+0, -1) h=25pt f=zapfb
"&prod1." m=(+.5, +1) f=special "R" 
m=(+0, -1) h=33pt f=zapfb "/&prod2." m=(+.5,+1) f=special "R"
m=(+0, -1) h=33pt f=zapfb m=(+0,-1)" - &hel_code. " m=(+.5, +1)  f=special " " "%sysfunc(byte(185))";
%end;
%put &title_no;

GOPTIONS GOUTMODE=APPEND BORDER CBACK=skyblue FTEXT=SIMPLEX HTEXT=2.5 HTITLE=3 FTITLE=zapfb CTITLE=BLACK;
footnote;
LEGEND1 VALUE=(H=2.5 'Comparison' 'Test With Event')
        LABEL=('') POSITION=(bottom center outside) CBORDER=black;

SYMBOL1 CV=BLUE CI=BLUE  V=STAR I=JOIN POINTLABEL=NONE h=2;
SYMBOL2 CV=RED  CI=RED V=DOT  I=JOIN POINTLABEL=NONE h=2;

AXIS1 ORDER=(&min_out. to &max_out. by &by_var.) LABEL=(ANGLE=90 ROTATE=0 FONT='verdana' HEIGHT=40PT 'Average Monthly NRx');
AXIS2 ORDER=(&min_out1. to &max_out1. by 1) LABEL=(FONT='verdana' HEIGHT=25PT f=simplex "Time Aligned Month");
/**/

PROC GPLOT DATA=trans_graph gout=nrxcat;
    PLOT (comparison test_with_event)*testcand / overlay skipmiss NAME="NRx" VAXIS=AXIS1 HAXIS=AXIS2 LEGEND = LEGEND1
        CFRAME=lightyellow GRID;
RUN;
QUIT;
%end;
%mend gph;
%gph(LECTURE);
%gph(PDG);
%gph(PFI);
%gph(SYMPOSIUM);
ODS HTML CLOSE;


%MACRO SS;
FILENAME ODSOUT "&PATH";
ODS HTML FILE="MMF NRX Graphs.xls" PATH=ODSOUT;

/* CONSOLIDATING GRAPHS INTO A TEMPLATE */

proc greplay igout=nrxcat tc=sashelp.templt template=l2r2 nofs;
	treplay 1:NRx 2:NRx1 3:NRx2;
run;

QUIT;
ODS HTML CLOSE;
%MEND SS;
%SS;


**********************************;
*** TEST VS CAND: MEANS & STD DEVS;
**********************************;
PROC MEANS DATA=MMF.MODEL NWAY NOPRINT;
VAR PROD_PREMEAN CLASS_PREMEAN DET_PREMEAN SAM_PREMEAN MFP_PREMEAN SFP_PREMEAN
    PROD_POSTMEAN CLASS_POSTMEAN DET_POSTMEAN SAM_POSTMEAN MFP_POSTMEAN SFP_POSTMEAN;
CLASS HELCODE TESTCAND;
OUTPUT OUT=MEANSTD; RUN;

PROC SORT DATA=MEANSTD (DROP=_TYPE_) OUT=MEANSTD2;
WHERE _STAT_ IN ('MEAN','STD');
BY HELCODE _STAT_ TESTCAND; RUN;

PROC PRINT DATA=MEANSTD2; 
TITLE2 'MEAN & STD FOR TEST & CNTL';  RUN;

PROC EXPORT DATA=MEANSTD2 OUTFILE="&PATH\MEAN_STD FOR TEST & CONTROL.XLS"
DBMS=EXCEL97 REPLACE;
RUN;

proc printto;
quit;



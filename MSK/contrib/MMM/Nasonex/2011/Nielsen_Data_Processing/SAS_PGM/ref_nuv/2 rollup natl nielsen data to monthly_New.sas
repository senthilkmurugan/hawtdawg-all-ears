PROC PRINTTO LOG="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\2 rollup natl nielsen data to monthly.LOG" NEW
			PRINT="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\2 rollup natl nielsen data to monthly.LST" NEW;
***************************************************************************;
* ROLLUP WEEKLY BRAND-CREATIVE-DAYPART-DURATION DATA TO MONTHLY FOR DATA   ;
* DESCRIPTION/GRAPHING...NATIONAL DATA ONLY...                             ;
***************************************************************************;
TITLE "NMR DATA ROLLUP TO MONTHLY - JAN2010 THROUGH JUN 2010";
OPTION PAGESIZE=MAX;
* LIBRARY STATEMENTS FOR INPUT DATASETS;
LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets"; 

* LIBRARY AND PATH FOR OUTPUT FILES;
LIBNAME NEWOUT "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets";
%LET PATH=\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets;

* CREATE DATASET OF ALL POSSIBLE YEAR-MONTHS IN RANGE;
DATA YEARMONTHS;
INPUT YEAR MONTH @@;
MONTHLABEL=PUT((MDY(MONTH,1,YEAR)),MONYY5.);
QTRLABEL=PUT((MDY(MONTH,1,YEAR)),YYQ4.);
CARDS;
2009 12 2010 1 2010 2 2010 3 2010 4 2010 5 2010 6
;
run;

* CREATE DATASET OF ALL INCLUDED BRANDS;
DATA BRANDS; LENGTH BRAND $200.; INPUT BRAND $ @@;
CARDS;
NUVARING YAZ MIRENA SEASONIQUE LOESTRIN
; 

* CREATE CROSS-PRODUCT OF BRAND-YEARMONTHS;
PROC SQL;
    CREATE TABLE BRAND_YEARMONTHS AS
    SELECT BRAND, MONTHLABEL, QTRLABEL, YEAR, MONTH
    FROM BRANDS, YEARMONTHS;
QUIT; RUN;
PROC SORT DATA=BRAND_YEARMONTHS; BY BRAND YEAR MONTH; RUN;

* CREATE DATASET OF ALL INCLUDED DURATIONS;
PROC FREQ DATA=DTC.natl_tv_mm_jan10_jun10; TABLES BRAND*DURATION/LIST MISSING; RUN;
DATA DURATIONS; INPUT DURATION @@;
CARDS;
10 15 30 35 50 60 75
;

* CREATE CROSS-PRODUCT OF BRAND-YEARMONTHS-DURATIONS;
PROC SQL;
	CREATE TABLE BRAND_YEARMONTHS_DURATIONS AS
	SELECT BRAND, MONTHLABEL, YEAR, MONTH, DURATION
	FROM BRAND_YEARMONTHS, DURATIONS;
QUIT;
PROC SORT DATA=BRAND_YEARMONTHS_DURATIONS; BY BRAND YEAR MONTH DURATION; RUN;

TITLE2 "UPDATE TV AND MULTIMEDIA DATASETS"; RUN;
DATA TV_COMB MM_COMB PR_COMB ;
	SET DTC.NATL_TV_MM_jan10_jun10;
	EQIVWGT=DURATION/60;
	IF BRAND IN ('NUVARING' 'YAZ' 'MIRENA' 'SEASONIQUE' 'LOESTRIN');
	IF RECTYPE="MM" THEN OUTPUT MM_COMB;
	IF RECTYPE="TV" THEN OUTPUT TV_COMB;
RUN;

PROC SORT DATA=MM_COMB EQUALS NODUPKEY; BY MARKET LONG_BRAND REPORT_PERIOD; RUN;
DATA NATL_TV_MM_COMB; SET TV_COMB MM_COMB; RUN; 
PROC PRINT DATA=NATL_TV_MM_COMB(OBS=10); RUN; TITLE2 ""; RUN;
PROC PRINT DATA=NATL_TV_MM_COMB(WHERE=(RECTYPE="MM" AND BRAND="NUVARING")); 
        VAR REPORT_PERIOD INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND; RUN; 

PROC PRINT DATA=TV_COMB (OBS=10); RUN; TITLE2 ""; RUN;
PROC FREQ DATA=TV_COMB (WHERE=(YEAR GE 2007 AND BRAND='NUVARING')); TABLES BRAND*CREATIVE*YEAR*MONTH/LIST MISSING; RUN;

*CREATE INDICATION VARIABLE;
DATA NATL_TV_MM_COMB1;
     SET NATL_TV_MM_COMB;
	 LENGTH FLAG $15.;
	 IF BRAND='YAZ' AND RECTYPE ='TV' AND CREATIVE = 'PMDD/MODERATE ACNE/WOMAN IN CLUB' THEN FLAG= 'CORR'; ELSE
     FLAG='REG';
RUN;
PROC FREQ DATA=NATL_TV_MM_COMB1(WHERE=(BRAND='YAZ')); TABLES /*RECTYPE*BRAND*/FLAG*CREATIVE/LIST MISSING; RUN;
PROC FREQ DATA=NATL_TV_MM_COMB1(WHERE=(BRAND='YAZ')); TABLES BRAND*CREATIVE*FLAG*YEAR*MONTH/LIST MISSING; RUN; 

* "EXPLORE TV UNWEIGHTED GRP DATA BY BRAND YEAR MONTH DURATION";
PROC MEANS DATA=NATL_TV_MM_COMB1 (WHERE=(RECTYPE="TV"))
SUM NOPRINT NWAY;
CLASS BRAND FLAG YEAR MONTH DURATION;
VAR CABTV_F1849 NETTV_F1849 SYNTV_F1849 CABTV_F1849_SPANISH NETTV_F1849_SPANISH;
OUTPUT OUT=NATL_USUM SUM(CABTV_F1849 NETTV_F1849 SYNTV_F1849 CABTV_F1849_SPANISH NETTV_F1849_SPANISH)=CABTV_F1849 NETTV_F1849 SYNTV_F1849 CABTV_F1849_SPANISH NETTV_F1849_SPANISH; RUN;

PROC SORT DATA=NATL_USUM; BY BRAND YEAR MONTH; RUN;
DATA MNATL_USUM (DROP=K); MERGE BRAND_YEARMONTHS_DURATIONS NATL_USUM; 
BY BRAND YEAR MONTH DURATION;
ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; 	END; 
IF FLAG=' ' THEN FLAG='REG'; 
RUN;
PROC SORT DATA=MNATL_USUM; BY BRAND DURATION YEAR MONTH; RUN;
PROC EXPORT DATA=MNATL_USUM OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=TVGRP_USUM; RUN;

* "EXPLORE TV WEIGHTED GRP DATA BY BRAND YEAR MONTH DURATION";
PROC MEANS DATA=NATL_TV_MM_COMB1(WHERE=(RECTYPE="TV")) SUM NOPRINT NWAY;
CLASS BRAND FLAG YEAR MONTH;
WEIGHT EQIVWGT;
VAR CABTV_F1849 NETTV_F1849 SYNTV_F1849 CABTV_F1849_SPANISH NETTV_F1849_SPANISH;
OUTPUT OUT=NATL_WSUM SUM(CABTV_F1849 NETTV_F1849 SYNTV_F1849 CABTV_F1849_SPANISH NETTV_F1849_SPANISH)=CABTV_F1849_W NETTV_F1849_W SYNTV_F1849_W CABTV_F1849_SPANISH_W NETTV_F1849_SPANISH_W; RUN;
PROC SORT DATA=NATL_WSUM; BY BRAND YEAR MONTH; RUN; 

DATA MNATL_WSUM (DROP=K); MERGE BRAND_YEARMONTHS NATL_WSUM; BY BRAND YEAR MONTH;
ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END;
IF FLAG=' ' THEN FLAG='REG';
RUN;
PROC EXPORT DATA=MNATL_WSUM OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=TVGRP_WSUM; RUN;

* "EXPLORE TV SPEND DATA BY BRAND YEAR MONTH";
PROC MEANS DATA=NATL_TV_MM_COMB (WHERE=(RECTYPE="TV"))SUM NOPRINT;
CLASS BRAND YEAR MONTH;
VAR CABTV_SPEND NETTV_SPEND SYNTV_SPEND;
OUTPUT OUT=NATL_SPEND SUM(CABTV_SPEND NETTV_SPEND SYNTV_SPEND)=CABTV_SPEND NETTV_SPEND SYNTV_SPEND; RUN;
DATA MNATL_SPEND (DROP=K); MERGE BRAND_YEARMONTHS NATL_SPEND (WHERE=(_TYPE_=7)); BY BRAND YEAR MONTH;
ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END; RUN;
PROC EXPORT DATA=MNATL_SPEND OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=TV_SPEND; RUN;

* "EXPLORE TV SPEND DATA BY BRAND QUARTER";
PROC MEANS DATA=MNATL_SPEND SUM NOPRINT NWAY; 
CLASS BRAND QTRLABEL;
VAR CABTV_SPEND NETTV_SPEND SYNTV_SPEND;
OUTPUT OUT=QNATL_SPEND SUM(CABTV_SPEND NETTV_SPEND SYNTV_SPEND)=
						   CABTV_QSPEND NETTV_QSPEND SYNTV_QSPEND;
PROC EXPORT DATA=QNATL_SPEND OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=TV_QSPEND; RUN;

* "EXPLORE MULTIMEDIA SPEND DATA BY BRAND YEAR MONTH";
PROC MEANS DATA=NATL_TV_MM_COMB (WHERE=(RECTYPE="MM")) SUM NOPRINT NWAY;
CLASS BRAND YEAR MONTH;
VAR INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND;
OUTPUT OUT=NATL_MM SUM(INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND)=
					   INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND; RUN;
DATA MNATL_MM (DROP=K); MERGE BRAND_YEARMONTHS NATL_MM; BY BRAND YEAR MONTH;
ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END; RUN;
PROC EXPORT DATA=MNATL_MM OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=MM_SPEND; RUN;

* "EXPLORE MULTIMEDIA SPEND DATA BY BRAND QUARTER";
PROC MEANS DATA=MNATL_MM SUM NOPRINT NWAY; 
CLASS BRAND QTRLABEL;
VAR INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND;
OUTPUT OUT=QNATL_MM SUM(INET_SPEND MAG_SPEND NEWS_SPEND SUP_SPEND RAD_SPEND)=
						INET_QSPEND MAG_QSPEND NEWS_QSPEND SUP_QSPEND RAD_QSPEND;
PROC EXPORT DATA=QNATL_MM OUTFILE= "&PATH\NATL_GRAPHS.XLS"
DBMS=EXCEL97 REPLACE; SHEET=MM_QSPEND; RUN;

* CREATE PERMANENT DATASETS FOR MODELING;
DATA NEWOUT.NATL_TV_MM; SET NATL_TV_MM_COMB1; RUN;
DATA NEWOUT.NATL_TV_WEIGHTED_GRP; SET MNATL_WSUM(DROP=_TYPE_ _FREQ_);RUN;
DATA NEWOUT.NATL_TV_SPEND; SET MNATL_SPEND (DROP=_TYPE_ _FREQ_); RUN;
DATA NEWOUT.NATL_MM_SPEND; SET MNATL_MM (DROP=_TYPE_ _FREQ_); RUN;


* PRINT SAMPLE RECORDS FROM PERMANENT DATASETS;
TITLE2 "NATIONAL TV MM COMBINED"; 
PROC PRINT DATA=NEWOUT.NATL_TV_MM (OBS=10); RUN;
RUN;
TITLE2 "NATIONAL TV SPEND"; 
PROC PRINT DATA=NEWOUT.NATL_TV_SPEND (OBS=10); RUN;
TITLE2 "NATIONAL MM SPEND";
PROC PRINT DATA=NEWOUT.NATL_MM_SPEND (OBS=10); RUN;

PROC PRINTTO;
QUIT;

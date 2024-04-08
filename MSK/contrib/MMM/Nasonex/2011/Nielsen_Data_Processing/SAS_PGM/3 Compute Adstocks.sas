/*PROC PRINTTO LOG="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\3 Compute Adstocks.LOG" NEW
			PRINT="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\3 Compute Adstocks.LST" NEW;
*/
/***************************************************************************
* PGM 3: COMPUTE ADSTOCKS AT EITHER STANDARD WEEK LEVEL OR MONTH LEVEL BASED ON NEED;
***************************************************************************/
LIBNAME INPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\INPUT";
LIBNAME OUTPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";
LIBNAME CONFIG "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\CONFIG";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
0. Define standard values;
*/
%LET ADSTK_COLS = GRPADV_ GRPALA_ GRPALL_ GRPBEN_ GRPCLA_ GRPNAS_ GRPOMN_ GRPZYR_; 

/*
0. READ IN CONFIGURATION DATA (from Access tables) AND CREATE ANY CONFIGURATION BASED MACRO VARIABLES.
*/
%MACRO GETCONFIG(DBNAME,TABLENM,OUTNAME);
  PROC IMPORT DATATABLE = "&TABLENM."  OUT = WORK.&OUTNAME.
    DBMS=ACCESS REPLACE;
    DATABASE = "&PATH\CONFIG\&DBNAME.";
  RUN;
%MEND;
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_1_BRANDS,CONF_BRANDS);
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_2_BRAND_PREFIX,CONF_BRAND_PREFIX);
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_3_TARGET_AGE_GROUP,CONF_TARGET_AGE_GROUP);
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_4_DATA_PERIOD,CONF_DATA_PERIOD);
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_5_ADSTOCK_DATA_UNIT,CONF_ADSTOCK_DATA_UNIT);
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_6_ADSTOCK_LAMBDA,CONF_ADSTOCK_LAMBDA);

PROC SQL;
SELECT ADSTOCK_DATA_UNIT INTO :ADS_DATA_UNIT SEPARATED BY "" FROM CONF_ADSTOCK_DATA_UNIT;
QUIT;
*%LET TGT_SUFFIX = %SYSFUNC(COMPRESS(&&TGT_SUFFIX.));
%PUT &ADS_DATA_UNIT.END;


/*
1. AGGREGATE WEIGHTED GRPS AT THE STANDARD WEEK AND/OR MONTH LEVEL               
   NOTE: MONTH LEVEL IS ONLY POSSIBLE IF THE INPUT DATA WAS BY CALENDAR WEEK 
   (If not, monthly aggregation error is there because no splitting is one)       
   NOTE 2: FOR COMPUTING ADSTOCK, DATA NEEDS TO BE AGGREGATED BY EITHER STANDARD WEEK OR REPORT MONTH BASED ON ADSTK COMPUTATION UNIT
*/
DATA WTD_GRP_BY_DMA_REPORT_WEEK; 
  SET OUTPUT.WTD_GRP_BY_DMA_REPORT_WEEK; 
  YEARMO = put(REPORT_END,yymmn6.);
RUN;

PROC MEANS DATA=WTD_GRP_BY_DMA_REPORT_WEEK SUM NOPRINT NWAY;
CLASS DMA STANDARD_WEEK;
VAR GRP:;
OUTPUT OUT=OUTPUT.WTD_GRP_BY_STANDARD_WEEK(DROP=_TYPE_ _FREQ_) SUM=; 
RUN;

PROC MEANS DATA=WTD_GRP_BY_DMA_REPORT_WEEK SUM NOPRINT NWAY;
CLASS DMA YEARMO;
VAR GRP:;
OUTPUT OUT=OUTPUT.WTD_GRP_BY_REPORT_MONTH(DROP=_TYPE_ _FREQ_) SUM=; 
RUN;

/*
2. Process Adstocks:
   (A) If ADSTOCK DATA UNIT is "MONTH", then use YEARMO as Monthly data unit and use monthly lambdas 
            OR
   (B) If ADSTOCK DATA UNIT is "WEEK", then use STANDARD_WEEK as data unit and use weekly lambdas 
*/
%MACRO GET_ADSTK_SOURCE();
  %IF &ADS_DATA_UNIT. = MONTH %THEN %DO;
    DATA WGRP_SOURCE; SET OUTPUT.WTD_GRP_BY_REPORT_MONTH; RUN;
    PROC SORT DATA=WGRP_SOURCE; BY DMA YEARMO; RUN;
  %END;
  %IF &ADS_DATA_UNIT. = WEEK %THEN %DO;
    DATA WGRP_SOURCE; SET OUTPUT.WTD_GRP_BY_STANDARD_WEEK; RUN;
    PROC SORT DATA=WGRP_SOURCE; BY DMA STANDARD_WEEK; RUN;
  %END;
%MEND;
%GET_ADSTK_SOURCE();

/* 
  Create a string with automatic Adstock related macro calls based on configured lambdas
  macro var callADSTK has value like: "%ADSTK1(0.1,10); %ADSTK1(0.2,20); ....."
  This macro var is later introduced during actual macro call.
*/ 
%LET CALLADSTK = ;
PROC SQL;
  SELECT '%ADSTK1('||TRIM(LEFT(PUT(ADSTOCK_LAMBDA,BEST.)))||','||TRIM(LEFT(ADSTOCK_SUFFIX))||');' 
    INTO :CALLADSTK SEPARATED BY '  '
  FROM CONF_ADSTOCK_LAMBDA;
QUIT;
/* Compute Adstocks */
DATA ADSTK_DATA;
  SET WGRP_SOURCE;
  BY DMA;
  /* Create strings like below (i.e., columns corresponding to an array)
     using defined macro variable ADSTK_COLS
     ARRAY arGRPS(*) GRP:;
     ARRAY arADS10(*) ADSADV10 ADSALA10 ADSALL10;
  */
  ARRAY arGRPS(*)  %SYSFUNC(TRANWRD(&ADSTK_COLS.,_,%STR( )));;
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY arADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS.,_,_&HLLBL.));;
    RETAIN arADS&HLLBL.;
    IF FIRST.DMA THEN DO;
      DO J=1 TO DIM(arADS&HLLBL.);
        arADS&HLLBL.(J) = arGRPS(J);
      END;
    END;
    ELSE DO;
	  DO J=1 TO DIM(arADS&HLLBL.);
	    arADS&HLLBL.(J) = arGRPS(J) + &DECAY.*arADS&HLLBL.(J);
	  END;
    END;
  %MEND;
  /* Create string like below in macro var CALLADSTK through proc sql 
       before executing this data step;
      %ADSTK1(0.1,10); %ADSTK1(0.2,20); ....
  */
  &CALLADSTK; 
  DROP J;
RUN;

%MACRO STORE_ADSTK_DATA();
  %IF &ADS_DATA_UNIT. = MONTH %THEN %DO;
      DATA OUTPUT.ADS_BY_UNIT_MONTH; SET ADSTK_DATA; RUN;  
  %END;
  %IF &ADS_DATA_UNIT. = WEEK %THEN %DO;
      DATA OUTPUT.ADS_BY_STANDARD_WEEK; SET ADSTK_DATA; RUN;  
  %END;
%MEND;
%STORE_ADSTK_DATA();

/*
3. Aggregation of Standard Week data to monthly level.
   If a standard week covers two months adstocks are split according to 
   number of days in each month.
   HERE, we merge OUTPUT.WTD_GRP_BY_DMA_REPORT_WEEK and OUTPUT.ADS_BY_STANDARD_WEEK
    after properly selecting relevant columns from each data source.
   Then, using num_days in each month adstocks are readjusted to calendar week and then
   reaggregated at monthly level.
*/
PROC SORT DATA=OUTPUT.WTD_GRP_BY_DMA_REPORT_WEEK OUT=REPORT_WEEK_WGRPS; 
  BY DMA STANDARD_WEEK REPORT_END;
RUN;
PROC SORT DATA=OUTPUT.ADS_BY_STANDARD_WEEK OUT=STANDARD_WEEK_ADSTKS; 
  BY DMA STANDARD_WEEK;
RUN;
DATA STANDARD_WEEK_ADSTKS;
  SET STANDARD_WEEK_ADSTKS;
  KEEP DMA STANDARD_WEEK %SYSFUNC(TRANWRD(&ADSTK_COLS.,_,_:));;
RUN;

/* 
  Create a string with automatic Adstock related macro calls based on configured Half Life Labels
  macro var callADSTK_2 has value like: "%ADSTK_2(10); %ADSTK_2(20); ....."
  This macro var is later introduced during actual macro call.
*/ 
%LET CALLADSTK_2 = ;
PROC SQL;
  SELECT '%ADSTK_2('||TRIM(LEFT(ADSTOCK_SUFFIX))||');' 
    INTO :CALLADSTK_2 SEPARATED BY '  '
  FROM CONF_ADSTOCK_LAMBDA;
QUIT;
/* Merge and Adjust Adstocks according to Days in the Calendar week (REPORT_END) */
DATA ADS_REPORT_WEEK;
  MERGE REPORT_WEEK_WGRPS(IN=A) STANDARD_WEEK_ADSTKS(IN=B);
  BY DMA STANDARD_WEEK;
RUN;
DATA ADS_REPORT_WEEK;
  SET ADS_REPORT_WEEK;

  %MACRO ADSTK_2(HLLBL);
    ARRAY arADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS.,_,_&HLLBL.));;
    DO J=1 TO DIM(arADS&HLLBL.);
        arADS&HLLBL.(J) = arADS&HLLBL.(J)* (NUM_DAYS / 7);
    END;
  %MEND;
  /* Create string like below in macro var CALLADSTK through proc sql 
       before executing this data step;
      %ADSTK_2(10); %ADSTK_2(20); ....
  */
  &CALLADSTK_2; 
  DROP J;
RUN;

/* AGGREGATE BY MONTH */
DATA ADS_BY_DMA_REPORT_WEEK; 
  SET ADS_REPORT_WEEK; 
  YEARMO = put(REPORT_END,yymmn6.);
RUN;
PROC MEANS DATA=ADS_BY_DMA_REPORT_WEEK(DROP=REPORT_END STANDARD_WEEK) SUM NOPRINT NWAY;
  CLASS DMA YEARMO;
  VAR _NUMERIC_ ;
  OUTPUT OUT=OUTPUT.ADSTK_AGGR_BY_MONTH(DROP=_TYPE_ _FREQ_) SUM=; 
RUN;

/*
PROC PRINTTO;
QUIT;
*/



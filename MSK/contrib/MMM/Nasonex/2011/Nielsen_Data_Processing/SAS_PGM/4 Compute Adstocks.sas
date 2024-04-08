PROC PRINTTO LOG="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\4 Compute Adstocks.LOG" NEW
			PRINT="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\4 Compute Adstocks.LST" NEW;

/***************************************************************************
* PGM 4: COMPUTE ADSTOCKS AT EITHER FULL WEEK LEVEL OR MONTH LEVEL BASED ON NEED;
***************************************************************************/
/*
1. AGGREGATE WEIGHTED GRPS AT THE FULL WEEK AND/OR MONTH LEVEL               
   NOTE: MONTH LEVEL IS ONLY POSSIBLE IF THE INPUT DATA WAS BY CALENDAR WEEK 
   (If not, monthly aggregation error is there because no splitting is one)       
   NOTE 2: FOR COMPUTING ADSTOCK, DATA NEEDS TO BE AGGREGATED BY EITHER FULL WEEK OR REPORT MONTH BASED ON ADSTK COMPUTATION UNIT
*/
DATA TV_MM_GRP_BY_DMA_REPORT_WEEK; 
  SET OUTPUT.TV_MM_GRP_BY_DMA_REPORT_WEEK; 
  YEARMO = put(REPORT_END,yymmn6.);
RUN;

%LET TMP_VAR_LST = ;
%MACRO GET_VARS_1();
  %IF &INCLUDE_MM.=YES %THEN %DO; %LET TMP_VAR_LST = GRP: MM_: ; %END; 
  %ELSE %DO; %LET TMP_VAR_LST = GRP: ; %END; 
%MEND GET_VARS_1;
%GET_VARS_1();
%PUT &TMP_VAR_LST.END;

PROC MEANS DATA=TV_MM_GRP_BY_DMA_REPORT_WEEK SUM NOPRINT NWAY;
CLASS DMA FULL_WEEK;
VAR &TMP_VAR_LST.;
OUTPUT OUT=OUTPUT.TV_MM_GRP_BY_FULL_WEEK(DROP=_TYPE_ _FREQ_) SUM=; 
RUN;

PROC MEANS DATA=TV_MM_GRP_BY_DMA_REPORT_WEEK SUM NOPRINT NWAY;
CLASS DMA YEARMO;
VAR &TMP_VAR_LST.; 
OUTPUT OUT=OUTPUT.TV_MM_GRP_BY_REPORT_MONTH(DROP=_TYPE_ _FREQ_) SUM=; 
RUN;

/*
2. Process Adstocks:
   (A) If ADSTOCK DATA UNIT is "MONTH", then use YEARMO as Monthly data unit and use monthly lambdas 
            OR
   (B) If ADSTOCK DATA UNIT is "WEEK", then use FULL_WEEK as data unit and use weekly lambdas 
*/
%MACRO GET_ADSTK_SOURCE();
  %IF &ADS_DATA_UNIT. = MONTH %THEN %DO;
    DATA WGRP_SOURCE; SET OUTPUT.TV_MM_GRP_BY_REPORT_MONTH; RUN;
    PROC SORT DATA=WGRP_SOURCE; BY DMA YEARMO; RUN;
  %END;
  %IF &ADS_DATA_UNIT. = WEEK %THEN %DO;
    DATA WGRP_SOURCE; SET OUTPUT.TV_MM_GRP_BY_FULL_WEEK; RUN;
    PROC SORT DATA=WGRP_SOURCE; BY DMA FULL_WEEK; RUN;
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
  ARRAY arGRPS(*)  %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,%STR( )));;
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY arADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,_&HLLBL.));;
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
      DATA OUTPUT.ADS_BY_FULL_WEEK; SET ADSTK_DATA; RUN;  
  %END;
%MEND;
%STORE_ADSTK_DATA();

/*
3. Aggregation of FULL Week data to monthly level.
   If a FULL week covers two months adstocks are split according to 
   number of days in each month.
   HERE, we merge OUTPUT.TV_MM_GRP_BY_DMA_REPORT_WEEK and OUTPUT.ADS_BY_FULL_WEEK
    after properly selecting relevant columns from each data source.
   Then, using num_days in each month adstocks are readjusted to calendar week and then
   reaggregated at monthly level.
*/
%MACRO AGGR_FULL_WEEK_TO_MONTH();
  PROC SORT DATA=OUTPUT.ADS_BY_FULL_WEEK OUT=FULL_WEEK_ADSTKS; 
    BY DMA FULL_WEEK;
  RUN;
  DATA FULL_WEEK_ADSTKS;
    SET FULL_WEEK_ADSTKS;
	YEARMO = put(FULL_WEEK,yymmn6.);
    KEEP DMA FULL_WEEK YEARMO %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,_:));;
  RUN;

  /* AGGREGATE BY MONTH */
  PROC MEANS DATA=FULL_WEEK_ADSTKS SUM NOPRINT NWAY;
    CLASS DMA YEARMO;
    VAR %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,_:));;
    OUTPUT OUT=ADSTK_BY_MONTH(DROP=_TYPE_ RENAME=(_FREQ_ = NUM_FULL_WEEKS)) SUM=; 
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
  /*  Adjust Adstocks according to number of Days in the month 
        and the number of full weeks in the month   */
  DATA ADSTK_BY_MONTH_2;
    SET ADSTK_BY_MONTH;
	*get days in month;
	som = MDY(SUBSTR(YEARMO,5,2)*1,1,SUBSTR(YEARMO,1,4)*1); * gets first day of month;
	eom = intnx('month',som,0,'end'); * gets last day of month;
	days_in_month = day(eom); * gets number of days in the month;

    %MACRO ADSTK_2(HLLBL);
      ARRAY arADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,_&HLLBL.));;
      DO J=1 TO DIM(arADS&HLLBL.);
          arADS&HLLBL.(J) = (arADS&HLLBL.(J)/num_full_weeks)*(days_in_month/7);
      END;
    %MEND ADSTK_2;
    /* Create string like below in macro var CALLADSTK through proc sql 
         before executing this data step;
        %ADSTK_2(10); %ADSTK_2(20); ....
    */
    &CALLADSTK_2; 
    DROP J som eom;
  RUN; * This gives adjusted adstocks for the dma and month;

  /* MERGE "GRPS BY MONTH" AND "ADSTOCKS BY MONTH" BY DMA AND YEARMO */
  PROC SORT DATA=OUTPUT.TV_MM_GRP_BY_REPORT_MONTH OUT=GRPS_AGGR_BY_MONTH; 
       BY DMA YEARMO; RUN;
  PROC SORT DATA=ADSTK_BY_MONTH_2; BY DMA YEARMO; RUN;
  DATA GRP_ADSTK_AGGR_BY_MONTH;
    MERGE GRPS_AGGR_BY_MONTH(IN=A) ADSTK_BY_MONTH_2(IN=B);
	BY DMA YEARMO;
	IF A;
	INSET=10*A+B;
  RUN;
  PROC FREQ DATA=GRP_ADSTK_AGGR_BY_MONTH; TABLES INSET; RUN;
  DATA OUTPUT.ADSTK_AGGR_BY_MONTH(DROP=INSET); SET GRP_ADSTK_AGGR_BY_MONTH; RUN;

%MEND AGGR_FULL_WEEK_TO_MONTH;

%MACRO EXEC_WEEK_TO_MONTH_AGGR();
  %IF &ADS_DATA_UNIT. = WEEK %THEN %DO;
    %AGGR_FULL_WEEK_TO_MONTH();
  %END;
%MEND EXEC_WEEK_TO_MONTH_AGGR;
%EXEC_WEEK_TO_MONTH_AGGR();

PROC PRINTTO;
QUIT;




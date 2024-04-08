***************************************************************************;
* DRIVER PROGRAM FOR GENERATING GRP ADSTOCKS.                              ;
***************************************************************************;
LIBNAME INPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\INPUT";
LIBNAME OUTPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";
LIBNAME CONFIG "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\CONFIG";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/************************************************************************
STEP 1. 
IMPORT RAW DATA USING 1 Import GRP Data.sas
DATA EXPECTED: CALENDAR WEEK LEVEL FOR NATIONAL AND LOCAL TV GRPS AND OTHER MEDIA OCCURENCES
   WITH OPTIONAL SPEND AND OTHER RELATED DATA LIKE IMPRESSIONS, CPM ETC.,
THIS PROGRAM SHOULD BE MODIFIED BASED ON DATA SPECS.
THE OUTPUT OF THIS PROGRAM SHOULD GENERATE 4 DATASETS 
(ALL WITH ONLY NECESSAY COLUMNS WITH DEFINED NAMES):
1. SEL_RAW_NATL_TV; 2. SEL_RAW_LOCL_TV; 3. SEL_RAW_NATL_MM; 4.SEL_RAW_LOCL_MM; 
***************************************************************************/

/************************************************************************
STEP 2. 
READ IN CONFIGURATION DATA (from Access tables).
***************************************************************************/
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
%GETCONFIG(CONFIG_GRP_PROCESS.mdb,CONF_7_ADSTOCK_COLUMNS,CONF_ADSTOCK_COLUMNS);

/************************************************************************
STEP 3. 
COMPUTE WEIGHTED GRPS FOR TV. GENERALLY, WEIGHTED BASED ON 60 SECONDS DURATIONS.
***************************************************************************/
%LET STD_ADSECS = 60; * Converts all adds to this commercial duration scale (ie., seconds);

PROC SQL;
SELECT TGT_FIELD_SUFFIX INTO :TGT_SUFFIX SEPARATED BY "" FROM CONF_TARGET_AGE_GROUP;
QUIT;
%PUT &TGT_SUFFIX.END;

/* call corresponding program. Uncomment while running and comment it back after running */
*%INCLUDE "&PATH\SAS_PGM\2 Compute Wtd GRPs by Week.sas";


/************************************************************************
STEP 4. 
ADD MULTI MEDIA METRICS TO TV GRPS.
MM Types include PRINT, RADIO, INTERNET, OTHER.
***************************************************************************/
%LET MM_METRIC = UNITS; * Define MM metric to capture: UNITS or SPEND;

/* Get product names for each of the MM type.*/
%LET MM_PRT_BRANDS = ; %LET MM_RAD_BRANDS = ; %LET MM_INT_BRANDS = ; %LET MM_OTH_BRANDS = ;
PROC SQL;
SELECT PREFIX INTO :MM_PRT_BRANDS SEPARATED BY " " FROM CONF_BRAND_PREFIX WHERE INCLUDE_MM_PRINT = "YES";
SELECT PREFIX INTO :MM_RAD_BRANDS SEPARATED BY " " FROM CONF_BRAND_PREFIX WHERE INCLUDE_MM_RADIO = "YES";
SELECT PREFIX INTO :MM_INT_BRANDS SEPARATED BY " " FROM CONF_BRAND_PREFIX WHERE INCLUDE_MM_INTERNET = "YES";
SELECT PREFIX INTO :MM_OTH_BRANDS SEPARATED BY " " FROM CONF_BRAND_PREFIX WHERE INCLUDE_MM_OTHER = "YES";
QUIT;
%PUT &MM_PRT_BRANDS.~~&MM_RAD_BRANDS.~~&MM_INT_BRANDS.~~&MM_OTH_BRANDS.END;

/* call corresponding program IF AT LEAST ONE of the MM metric is needed. 
   Uncomment INCLUDE statement while running and comment it back after running */
%LET INCLUDE_MM = ;
%MACRO CALL_MM_MODULE();
  %IF (&MM_PRT_BRANDS. ^= OR &MM_PRT_BRANDS. ^= OR
       &MM_PRT_BRANDS. ^= OR &MM_PRT_BRANDS. ^= ) %THEN %DO;
	%LET INCLUDE_MM=YES;
    *%INCLUDE "&PATH\SAS_PGM\3 Include MM Metrics by Week.sas";
  %END;
  %ELSE %DO;
    %LET INCLUDE_MM=NO;
    DATA OUTPUT.TV_MM_GRP_BY_DMA_REPORT_WEEK; SET OUTPUT.WTD_GRP_BY_DMA_REPORT_WEEK; RUN;
  %END;
%MEND CALL_MM_MODULE;
%CALL_MM_MODULE();


/**************************************************************************
STEP 5. 
COMPUTE ADSTOCKS.
***************************************************************************/
/* note the macro var INCLUDE_MM from previous step shoud be assigned either YES or NO
   for this step. */
PROC SQL;
SELECT ADSTOCK_DATA_UNIT INTO :ADS_DATA_UNIT SEPARATED BY "" FROM CONF_ADSTOCK_DATA_UNIT;
SELECT ADSTOCK_COLUMN INTO :ADSTK_COL1 SEPARATED BY "_XX_ " FROM CONF_ADSTOCK_COLUMNS;
QUIT;
%PUT &ADS_DATA_UNIT.END;

%LET ADSTK_COLS = ;
%MACRO ADJUST_COLS();
  %LET ADSTK_COLS = %sysfunc(cats(&ADSTK_COL1,_XX_));
%MEND ADJUST_COLS;
%ADJUST_COLS();
%PUT &ADSTK_COLS.END;

/* call corresponding program Uncomment while running and comment it back after running. */
*%INCLUDE "&PATH\SAS_PGM\4 Compute Adstocks.sas";


/*PROC PRINTTO LOG="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\1 import GRP Data.LOG" NEW
			PRINT="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\1 import GRP data.LST" NEW;
*/
***************************************************************************;
* IMPORT NATIONAL AND DMA-LEVEL DATA RECEIVED FROM NMR for NASONEX -       ;
* TIME PERIOD IS Feb-2009 to July-2011                                     ;
*                                                                          ;
***************************************************************************;
LIBNAME INPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\INPUT";
LIBNAME OUTPUT "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";
LIBNAME CONFIG "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\CONFIG";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. IMPORT NATL AND LOCL TV AND MULTIMEDIA DATA (GRPS, MULTIMEDIA, SPEND);
*/
%MACRO IMPORTDATA(DBNAME,TABLENM,OUTNAME);
  PROC IMPORT DATATABLE = "&TABLENM."  OUT = WORK.&OUTNAME.
    DBMS=ACCESS REPLACE;
    DATABASE = "&PATH\INPUT\&DBNAME.";
  RUN;
%MEND;
* NATL TV - GRPS;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,NAS NATIONAL TV GRPs,RAW_NATL_TV);
* LOCAL TV - GRPS;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,NAS LOCAL TV GRPs,RAW_LOCL_TV);
* NATL MULTI MEDIA;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,NAS NATIONAL MULTI SPEND,RAW_NATL_MM);
* LOCAL MULTI MEDIA;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,NAS LOCAL MULTI SPEND,RAW_LOCL_MM);

* DMA NAME (Market) to DMA CODE XREF;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,DMA_NAME_CODE_XREF,RAW_DMA_XREF);

/*
2. FOR EACH IMPORTED DATASET, RENAME FIELDS APPROPRIATELY
   CREATE ANY PROCESSING FIELDS LIKE: start_date, end_date, YEARMO, Year, Month.
   NOTE: The data obtained was for calendar week, hence it ends for each month 
     (i.e., end date could be used for yearmo and aggregation by month)
*/
* NATL TV - GRPS;
proc contents data=RAW_NATL_TV varnum; run;
DATA NATL_TV;
  SET RAW_NATL_TV;
  RENAME Brand = Brand_Long
    Report_Period__multiple_ = Report_Period
    Cable_TV_Units = CABTV_UNITS
    Cable_TV______000_ = CABTV_SPEND
    Cable_TV_GRP__TV_Households = CABTV_HH
    Cable_TV_IMP_000___TV_Households = CABTV_IMP_HH
    Cable_TV_CPM__TV_Households = CABTV_CPM_HH
    Cable_TV_GRP__P18_ = CABTV_18P
    Cable_TV_IMP_000___P18_ = CABTV_IMP_18P
    Cable_TV_CPM__P18_ = CABTV_CPM_18P
    Cable_TV_GRP__P21_54 = CABTV_A2154
    Cable_TV_IMP_000___P21_54 = CABTV_IMP_A2154
    Cable_TV_CPM__P21_54 = CABTV_CPM_A2154
    Cable_TV_GRP__P21_64 = CABTV_A2164
    Cable_TV_IMP_000___P21_64 = CABTV_IMP_A2164
    Cable_TV_CPM__P21_64 = CABTV_CPM_A2164
    Network_TV_Units = NETTV_UNITS
    Network_TV______000_ = NETTV_SPEND
    Network_TV_GRP__TV_Households = NETTV_HH
    Network_TV_IMP_000___TV_Househol = NETTV_IMP_HH
    Network_TV_CPM__TV_Households = NETTV_CPM_HH
    Network_TV_GRP__P18_ = NETTV_18P
    Network_TV_IMP_000___P18_ = NETTV_IMP_18P
    Network_TV_CPM__P18_ = NETTV_CPM_18P
    Network_TV_GRP__P21_54 = NETTV_A2154
    Network_TV_IMP_000___P21_54 = NETTV_IMP_A2154
    Network_TV_CPM__P21_54 = NETTV_CPM_A2154
    Network_TV_GRP__P21_64 = NETTV_A2164
    Network_TV_IMP_000___P21_64 = NETTV_IMP_A2164
    Network_TV_CPM__P21_64 = NETTV_CPM_A2164
    Spanish_Language_Cable_TV_Units = CABTV_UNITS_SPANISH
    Spanish_Language_Cable_TV______0 = CABTV_SPEND_SPANISH
    Spanish_Language_Cable_TV_GRP__T = CABTV_HH_SPANISH
    Spanish_Language_Cable_TV_IMP_00 = CABTV_IMP_HH_SPANISH
    Spanish_Language_Cable_TV_CPM__T = CABTV_CPM_HH_SPANISH
    Spanish_Language_Cable_TV_GRP__P = CABTV_18P_SPANISH
    Spanish_Language_Cable_TV_IMP_01 = CABTV_IMP_18P_SPANISH
    Spanish_Language_Cable_TV_CPM__P = CABTV_CPM_18P_SPANISH
    Spanish_Language_Cable_TV_GRP__0 = CABTV_A2154_SPANISH
    Spanish_Language_Cable_TV_IMP_02 = CABTV_IMP_A2154_SPANISH
    Spanish_Language_Cable_TV_CPM__0 = CABTV_CPM_A2154_SPANISH
    Spanish_Language_Cable_TV_GRP__1 = CABTV_A2164_SPANISH
    Spanish_Language_Cable_TV_IMP_03 = CABTV_IMP_A2164_SPANISH
    Spanish_Language_Cable_TV_CPM__1 = CABTV_CPM_A2164_SPANISH
    Spanish_Language_Network_TV_Unit = NETTV_UNITS_SPANISH
    Spanish_Language_Network_TV_____ = NETTV_SPEND_SPANISH
    Spanish_Language_Network_TV_GRP_ = NETTV_HH_SPANISH
    Spanish_Language_Network_TV_IMP_ = NETTV_IMP_HH_SPANISH
    Spanish_Language_Network_TV_CPM_ = NETTV_CPM_HH_SPANISH
    Spanish_Language_Network_TV_GRP0 = NETTV_18P_SPANISH
    Spanish_Language_Network_TV_IMP0 = NETTV_IMP_18P_SPANISH
    Spanish_Language_Network_TV_CPM0 = NETTV_CPM_18P_SPANISH
    Spanish_Language_Network_TV_GRP1 = NETTV_A2154_SPANISH
    Spanish_Language_Network_TV_IMP1 = NETTV_IMP_A2154_SPANISH
    Spanish_Language_Network_TV_CPM1 = NETTV_CPM_A2154_SPANISH
    Spanish_Language_Network_TV_GRP2 = NETTV_A2164_SPANISH
    Spanish_Language_Network_TV_IMP2 = NETTV_IMP_A2164_SPANISH
    Spanish_Language_Network_TV_CPM2 = NETTV_CPM_A2164_SPANISH
    Spot_TV_Units = SPOTTV_UNITS
    Spot_TV______000_ = SPOTTV_SPEND
    Spot_TV_GRP__TV_Households = SPOTTV_HH
    Spot_TV_IMP_000___TV_Households = SPOTTV_IMP_HH
    Spot_TV_CPM__TV_Households = SPOTTV_CPM_HH
    Spot_TV_GRP__P18_ = SPOTTV_18P
    Spot_TV_IMP_000___P18_ = SPOTTV_IMP_18P
    Spot_TV_CPM__P18_ = SPOTTV_CPM_18P
    Spot_TV_GRP__P21_54 = SPOTTV_A2154
    Spot_TV_IMP_000___P21_54 = SPOTTV_IMP_A2154
    Spot_TV_CPM__P21_54 = SPOTTV_CPM_A2154
    Spot_TV_GRP__P21_64 = SPOTTV_A2164
    Spot_TV_IMP_000___P21_64 = SPOTTV_IMP_A2164
    Spot_TV_CPM__P21_64 = SPOTTV_CPM_A2164
    Syndicated_TV_Units = SYNTV_UNITS
    Syndicated_TV______000_ = SYNTV_SPEND
    Syndicated_TV_GRP__TV_Households = SYNTV_HH
    Syndicated_TV_IMP_000___TV_House = SYNTV_IMP_HH
    Syndicated_TV_CPM__TV_Households = SYNTV_CPM_HH
    Syndicated_TV_GRP__P18_ = SYNTV_18P
    Syndicated_TV_IMP_000___P18_ = SYNTV_IMP_18P
    Syndicated_TV_CPM__P18_ = SYNTV_CPM_18P
    Syndicated_TV_GRP__P21_54 = SYNTV_A2154
    Syndicated_TV_IMP_000___P21_54 = SYNTV_IMP_A2154
    Syndicated_TV_CPM__P21_54 = SYNTV_CPM_A2154
    Syndicated_TV_GRP__P21_64 = SYNTV_A2164
    Syndicated_TV_IMP_000___P21_64 = SYNTV_IMP_A2164
    Syndicated_TV_CPM__P21_64 = SYNTV_CPM_A2164 ;
RUN;
DATA NATL_TV;
  SET NATL_TV;
  LENGTH BRAND $20. YEARMO $6.;
  FORMAT REPORT_START date9. REPORT_END date9.;
  BRAND=UPCASE(SCAN(BRAND_LONG,1));
  REPORT_START = MDY(SUBSTR(Report_Period,1,2),SUBSTR(Report_Period,4,2),SUBSTR(Report_Period,7,2));
  REPORT_END = MDY(SUBSTR(Report_Period,12,2),SUBSTR(Report_Period,15,2),SUBSTR(Report_Period,18,2));
  YEARMO = put(REPORT_END,yymmn6.);
RUN;
proc freq data=natl_tv; tables yearmo brand / list missing; run;

* Local TV - GRPS;
proc contents data=raw_locl_tv varnum; run;
DATA LOCL_TV;
  SET raw_locl_tv;
  RENAME Brand = Brand_Long 
    Report_Period__multiple_ = Report_period 
    Network_Clearance_Spot_TV_Units = NETSPOTTV_UNITS 
    Network_Clearance_Spot_TV______0 = NETSPOTTV_SPEND 
    Network_Clearance_Spot_TV_GRP__T = NETSPOTTV_HH
    Network_Clearance_Spot_TV_CPM__T = NETSPOTTV_CPM_HH
    Network_Clearance_Spot_TV_GRP__P = NETSPOTTV_18P
    Network_Clearance_Spot_TV_CPM__P = NETSPOTTV_CPM_18P
    Network_Clearance_Spot_TV_GRP__0 = NETSPOTTV_A2154
    Network_Clearance_Spot_TV_CPM__0 = NETSPOTTV_CPM_A2154
    Network_Clearance_Spot_TV_GRP__1 = NETSPOTTV_A2164
    Network_Clearance_Spot_TV_CPM__1 = NETSPOTTV_CPM_A2164
    Spot_TV_Units = SPOTTV_UNITS
    Spot_TV______000_ = SPOTTV_SPEND 
    Spot_TV_GRP__TV_Households = SPOTTV_HH 
    Spot_TV_CPM__TV_Households = SPOTTV_CPM_HH 
    Spot_TV_GRP__P18_ = SPOTTV_18P
    Spot_TV_CPM__P18_ = SPOTTV_CPM_18P
    Spot_TV_GRP__P21_54 = SPOTTV_A2154
    Spot_TV_CPM__P21_54 = SPOTTV_CPM_A2154
    Spot_TV_GRP__P21_64 = SPOTTV_A2164
    Spot_TV_CPM__P21_64 = SPOTTV_CPM_A2164
    Syndicated_Clearance_Spot_TV_Uni = SYNSPOTTV_UNITS 
    Syndicated_Clearance_Spot_TV____ = SYNSPOTTV_SPEND 
    Syndicated_Clearance_Spot_TV_GRP = SYNSPOTTV_HH
    Syndicated_Clearance_Spot_TV_CPM = SYNSPOTTV_CPM_HH
    Syndicated_Clearance_Spot_TV_GR0 = SYNSPOTTV_18P
    Syndicated_Clearance_Spot_TV_CP0 = SYNSPOTTV_CPM_18P
    Syndicated_Clearance_Spot_TV_GR1 = SYNSPOTTV_A2154
    Syndicated_Clearance_Spot_TV_CP1 = SYNSPOTTV_CPM_A2154
    Syndicated_Clearance_Spot_TV_GR2 = SYNSPOTTV_A2164
    Syndicated_Clearance_Spot_TV_CP2 = SYNSPOTTV_CPM_A2164;
RUN;
DATA LOCL_TV;
  SET LOCL_TV;
  LENGTH BRAND $20. YEARMO $6.;
  FORMAT REPORT_START date9. REPORT_END date9.;
  BRAND=UPCASE(SCAN(BRAND_LONG,1));
  REPORT_START = MDY(SUBSTR(Report_Period,1,2),SUBSTR(Report_Period,4,2),SUBSTR(Report_Period,7,2));
  REPORT_END = MDY(SUBSTR(Report_Period,12,2),SUBSTR(Report_Period,15,2),SUBSTR(Report_Period,18,2));
  YEARMO = put(REPORT_END,yymmn6.);
RUN;
proc freq data=LOCL_TV; tables yearmo brand / list missing; run;

* merge LOCL_TV data with DMA Codes;
proc sort data=locl_tv; by market; run;
proc sort data=raw_dma_xref(where=(duplicate_ind=0) rename=(dma_name = MARKET)) 
    out=dma_xref(keep=DMA_Code MARKET rename=(dma_code = DMA));
by MARKET;
run;
data locl_tv_2;
  merge locl_tv(in=a) dma_xref(in=b);
  by market;
  *inset=10*a+b;
run;
/*proc freq data=locl_tv_2; tables inset / list missing; run;
* ALL INSET=11; 
proc freq data=locl_tv_2; tables inset*dma*market / list missing; run; *210 DMAs;
*/
proc freq data=locl_tv_2; tables dma*market / list missing; run; *210 DMAs;

* store dma_xref as permanent data set;
/*data output.dma_xref_grp; set dma_xref; run;*/

* NATL Multi Media;
proc contents data=raw_natl_mm varnum; run;
DATA NATL_MM;
  SET raw_natl_mm;
  RENAME Brand = Brand_Long
    Report_Period__multiple_ = Report_Period
    Cable_TV_Units = MM_CABTV_UNITS
    Cable_TV______000_ = MM_CABTV_SPEND
    FSI_Coupon_Units = MM_FSI_UNITS 
    FSI_Coupon______000_ = MM_FSI_SPEND
    Internet_Units = MM_INT_UNITS
    Internet______000_ = MM_INT_SPEND
    National_Magazine_Units = MM_NATMAG_UNITS
    National_Magazine______000_ = MM_NATMAG_SPEND
    National_Newspaper_Units = MM_NATPAP_UNITS
    National_Newspaper______000_ = MM_NATPAP_SPEND
    National_Sunday_Supplement_Units = MM_NATSS_UNITS
    National_Sunday_Supplement______ = MM_NATSS_SPEND
    Network_Radio_Units = MM_NETRAD_UNITS
    Network_Radio______000_ = MM_NETRAD_SPEND
    Network_TV_Units = MM_NETTV_UNITS
    Network_TV______000_ = MM_NETTV_SPEND
    Outdoor_Units = MM_OUTDR_UNITS
    Outdoor______000_ = MM_OUTDR_SPEND
    Spanish_Language_Cable_TV_Units = MM_CABTV_UNITS_SPANISH
    Spanish_Language_Cable_TV______0 = MM_CABTV_SPEND_SPANISH
    Spanish_Language_Network_TV_Unit = MM_NETTV_UNITS_SPANISH
    Spanish_Language_Network_TV_____ = MM_NETTV_SPEND_SPANISH
    Spot_Radio_Units = MM_SPOTRAD_UNITS
    Spot_Radio______000_ = MM_SPOTRAD_SPEND
    Spot_TV_Units = MM_SPOTTV_UNITS
    Spot_TV______000_ = MM_SPOTTV_SPEND
    Syndicated_TV_Units = MM_SYNTV_UNITS
    Syndicated_TV______000_ = MM_SYNTV_SPEND;
RUN;
DATA NATL_MM;
  SET NATL_MM;
  LENGTH BRAND $20. YEARMO $6.;
  FORMAT REPORT_START date9. REPORT_END date9.;
  BRAND=UPCASE(SCAN(BRAND_LONG,1));
  REPORT_START = MDY(SUBSTR(Report_Period,1,2),SUBSTR(Report_Period,4,2),SUBSTR(Report_Period,7,2));
  REPORT_END = MDY(SUBSTR(Report_Period,12,2),SUBSTR(Report_Period,15,2),SUBSTR(Report_Period,18,2));
  YEARMO = put(REPORT_END,yymmn6.);
RUN;
proc freq data=NATL_MM; tables yearmo brand / list missing; run;


* LOCAL Multi Media;
proc contents data=raw_locl_mm varnum; run;
DATA LOCL_MM;
  SET raw_locl_mm;
  RENAME Brand = Brand_Long
    Report_Period__multiple_ = Report_Period
    FSI_Coupon_Units = MM_FSI_UNITS
    FSI_Coupon______000_ = MM_FSI_SPEND
    Local_Magazine_Units = MM_LOCMAG_UNITS
    Local_Magazine______000_ = MM_LOCMAG_SPEND
    Local_Newspaper_Units = MM_LOCPAP_UNITS
    Local_Newspaper______000_ = MM_LOCPAP_SPEND
    Local_Sunday_Supplement_Units = MM_LOCSS_UNITS
    Local_Sunday_Supplement______000 = MM_LOCSS_SPEND
    Outdoor_Units = MM_OUTDR_UNITS
    Outdoor______000_ = MM_OUTDR_SPEND
    Spot_Radio_Units = MM_SPOTRAD_UNITS
    Spot_Radio______000_ = MM_SPOTRAD_SPEND
    Spot_TV_Units = MM_SPOTTV_UNITS
    Spot_TV______000_ = MM_SPOTTV_SPEND;
RUN;
DATA LOCL_MM;
  SET LOCL_MM;
  LENGTH BRAND $20. YEARMO $6.;
  FORMAT REPORT_START date9. REPORT_END date9.;
  BRAND=UPCASE(SCAN(BRAND_LONG,1));
  REPORT_START = MDY(SUBSTR(Report_Period,1,2),SUBSTR(Report_Period,4,2),SUBSTR(Report_Period,7,2));
  REPORT_END = MDY(SUBSTR(Report_Period,12,2),SUBSTR(Report_Period,15,2),SUBSTR(Report_Period,18,2));
  YEARMO = put(REPORT_END,yymmn6.);
RUN;
proc freq data=LOCL_MM; tables yearmo brand / list missing; run;

* merge LOCL_MM data with DMA Codes;
proc sort data=locl_mm; by market; run;
proc sort data=raw_dma_xref(where=(duplicate_ind=0) rename=(dma_name = MARKET)) 
    out=dma_xref(keep=DMA_Code MARKET rename=(dma_code = DMA));
by MARKET;
run;
data locl_mm_2;
  merge locl_mm(in=a) dma_xref(in=b);
  by market;
  *inset=10*a+b;
run;
/*proc freq data=locl_mm_2; tables inset / list missing; run;
* ALL INSET=11; */
proc freq data=locl_mm_2; tables dma*market / list missing; run; *210 DMAs;
data locl_mm_2(drop=dma rename=(dma2=dma));
  set locl_mm_2;
  length dma2 $3.;
  dma2=trim(left(dma));
run;



/*
3. STORE ALL PROCESSED RAW DATA AS PERMANENT DATASETS
*/
data output.raw_natl_tv; set natl_tv; run;
data output.raw_locl_tv; set locl_tv_2; run;
data output.raw_natl_mm; set natl_mm; run;
data output.raw_locl_mm; set locl_mm_2; run;


/*
4. Shorten Each Dataset to contain only the necessary fields for the analysis (i.e., target GRPs)
*/
OPTIONS NOLABEL;
DATA output.sel_raw_natl_tv;
  SET output.raw_natl_tv;
  KEEP Market Brand Yearmo Report_Start Report_End creative commercial_duration
       CABTV_A2154 NETTV_A2154 SYNTV_A2154 SPOTTV_A2154 CABTV_A2154_SPANISH NETTV_A2154_SPANISH;
RUN;
DATA output.sel_raw_locl_tv;
  SET output.raw_locl_tv(rename=(dma=dma_0));
  length dma $3.;
  DMA = DMA_0;
  KEEP DMA Market Brand Yearmo Report_Start Report_End creative commercial_duration
       NETSPOTTV_A2154 SPOTTV_A2154 SYNSPOTTV_A2154;
RUN;

PROC SQL;
CREATE TABLE output.sel_raw_natl_mm AS
SELECT MARKET, BRAND, YEARMO, REPORT_START, REPORT_END, 
    SUM(MM_CABTV_UNITS + MM_NETTV_UNITS + MM_SYNTV_UNITS + MM_SPOTTV_UNITS + MM_CABTV_UNITS_SPANISH + MM_NETTV_UNITS_SPANISH) AS NATL_TV_UNITS,
    SUM(MM_NATMAG_UNITS + MM_NATPAP_UNITS + MM_NATSS_UNITS) AS NATL_PRINT_UNITS,
    SUM(MM_NETRAD_UNITS + MM_SPOTRAD_UNITS) AS NATL_RADIO_UNITS,
	SUM(MM_INT_UNITS) AS NATL_INTERNET_UNITS,
    SUM(MM_FSI_UNITS + MM_OUTDR_UNITS) AS NATL_OTHER_UNITS,
    SUM(MM_CABTV_SPEND + MM_NETTV_SPEND + MM_SYNTV_SPEND + MM_SPOTTV_SPEND + MM_CABTV_SPEND_SPANISH + MM_NETTV_SPEND_SPANISH) AS NATL_TV_SPEND,
    SUM(MM_NATMAG_SPEND + MM_NATPAP_SPEND + MM_NATSS_SPEND) AS NATL_PRINT_SPEND,
    SUM(MM_NETRAD_SPEND + MM_SPOTRAD_SPEND) AS NATL_RADIO_SPEND,
	SUM(MM_INT_SPEND) AS NATL_INTERNET_SPEND,
    SUM(MM_FSI_SPEND + MM_OUTDR_SPEND) AS NATL_OTHER_SPEND
FROM output.raw_natl_mm
GROUP BY MARKET, BRAND, YEARMO, REPORT_START, REPORT_END;
QUIT;

PROC SQL;
CREATE TABLE output.sel_raw_locl_mm AS
SELECT DMA, MARKET, BRAND, YEARMO, REPORT_START, REPORT_END, 
    SUM(MM_SPOTTV_UNITS) AS LOCL_TV_UNITS,
    SUM(MM_LOCMAG_UNITS + MM_LOCPAP_UNITS + MM_LOCSS_UNITS) AS LOCL_PRINT_UNITS,
    SUM(MM_SPOTRAD_UNITS) AS LOCL_RADIO_UNITS,
    SUM(MM_FSI_UNITS + MM_OUTDR_UNITS) AS LOCL_OTHER_UNITS,
    SUM(MM_SPOTTV_SPEND) AS LOCL_TV_SPEND,
    SUM(MM_LOCMAG_SPEND + MM_LOCPAP_SPEND + MM_LOCSS_SPEND) AS LOCL_PRINT_SPEND,
    SUM(MM_SPOTRAD_SPEND) AS LOCL_RADIO_SPEND,
    SUM(MM_FSI_SPEND + MM_OUTDR_SPEND) AS LOCL_OTHER_SPEND
FROM output.raw_locl_mm
GROUP BY DMA, MARKET, BRAND, YEARMO, REPORT_START, REPORT_END;
QUIT;
OPTIONS LABEL;

/*
PROC PRINTTO;
QUIT;
*/

PROC PRINTTO LOG="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\2 Compute Wtd GRPs by Week.LOG" NEW
			PRINT="C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\LOGS\2 Compute Wtd GRPs by Week.LST" NEW;

***************************************************************************;
* PGM 2: COMPUTE WEIGHTED GRPs BY WEEK FOR NATL ND LOCL TV GRPS            ;
*         MERGE NATIONAL AND LOCAL WEIGTHTED GRPS                          ;
***************************************************************************;
/*
1. Compute Weighted GRPs for RELEVANT NATIONAL TV media types.
*/
DATA SEL_RAW_NATL_TV; 
  SET OUTPUT.SEL_RAW_NATL_TV; 
  DURATION = SCAN(COMMERCIAL_DURATION,1)*1;
RUN;

/* Get eligible brand groups and prefix. It could be N to N match if multiple brands are repeated in multiple brand groups */
PROC SQL;
CREATE TABLE RAW_NATL_TV_2 AS
  SELECT A.*, B.BRAND_GROUP, C.PREFIX AS BG_PREFIX
  FROM SEL_RAW_NATL_TV A, CONF_BRANDS B, CONF_BRAND_PREFIX C
  WHERE B.BRAND_GROUP = C.BRAND_GROUP
    AND A.BRAND = B.BRAND
	AND B.INCLUDE_FLAG = "YES"
    AND C.INCLUDE_TV_GRP = "YES";
QUIT;
PROC FREQ DATA=RAW_NATL_TV_2; TABLES BRAND_GROUP*BRAND BRAND_GROUP*BG_PREFIX DURATION / LIST MISSING; RUN;

/* Compute relevant weighted national grps by brand_group, prrefix, report_end */
DATA RAW_NATL_TV_2;
  SET RAW_NATL_TV_2;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
RUN;
PROC SQL;
CREATE TABLE NATL_TV_WTD_GRP AS
  SELECT BRAND_GROUP, BG_PREFIX, REPORT_END,
         SUM((CABTV_&TGT_SUFFIX.*(DURATION/&STD_ADSECS.)) 
		       + (CABTV_&TGT_SUFFIX._SPANISH*(DURATION/&STD_ADSECS.)) 
               + (NETTV_&TGT_SUFFIX._SPANISH*(DURATION/&STD_ADSECS.))
             ) AS NATL_RELEVANT_WTD_GRPS
  FROM RAW_NATL_TV_2
  GROUP BY BRAND_GROUP, BG_PREFIX, REPORT_END; 
QUIT;
/* note: national level nettv and syntv are not included in NATL_RELEVANT_WTD_GRPS 
     since they are also captured at local level by Nielsen.; 
*/
/*
2. Compute Weighted GRPs for RELEVANT LOCAL TV media types.
*/
DATA SEL_RAW_LOCL_TV; 
  SET OUTPUT.SEL_RAW_LOCL_TV; 
  DURATION = SCAN(COMMERCIAL_DURATION,1)*1;
RUN;

/* Get eligible brand groups and prefix. It could be N to N match if multiple brands are repeated in multiple brand groups */
PROC SQL;
CREATE TABLE RAW_LOCL_TV_2 AS
  SELECT A.*, B.BRAND_GROUP, C.PREFIX AS BG_PREFIX
  FROM SEL_RAW_LOCL_TV A, CONF_BRANDS B, CONF_BRAND_PREFIX C
  WHERE B.BRAND_GROUP = C.BRAND_GROUP
    AND A.BRAND = B.BRAND
	AND B.INCLUDE_FLAG = "YES"
    AND C.INCLUDE_TV_GRP = "YES";
QUIT;
PROC FREQ DATA=RAW_LOCL_TV_2; TABLES BRAND_GROUP*BRAND BRAND_GROUP*BG_PREFIX DURATION / LIST MISSING; RUN;

/* Compute relevant weighted national grps by brand_group, prrefix, report_end */
DATA RAW_LOCL_TV_2;
  SET RAW_LOCL_TV_2;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
RUN;
PROC SQL;
CREATE TABLE LOCL_TV_WTD_GRP AS
  SELECT DMA, BRAND_GROUP, BG_PREFIX, REPORT_END,
         SUM((SPOTTV_&TGT_SUFFIX.*(DURATION / &STD_ADSECS.)) 
               + (NETSPOTTV_&TGT_SUFFIX.*(DURATION / &STD_ADSECS.))
               + (SYNSPOTTV_&TGT_SUFFIX.*(DURATION / &STD_ADSECS.))
            ) AS LOCL_RELEVANT_WTD_GRPS
  FROM RAW_LOCL_TV_2
  GROUP BY DMA, BRAND_GROUP, BG_PREFIX, REPORT_END; 
QUIT;
 
/*
3. MERGE NATIONAL AND LOCAL WEIGHTED GRPS AND GET TOTAL GRPS.
*/
/* 5.1. Form Reference table with all combinations of DMA, brand_group, and report_end */
data timeperiods(keep=report_end curr_wk num_days rename=(curr_wk=full_week));
  set  CONF_DATA_PERIOD(keep=data_start_week data_end_week);
  format wk_st DATE9. wk_ed DATE9. prev_wk DATE9. curr_wk DATE9. report_end DATE9.;
  wk_st=datepart(data_start_week);
  wk_ed=datepart(data_end_week);
  prev_wk = wk_st;
  curr_wk = wk_st;
  report_end = wk_st;
  num_days=7;
  output timeperiods;
  do while(curr_wk <= wk_ed);
    prev_wk = curr_wk; 
    curr_wk = INTNX( 'WEEK', curr_wk, 1, 'S' );
	report_end = curr_wk;
    if(month(prev_wk) not= month(curr_wk)) then do;
      num_days = curr_wk - mdy(month(curr_wk),1,year(curr_wk)) + 1;
    end;
	else do; num_days = report_end - prev_wk; end;
	if (report_end <= wk_ed) then output timeperiods; 
    if(month(prev_wk) not= month(curr_wk)) then do;
      report_end = mdy(month(curr_wk),1,year(curr_wk)) - 1;
	  num_days = report_end - prev_wk;
	  if (report_end <= wk_ed) then output timeperiods;
    end;
  end;
run;
proc sort data=timeperiods nodupkey; by report_end; run; * HAS ALL CALENDAR WEEKS + FULL WEEKS;

PROC SQL;
CREATE TABLE REFTBL AS
SELECT BRAND_GROUP, BG_PREFIX, DMA, REPORT_END, FULL_WEEK, NUM_DAYS
FROM 
 (SELECT DISTINCT A1.BRAND_GROUP, A1.PREFIX AS BG_PREFIX FROM CONF_BRANDS A0, CONF_BRAND_PREFIX A1
    WHERE A0.BRAND_GROUP = A1.BRAND_GROUP AND A0.INCLUDE_FLAG = "YES" AND A1.INCLUDE_TV_GRP = "YES") A,
 (SELECT DISTINCT DMA FROM LOCL_TV_WTD_GRP) B,
 TIMEPERIODS C; 
QUIT;

/* 5.2 Merge reference table with national and local GRPs */
PROC SORT DATA=REFTBL; BY BRAND_GROUP BG_PREFIX REPORT_END DMA; RUN;
PROC SORT DATA=NATL_TV_WTD_GRP; BY BRAND_GROUP BG_PREFIX REPORT_END; RUN;
DATA REF_AND_NATL;
  MERGE REFTBL(IN=A) NATL_TV_WTD_GRP(IN=B);
  BY BRAND_GROUP BG_PREFIX REPORT_END;
  IF A;
  INSET=10*A+B;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
RUN;
proc freq data=REF_AND_NATL; tables inset; run;

PROC SORT DATA=REF_AND_NATL; BY BRAND_GROUP BG_PREFIX REPORT_END DMA; RUN;
PROC SORT DATA=LOCL_TV_WTD_GRP; BY BRAND_GROUP BG_PREFIX REPORT_END DMA; RUN;
DATA REF_NATL_LOCL;
  MERGE REF_AND_NATL(IN=A) LOCL_TV_WTD_GRP(IN=B);
  BY BRAND_GROUP BG_PREFIX REPORT_END DMA;
  IF A;
  INSET2=10*A+B;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
  TOT_WTD_GRP = NATL_RELEVANT_WTD_GRPS + LOCL_RELEVANT_WTD_GRPS;
RUN;
proc freq data=REF_NATL_LOCL; tables inset2 INSET*INSET2 BRAND_GROUP*BG_PREFIX / list missing; run;
/* inset*inset2 --> 10*10 - in reference, not in natl and locl; 10*11 - in reference, not in natl, but in locl;
                    11*10 - in ref and natl, not in locl; 11*11 - in all files;
*/ 

/*
4. Transpose total weighted grps so that brand groups are in columns.
   Store the results in permanent dataset. 
*/
PROC SORT DATA=REF_NATL_LOCL; BY DMA REPORT_END FULL_WEEK NUM_DAYS BG_PREFIX; RUN;
PROC TRANSPOSE DATA=REF_NATL_LOCL OUT=TR_REF_NATL_LOCL(drop=_name_) PREFIX=GRP;
  BY DMA REPORT_END FULL_WEEK NUM_DAYS;
  ID BG_PREFIX;
  VAR TOT_WTD_GRP;
RUN;

DATA OUTPUT.WTD_GRP_BY_DMA_REPORT_WEEK; SET TR_REF_NATL_LOCL; RUN;


PROC PRINTTO;
QUIT;


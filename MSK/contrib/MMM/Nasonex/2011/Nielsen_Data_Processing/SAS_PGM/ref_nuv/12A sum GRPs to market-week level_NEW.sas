PROC PRINTTO LOG="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\12A sum GRPs to market-week level.LOG" NEW
			PRINT="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\12A sum GRPs to market-week level.LST" NEW;
***************************************************************************;
* PROCEDURE:                                                               ;
* - SUMMARIZE LOCAL TV GRPS TO MARKET-WEEK-MERCK/COMP WEIGHTED BY DURATION ;
***************************************************************************;

LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";
LIBNAME DTC1 "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

/*LIBNAME NEWIN "\\WPUSHH01\DINFOPLN\PRA\DTC\NIELSEN DATA\2008 analysis data";*/
libname newin "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

OPTIONS MLOGIC MPRINT SYMBOLGEN pagesize=max;

*MACRO VARIABLES ARE DEFINED AS FOLLOWS;
	*PROD=PRODUCT TO PROCESS;
	*LIST1=PROD+ANY OTHER UNBRANDED MERCK ADS;
	*LIST2=ALL COMPETITORS;
	*AGE=DEMOGRAPHIC AGE BREAK SUFFIX;
%LET PROD=NUVARING;
%LET LIST1=('NUVARING');
%LET LIST2=('YAZ','LOESTRIN','MIRENA','SEASONIQUE','YAZC');
%LET AGE=F1849;
/*%MACRO SUMMARY(PROD,LIST1,LIST2,AGE);*/

TITLE "LOCAL TV SUMMARY PROCESS - &PROD"; RUN; QUIT;
PROC FREQ DATA=	NEWIN.LOCL_TV_MM; TABLES DURATION/LIST MISSING; RUN;
PROC CONTENTS DATA=NEWIN.LOCL_TV_MM; RUN; 

DATA NEWIN.LOCL_TV_MM1;
     SET NEWIN.LOCL_TV_MM;
 LENGTH BRAND1 $200;
 IF BRAND='YAZ' AND FLAG='CORR' THEN BRAND1='YAZC';
 ELSE BRAND1=BRAND;
 drop brand;
RUN; 

PROC FREQ DATA=NEWIN.LOCL_TV_MM1; TABLES RECTYPE BRAND1*FLAG/LIST MISSING; RUN;  

DATA LOCTV(COMPRESS=YES); SET NEWIN.LOCL_TV_MM1
 (WHERE=((UPCASE(BRAND1) IN &LIST1 OR UPCASE(BRAND1) IN &LIST2) AND RECTYPE in ("TV", "PR")));
 IF YEAR GE 2009;
 /*IF UPCASE(BRAND1) IN &LIST1 THEN BRAND1="&PROD";	*/
 if duration=. then duration=0;
RUN;

proc freq data=loctv; tables brand1 duration rectype/list missing; run; 

PROC CONTENTS DATA=LOCTV; RUN; 

* SUM TO DMA WEEK BRAND AND DURATION LEVEL (SUM ACROSS DAYPART);
PROC MEANS DATA=LOCTV NOPRINT NWAY SUM;
CLASS MARKET REPORT_PERIOD BRAND1 DURATION;
VAR NETSPOTTV_HH NETSPOTTV_&AGE
    SPOTTV_HH SPOTTV_&AGE
    SYNSPOTTV_HH SYNSPOTTV_&AGE
	;
OUTPUT OUT=DTC.SUM(DROP=_TYPE_ _FREQ_) SUM=;

PROC PRINT DATA=DTC.SUM (OBS=10); RUN;

PROC SORT DATA=DTC.SUM; BY MARKET REPORT_PERIOD; RUN;

DATA NEWIN.NATL_TV_MM1;
     SET NEWIN.NATL_TV_MM;
 LENGTH BRAND1 $200;
 IF BRAND='YAZ' AND FLAG='CORR' THEN BRAND1='YAZC';
 ELSE BRAND1=BRAND;
 drop brand;
RUN; 
PROC FREQ DATA=NEWIN.NATL_TV_MM1; TABLES BRAND1*FLAG/LIST MISSING; RUN; 

*sum to week brand and duration level national tv (sum across daypart);
DATA natltv(COMPRESS=YES); SET dtc.natl_TV_MM1
 (WHERE=(UPCASE(BRAND1) IN &LIST1 OR UPCASE(BRAND1) IN &LIST2));
 if rectype ='TV';
 IF YEAR GE 2009;
 /*IF UPCASE(BRAND1) IN &LIST1 THEN BRAND1="&PROD";	*/
RUN;
proc freq data=natltv; tables brand1/list missing; run; 

PROC MEANS DATA=natltv NOPRINT NWAY SUM;
CLASS REPORT_PERIOD BRAND1 DURATION;
VAR NETTV_HH NETTV_&AGE
    cabTV_HH cabTV_&AGE
    SYNtV_HH SYNTV_&AGE
    NETTV_HH_SPANISH NETTV_&AGE._SPANISH
    CABTV_HH_SPANISH CABTV_&AGE._SPANISH;
OUTPUT OUT=DTC.SUM1(DROP=_TYPE_ _FREQ_) SUM=;
PROC PRINT DATA=DTC.SUM1 (OBS=10); RUN;
PROC SORT DATA=DTC.SUM OUT=LOCLSUM; BY REPORT_PERIOD BRAND1 DURATION; RUN;

/*
Sep/9/2010: add code here so as to not miss any data while merging local and national datasets;
*/
proc freq data=dtc.sum; tables duration /list missing; run; * local;
proc freq data=dtc.sum1; tables duration /list missing; run; * national;
data chk; set dtc.sum; if market="CHICAGO" ; run; * 1 rec with 0 duration.;

proc sql;
create table tmp1 as
select distinct report_period, brand1, duration from
(  select report_period, brand1, duration from dtc.sum /* local */
  union
  select report_period, brand1, duration from dtc.sum1 /* national */ );
quit;
proc sort data=tmp1; by report_period brand1 duration; run; * 77 recs;
proc sort data=dtc.sum out=tmp2(keep=market) nodupkey; by market; run; * 210 recs;
proc sql;
create table master_comb as select * from tmp2, tmp1;
quit; * 16,170 recs (=210*77);

* merge master combination with local grp data on market, report_period, brand1, duration;
proc sort data=master_comb; by market report_period brand1 duration; run;
proc sort data=dtc.sum out=tmp_local; by market report_period brand1 duration; run;
data loclsum2;
  merge master_comb(in=a) tmp_local(in=b);
  by market report_period brand1 duration;
  inset=10*a+b;
run;
proc freq data=loclsum2; tables inset; run;

* merge local and national data on report_period brand1 duration;
proc sort data=loclsum2; by report_period brand1 duration; run;
proc sort data=dtc.sum1 out=tmp_natl; by report_period brand1 duration; run;
data locl_natl_sum;
  merge loclsum2(in=a) tmp_natl(in=b);
  by report_period brand1 duration;
  inset2 = 10*a+b;
  inset3 = inset*10+b;
run;
proc freq data=locl_natl_sum; tables inset2 inset*inset2 inset3/ list missing; run;
* set as permanent dataset for QC;
proc sort data=locl_natl_sum; by inset3; run;
data dtc.locl_natl_sum; set locl_natl_sum; run;

/*
data dtc.tsum;
merge loclsum (in=locl)
      dtc.sum1 (in=natl);
by report_period brand1 duration;
ARRAY NUMS(*) _NUMERIC_; 
DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; 
END; 
drop k;
if locl;
run; 
*/
data dtc.tsum;
set dtc.locl_natl_sum;
if inset3 = 100 then delete; * remove these records as they are not in either local or national dataset;
ARRAY NUMS(*) _NUMERIC_; 
DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; 
END; 
drop k inset inset2;
run; 

proc sort data=dtc.tsum; by market report_period brand1 duration; run; 

DATA SUM2; SET DTC.tSUM; BY MARKET REPORT_PERIOD;

	%MACRO DUR(LEN);   ** CREATES VARS AT DURATION AND PRODUCT LEVEL;

		IF BRAND1="&PROD" THEN DO;
  			IF DURATION=&LEN THEN DO;
			NETSPOTTV_HH_&LEN=NETSPOTTV_HH;
    	 	NETSPOTTV_&AGE._&LEN=NETSPOTTV_&AGE;
    	 	SPOTTV_HH_&LEN=SPOTTV_HH;
    	 	SPOTTV_&AGE._&LEN=SPOTTV_&AGE;
    	 	SYNSPOTTV_HH_&LEN=SYNSPOTTV_HH;
    	 	SYNSPOTTV_&AGE._&LEN=SYNSPOTTV_&AGE;
			cabTV_HH_&LEN=cabTV_HH;
    	 	cabTV_&AGE._&LEN=cabTV_&AGE;
			CABTV_HH_SPANISH_&LEN=CABTV_HH_SPANISH;
			CABTV_&AGE._SPANISH_&LEN=CABTV_&AGE._SPANISH;
			netTV_HH_SPANISH_&LEN=netTV_HH_SPANISH;
			netTV_&AGE._SPANISH_&LEN=netTV_&AGE._SPANISH;

  			END;
			NPRINT_GRP=	PRINT_GRP;
		END;
		
	    ELSE IF UPCASE(BRAND1) IN ('YAZ','SEASONIQUE','LOESTRIN','MIRENA','YAZC') THEN DO;
  			IF DURATION=&LEN THEN DO; 
     		CNETSPOTTV_HH_&LEN=NETSPOTTV_HH;
     		CNETSPOTTV_&AGE._&LEN=NETSPOTTV_&AGE;
     		CSPOTTV_HH_&LEN=SPOTTV_HH;
     		CSPOTTV_&AGE._&LEN=SPOTTV_&AGE;
     		CSYNSPOTTV_HH_&LEN=SYNSPOTTV_HH;
     		CSYNSPOTTV_&AGE._&LEN=SYNSPOTTV_&AGE;
			CcabTV_HH_&LEN=cabTV_HH;
     		CcabTV_&AGE._&LEN=cabTV_&AGE;
			cCABTV_HH_SPANISH_&LEN=CABTV_HH_SPANISH;
			cCABTV_&AGE._SPANISH_&LEN=CABTV_&AGE._SPANISH;
			CnetTV_HH_SPANISH_&LEN=netTV_HH_SPANISH;
			CnetTV_&AGE._SPANISH_&LEN=netTV_&AGE._SPANISH;
  			END;
			CPRINT_GRP=PRINT_GRP;
		END;
		**ADD LOOPS FOR SUMMING BY COMPETITOR BRAND;
		%MACRO COMP(CPROD,PREFX);
		IF BRAND1="&CPROD" THEN DO;
  			IF DURATION=&LEN THEN DO;
      		&PREFX.NETSPOTTV_HH_&LEN=NETSPOTTV_HH;
     		&PREFX.NETSPOTTV_&AGE._&LEN=NETSPOTTV_&AGE;
     		&PREFX.SPOTTV_HH_&LEN=SPOTTV_HH;
     		&PREFX.SPOTTV_&AGE._&LEN=SPOTTV_&AGE;
     		&PREFX.SYNSPOTTV_HH_&LEN=SYNSPOTTV_HH;
     		&PREFX.SYNSPOTTV_&AGE._&LEN=SYNSPOTTV_&AGE;
			&PREFX.cabTV_HH_&LEN=cabTV_HH;
     		&PREFX.cabTV_&AGE._&LEN=cabTV_&AGE;
			&PREFX.cabTV_HH_spanish_&LEN=cabTV_HH_spanish;
     		&PREFX.cabTV_&AGE._spanish_&LEN=cabTV_&AGE._spanish;
			&PREFX.netTV_HH_spanish_&LEN=netTV_HH_spanish;
     		&PREFX.netTV_&AGE._spanish_&LEN=netTV_&AGE._spanish;

  			END;
			&PREFX.PRINT_GRP=PRINT_GRP;
		END;
		%MEND;
		%COMP(YAZ,Z); %COMP(LOESTRIN,L); %COMP(SEASONIQUE,S); %COMP(MIRENA,R); %COMP(YAZC,V)
		**END LOOPS FOR SUMMING BY COMPETITOR BRAND;
	%MEND;
	%DUR(15); %DUR(30); %DUR(45);%DUR(60);%DUR(75); 

	ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END;

	DROP K BRAND1 DURATION NETSPOTTV_HH NETSPOTTV_&AGE
  	 	 SPOTTV_HH SPOTTV_&AGE SYNSPOTTV_HH SYNSPOTTV_&AGE cabTV_HH cabTV_&AGE cabTV_HH_spanish cabTV_&AGE._spanish 
         netTV_HH_spanish netTV_&AGE._spanish PRINT_GRP;
RUN;

PROC PRINT DATA=SUM2(OBS=10); RUN;

* SUM TO DMA AND WEEK;
PROC MEANS DATA=SUM2 NWAY SUM NOPRINT;
	BY MARKET REPORT_PERIOD;
	VAR  NET:  SPOT:  SYN: CAB:	NPRINT:
		CNET: CSPOT: CSYN: CCAB: CPRINT:
		ZNET: ZSPOT: ZSYN: ZCAB: ZPRINT:
		LNET: LSPOT: LSYN: LCAB: LPRINT:
		SNET: SSPOT: SSYN: SCAB: SPRINT:
		RNET: RSPOT: RSYN: RCAB:  RPRINT: 
        VNET: VSPOT: VSYN: VCAB: ;
	OUTPUT OUT=DTC.SUMBYMKTWEEK(DROP=_TYPE_ _FREQ_) SUM=;
RUN;

PROC PRINT DATA=DTC.SUMBYMKTWEEK(OBS=4); RUN;
proc contents data=	DTC.SUMBYMKTWEEK; run;

DATA DTC1.WEEKLY_LOCAL_WEIGHTED_GRPS (/*DROP=K*/) MISMATCHES;
	MERGE DTC.MARKET_WEEKS_JUN10 (IN=A) DTC.SUMBYMKTWEEK (IN=B);
    /*FORMAT MONTH DATE7.; */
    BY MARKET REPORT_PERIOD;

    %MACRO DUR(LEN);   ** CREATES TRPS WEIGHTED BY DURATION (PRODUCT, COMP);

        WM_NETSPOTTV_&AGE._&LEN=NETSPOTTV_&AGE._&LEN*(&LEN/60);
        WM_SPOTTV_&AGE._&LEN=SPOTTV_&AGE._&LEN*(&LEN/60);
        WM_SYNSPOTTV_&AGE._&LEN=synspotTV_&AGE._&LEN*(&LEN/60);
		WM_cabTV_&AGE._&LEN=cabTV_&AGE._&LEN*(&LEN/60);
		WM_cabTV_&AGE._spanish_&LEN=cabTV_&AGE._spanish_&LEN*(&LEN/60);
		WM_netTV_&AGE._spanish_&LEN=netTV_&AGE._spanish_&LEN*(&LEN/60);


            WC_CNETSPOTTV_&AGE._&LEN=CNETSPOTTV_&AGE._&LEN*(&LEN/60);
            WC_CSPOTTV_&AGE._&LEN=CSPOTTV_&AGE._&LEN*(&LEN/60);
            WC_CSYNSPOTTV_&AGE._&LEN=CSYNSPOTTV_&AGE._&LEN*(&LEN/60);  
			WC_CcabTV_&AGE._&LEN=CcabTV_&AGE._&LEN*(&LEN/60);  
		    Wc_ccabTV_&AGE._spanish_&LEN=ccabTV_&AGE._spanish_&LEN*(&LEN/60);
		    Wc_cnetTV_&AGE._spanish_&LEN=cnetTV_&AGE._spanish_&LEN*(&LEN/60);

        WL_LNETSPOTTV_&AGE._&LEN=LNETSPOTTV_&AGE._&LEN*(&LEN/60);
        WL_LSPOTTV_&AGE._&LEN=LSPOTTV_&AGE._&LEN*(&LEN/60);
        WL_LSYNSPOTTV_&AGE._&LEN=LSYNSPOTTV_&AGE._&LEN*(&LEN/60); 
        WL_LcabTV_&AGE._&LEN=LcabTV_&AGE._&LEN*(&LEN/60);  
		WL_LcabTV_&AGE._spanish_&LEN=LcabTV_&AGE._spanish_&LEN*(&LEN/60);
		WL_LnetTV_&AGE._spanish_&LEN=LnetTV_&AGE._spanish_&LEN*(&LEN/60);


            Wz_zNETSPOTTV_&AGE._&LEN=ZNETSPOTTV_&AGE._&LEN*(&LEN/60);
            WZ_ZSPOTTV_&AGE._&LEN=ZSPOTTV_&AGE._&LEN*(&LEN/60);
            WZ_ZSYNSPOTTV_&AGE._&LEN=ZSYNSPOTTV_&AGE._&LEN*(&LEN/60);  
			WZ_ZcabTV_&AGE._&LEN=ZcabTV_&AGE._&LEN*(&LEN/60);  
		    WZ_ZcabTV_&AGE._spanish_&LEN=ZcabTV_&AGE._spanish_&LEN*(&LEN/60);
		    WZ_ZnetTV_&AGE._spanish_&LEN=ZnetTV_&AGE._spanish_&LEN*(&LEN/60);


        WS_SNETSPOTTV_&AGE._&LEN=SNETSPOTTV_&AGE._&LEN*(&LEN/60);
        WS_SSPOTTV_&AGE._&LEN=SSPOTTV_&AGE._&LEN*(&LEN/60);
        WS_SSYNSPOTTV_&AGE._&LEN=SSYNSPOTTV_&AGE._&LEN*(&LEN/60); 
  		Ws_scabTV_&AGE._&LEN=scabTV_&AGE._&LEN*(&LEN/60);  
		Ws_scabTV_&AGE._spanish_&LEN=scabTV_&AGE._spanish_&LEN*(&LEN/60);
		Ws_snetTV_&AGE._spanish_&LEN=snetTV_&AGE._spanish_&LEN*(&LEN/60);


            WR_RNETSPOTTV_&AGE._&LEN=RNETSPOTTV_&AGE._&LEN*(&LEN/60);
            WR_RSPOTTV_&AGE._&LEN=RSPOTTV_&AGE._&LEN*(&LEN/60);
            WR_RSYNSPOTTV_&AGE._&LEN=RSYNSPOTTV_&AGE._&LEN*(&LEN/60);  
			WR_RCABTV_&AGE._&LEN=RCABTV_&AGE._&LEN*(&LEN/60);  
			WR_RCABTV_&AGE._SPANISH_&LEN=RCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
			WR_RNETTV_&AGE._SPANISH_&LEN=RNETTV_&AGE._SPANISH_&LEN*(&LEN/60);

			WV_VNETSPOTTV_&AGE._&LEN=VNETSPOTTV_&AGE._&LEN*(&LEN/60);
            WV_VSPOTTV_&AGE._&LEN=VSPOTTV_&AGE._&LEN*(&LEN/60);
            WV_VSYNSPOTTV_&AGE._&LEN=VSYNSPOTTV_&AGE._&LEN*(&LEN/60);  
			WV_VcabTV_&AGE._&LEN=VcabTV_&AGE._&LEN*(&LEN/60);  
			WV_VcabTV_&AGE._spanish_&LEN=VcabTV_&AGE._spanish_&LEN*(&LEN/60);
			WV_VnetTV_&AGE._spanish_&LEN=VnetTV_&AGE._spanish_&LEN*(&LEN/60);



    %MEND;
     %DUR(15);  %DUR(30); %DUR(45); %DUR(60); %DUR(75);

	** CREATES CUMS OF TRPS WEIGHTED BY DURATION REGARDLESS OF TV TYPE **;
	WTRPS_&AGE=SUM (OF WM_:);
	WCTRPS_&AGE=SUM(OF WC_C:);
    WZTRPS_&AGE=SUM (OF WZ_Z:);
    WLTRPS_&AGE=SUM (OF WL_L:);
    WSTRPS_&AGE=SUM (OF WS_S:);
    WRTRPS_&AGE=SUM (OF WR_R:);
    WVTRPS_&AGE=SUM (OF WV_V:);

    YEAR=YEAR(REPORT_PERIOD); 
	MONTH=MONTH(REPORT_PERIOD);

   ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END;

	OUTPUT DTC1.WEEKLY_LOCAL_WEIGHTED_GRPS;
	IF A~=B THEN OUTPUT MISMATCHES;
	
RUN;

data a; set dtc1.weekly_local_weighted_grps; run; 
proc sort data=a; by year month; run; 
proc summary data=a; var wtrps_f1849 wctrps_f1849 wztrps_f1849 wltrps_f1849 wstrps_f1849 wrtrps_f1849 wvtrps_f1849; 
     by year month; output out=abc sum=; run; 

proc summary data=a; var wc_csynspottv_f1849: wv_vsynspottv_f1849: wz_zsynspottv_f1849: wl_lsynspottv_f1849: ws_ssynspottv_f1849: wr_rsynspottv_f1849:; 
     by year month; output out=syn sum=; run; 

/*%MEND;*/
/*%SUMMARY(SINGULAIR,('SINGULAIR'),('ADVAIR','ASMANEX','ASTELIN','CLARITIN','GLAXOSMITHKLINE','NASONEX','PULMICORT','ZYRTEC'),HH)*/;
PROC PRINTTO;
QUIT;

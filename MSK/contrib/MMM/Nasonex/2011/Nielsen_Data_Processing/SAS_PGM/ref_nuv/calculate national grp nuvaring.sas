******************************************************************************;
* PROCEDURE:                                                                  ;
* - SUMMARIZE NATIONAL TV GRPS TO MARKET-WEEK-MERCK/COMP WEIGHTED BY DURATION ;
******************************************************************************;

LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2010 profit plan\SAS datasets";
LIBNAME DTC1 "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2010 profit plan\SAS datasets";

OPTIONS MLOGIC MPRINT SYMBOLGEN;
%LET PROD=NUVARING;
%LET LIST1=('NUVARING');
%LET LIST2='YAZ','LOESTRIN','MIRENA','SEASONIQUE','YAZC';
%LET AGE=F1849;

*MACRO VARIABLES ARE DEFINED AS FOLLOWS;
	*PROD=PRODUCT TO PROCESS;
	*LIST1=PROD+ANY OTHER UNBRANDED MERCK ADS;
	*LIST2=ALL COMPETITORS;
	*AGE=DEMOGRAPHIC AGE BREAK SUFFIX;

/*%MACRO SUMMARY(PROD,LIST1,LIST2,AGE);*/

TITLE "NATIONAL TV SUMMARY PROCESS - &PROD"; RUN; QUIT;

PROC CONTENTS DATA=	DTC1.NATL_TV_MM; RUN; 


DATA DTC1.NATL_TV_MM1;
     SET DTC1.NATL_TV_MM;
 LENGTH BRAND1 $200;
 IF BRAND='YAZ' AND FLAG='CORR' THEN BRAND1='YAZC';
 ELSE BRAND1=BRAND;
 drop brand;
RUN;  

DATA NATLTV(COMPRESS=YES); SET DTC1.NATL_TV_MM1
 (WHERE=(RECTYPE="TV"));
 IF UPCASE(BRAND1) IN &LIST1 THEN BRAND1="&PROD"; 
RUN;

PROC FREQ DATA=NATLTV; TABLES BRAND1*DURATION/LIST MISSING; RUN;

* SUM TO DMA WEEK BRAND AND DURATION LEVEL (SUM ACROSS DAYPART);
PROC MEANS DATA=NATLTV NOPRINT NWAY SUM;
CLASS REPORT_PERIOD BRAND1 DURATION;
VAR NETTV_&AGE
    CABTV_&AGE
    SYNTV_&AGE
	/*NETTV_&AGE._SPANISH
    CABTV_&AGE._SPANISH*/;

OUTPUT OUT= SUM1(DROP=_TYPE_ _FREQ_) SUM=;

PROC PRINT DATA=SUM1 (OBS=10); RUN;

PROC SORT DATA=SUM1; BY REPORT_PERIOD BRAND1 DURATION; RUN;



DATA SUM2; SET SUM1; BY REPORT_PERIOD;

	%MACRO DUR(LEN);   ** CREATES VARS AT DURATION AND PRODUCT LEVEL;

		IF BRAND1="&PROD" THEN DO;
  			IF DURATION=&LEN THEN DO;
    	 	NETTV_&AGE._&LEN=NETTV_&AGE;
    	 	SYNTV_&AGE._&LEN=SYNTV_&AGE;
    	 	CABTV_&AGE._&LEN=CABTV_&AGE;
			/*CABTV_&AGE._SPANISH_&LEN=CABTV_&AGE._SPANISH;
			netTV_&AGE._SPANISH_&LEN=netTV_&AGE._SPANISH; */

  			END;
		END;
		ELSE IF UPCASE(BRAND1) IN (&LIST2) THEN DO;
  			IF DURATION=&LEN THEN DO;
     		CNETTV_&AGE._&LEN=NETTV_&AGE;
     		CSYNTV_&AGE._&LEN=SYNTV_&AGE;
    	 	CCABTV_&AGE._&LEN=CABTV_&AGE;
			/*CCABTV_&AGE._SPANISH_&LEN=CABTV_&AGE._SPANISH;
			CNETTV_&AGE._SPANISH_&LEN=NETTV_&AGE._SPANISH; */
  			END;
		END;
		**END LOOPS FOR SUMMING BY COMPETITOR BRAND;
		%MACRO COMP(CPROD,PREFX);
		IF BRAND1="&CPROD" THEN DO;
  			IF DURATION=&LEN THEN DO;
     		&PREFX.NETTV_&AGE._&LEN=NETTV_&AGE;
     		&PREFX.CABTV_&AGE._&LEN=CABTTV_&AGE;
     		&PREFX.SYNTV_&AGE._&LEN=SYNTV_&AGE;
     		/*&PREFX.cabTV_&AGE._SPANISH_&LEN=cabTV_&AGE._SPANISH;
     		&PREFX.netTV_&AGE._spanish_&LEN=netTV_&AGE._SPANISH; */
  			END; 
		END;
		%MEND;
		%COMP(YAZ,Z); %COMP(LOESTRIN,L); %COMP(SEASONIQUE,S); %COMP(MIRENA,R); %COMP(YAZC,V);
	%MEND;
	%DUR(10); %DUR(15); %DUR(30); %DUR(35); %DUR(50); %DUR(60); 

	ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END;

	DROP K BRAND1 DURATION NETTV_&AGE
  	 	 SYNTV_&AGE CABTV_&AGE /*cabTV_&AGE._spanish 
         netTV_&AGE._spanish*/;
RUN;


PROC PRINT DATA=SUM2(OBS=10); RUN;

* SUM TO DMA AND WEEK;
PROC SORT DATA=SUM2; BY REPORT_PERIOD; RUN;

PROC MEANS DATA=SUM2 NWAY SUM NOPRINT;
	BY REPORT_PERIOD;
	VAR  NETTV:  SYNTV: CABTV:
		CNETTV:  CSYNTV: CCABTV:
		ZNETTV:  ZSYNTV: ZCABTV:
		LNETTV:  LSYNTV: LCABTV:
		SNETTV:  SSYNTV: SCABTV:
		VNETTV:  VSYNTV: VCABTV:
		RNETTV:  RSYNTV: RCABTV:
        ;
	OUTPUT OUT=SUMBYMKTWEEK(DROP=_TYPE_ _FREQ_) SUM=;
RUN;

PROC PRINT DATA=SUMBYMKTWEEK(OBS=4); RUN;

DATA DTC1.WEEKLY_NATL_WEIGHTED_GRPS (DROP=K) MISMATCHES;
	MERGE DTC.WEEKS_DEC09 (IN=A) SUMBYMKTWEEK (IN=B);
    BY REPORT_PERIOD;

    %MACRO DUR(LEN);   ** CREATES TRPS WEIGHTED BY DURATION (PRODUCT, COMP);

        WM_NETTV_&AGE._&LEN=NETTV_&AGE._&LEN*(&LEN/60);
        WM_SYNTV_&AGE._&LEN=SYNTV_&AGE._&LEN*(&LEN/60);
		WM_CABTV_&AGE._&LEN=CABTV_&AGE._&LEN*(&LEN/60);
		/*WM_cabTV_&AGE._spanish_&LEN=cabTV_&AGE._spanish_&LEN*(&LEN/60);
		WM_netTV_&AGE._spanish_&LEN=netTV_&AGE._spanish_&LEN*(&LEN/60);	*/

            WC_CNETTV_&AGE._&LEN=CNETTV_&AGE._&LEN*(&LEN/60);
            WC_CSYNTV_&AGE._&LEN=CSYNTV_&AGE._&LEN*(&LEN/60);  
            WC_CCABTV_&AGE._&LEN=CCABTV_&AGE._&LEN*(&LEN/60);  
			/*Wc_ccabTV_&AGE._spanish_&LEN=ccabTV_&AGE._spanish_&LEN*(&LEN/60);
		    Wc_cnetTV_&AGE._spanish_&LEN=cnetTV_&AGE._spanish_&LEN*(&LEN/60); */

         WL_LNETTV_&AGE._&LEN=LNETTV_&AGE._&LEN*(&LEN/60);
         WL_LSYNTV_&AGE._&LEN=LSYNTV_&AGE._&LEN*(&LEN/60);  
         WL_LCABTV_&AGE._&LEN=LCABTV_&AGE._&LEN*(&LEN/60);  
	    /* WL_LCABTV_&AGE._SPANISH_&LEN=LCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
		 WL_LNETTV_&AGE._SPANISH_&LEN=LNETTV_&AGE._SPANISH_&LEN*(&LEN/60); */

		      WZ_ZNETTV_&AGE._&LEN=ZNETTV_&AGE._&LEN*(&LEN/60);
              WZ_ZSYNTV_&AGE._&LEN=ZSYNTV_&AGE._&LEN*(&LEN/60);  
              WZ_ZCABTV_&AGE._&LEN=ZCABTV_&AGE._&LEN*(&LEN/60);  
	          /*WZ_ZCABTV_&AGE._SPANISH_&LEN=ZCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
		      WZ_ZNETTV_&AGE._SPANISH_&LEN=ZNETTV_&AGE._SPANISH_&LEN*(&LEN/60);	*/

		   WS_SNETTV_&AGE._&LEN=SNETTV_&AGE._&LEN*(&LEN/60);
           WS_SSYNTV_&AGE._&LEN=SSYNTV_&AGE._&LEN*(&LEN/60);  
           WS_SCABTV_&AGE._&LEN=SCABTV_&AGE._&LEN*(&LEN/60);  
	      /* WS_SCABTV_&AGE._SPANISH_&LEN=SCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
		   WS_SNETTV_&AGE._SPANISH_&LEN=SNETTV_&AGE._SPANISH_&LEN*(&LEN/60); */

                WR_RNETTV_&AGE._&LEN=RNETTV_&AGE._&LEN*(&LEN/60);
                WR_RSYNTV_&AGE._&LEN=RSYNTV_&AGE._&LEN*(&LEN/60);  
                WR_RCABTV_&AGE._&LEN=RCABTV_&AGE._&LEN*(&LEN/60);  
	          /*  WM_MCABTV_&AGE._SPANISH_&LEN=MCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
		        WM_MNETTV_&AGE._SPANISH_&LEN=MNETTV_&AGE._SPANISH_&LEN*(&LEN/60); */
           
			WV_VNETTV_&AGE._&LEN=VNETTV_&AGE._&LEN*(&LEN/60);
            WV_VSYNTV_&AGE._&LEN=VSYNTV_&AGE._&LEN*(&LEN/60);  
            WV_VCABTV_&AGE._&LEN=VCABTV_&AGE._&LEN*(&LEN/60);  
	       /* WV_VCABTV_&AGE._SPANISH_&LEN=VCABTV_&AGE._SPANISH_&LEN*(&LEN/60);
		    WV_VNETTV_&AGE._SPANISH_&LEN=VNETTV_&AGE._SPANISH_&LEN*(&LEN/60); */


    %MEND;
   %DUR(10); %DUR(15);  %DUR(30); %DUR(35);  %DUR(50); %DUR(60);

	** CREATES CUMS OF TRPS WEIGHTED BY DURATION REGARDLESS OF TV TYPE **;
	WTRPS_&AGE=SUM (OF WM_:);
    WCTRPS_&AGE=SUM (OF WC_C:);
    WZTRPS_&AGE=SUM (OF WZ_Z:);
    WLTRPS_&AGE=SUM (OF WL_L:);
    WSTRPS_&AGE=SUM (OF WS_S:);
    WRTRPS_&AGE=SUM (OF WR_R:);
    WVTRPS_&AGE=SUM (OF WV_V:);

    YEAR=YEAR(REPORT_PERIOD); 
	MONTH=MONTH(REPORT_PERIOD);

    ARRAY NUMS(*) _NUMERIC_; DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; END;

	OUTPUT DTC1.WEEKLY_NATL_WEIGHTED_GRPS;
	IF A~=B THEN OUTPUT MISMATCHES;
	
RUN;

PROC SUMMARY DATA=DTC1.WEEKLY_NATL_WEIGHTED_GRPS; VAR WTRPS_F1849 WCTRPS_F1849 WZTRPS_F1849 WLTRPS_F1849 WSTRPS_F1849 WRTRPS_F1849 WVTRPS_F1849; by year month monthlabel;
    OUTPUT OUT=ABC SUM=; RUN; 

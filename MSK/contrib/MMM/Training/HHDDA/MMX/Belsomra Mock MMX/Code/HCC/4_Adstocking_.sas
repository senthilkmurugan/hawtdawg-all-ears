LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN;
LIBNAME HCC "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/FINAL_DATASET";


PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

************************************************ PROMO ADSTOCK

	*******************************************************************************;
* PICK THESE DECAY RATES ALWAYS: 0.25, 30, 0.40, 0.5, 0.6 AND 0.7 AND 0.8. THESE CORRESPOND TO HALF-LIFE FROM 2 WEEKS TO 8 WEEKS. DO
NOT GO ABOVE
THESE DECAY RATES AS THEY DON'T ALWAYS MAKE SENSE. ITS NOT OFTEN POSSIBLE THAT YOU SEE HALF-LIFES OF MORE THAN 2 MONTHS. ALSO, MINIMUM
HALF-LIFE CAN BE CHOSEN TO BE 2 WEEKS;
** A) IMPORT HALF-LIFES, DECAY RATES FROM CONFIGURATION TABLE **;

PROC IMPORT OUT=CONF_ADSTOCK_LAMBDA DATAFILE="/efs-MAIO/Team/promo_opt/MktMixPP/2022_Planning/Rotateq/input/ref/RAW_SAS_DATASETS/CONFIGURE GRP PROCESS.xlsx" 
		DBMS=XLSX REPLACE;
	SHEET="LAMBDA";
RUN;

PROC SORT DATA=CONF_ADSTOCK_LAMBDA;
	BY ADSTOCK_HALF_LIFE;
	WHERE adstock_suffix IN ('10' ,'20' ,'30' ,'40','50','60' ,'70', '75','80' ,'85', '90');
RUN;

** B)LIST ALL VARIABLES YOU NEED TO GET ADSTOCKS FOR **;

DATA MASTERDATA;
	SET  HCC.BELSOMRA_PRO_HCC_Feb20_JAN23;
	where yearmo >= 202101 and yearmo <=202301;
RUN;

proc print data=MASTERDATA (obs=10);
run;

%LET ADSTK_COLS =
hcc_disp_imp_XX_ 
hcc_olv_imp_XX_ 
hcc_osrch_sessions_XX_ 
hcc_psrch_clk_XX_ 
hcc_soc_imp_XX_ 
hcp_alert_eng_XX_ 
hcp_ban_eng_XX_ 
hcp_edtl_eng_XX_ 
hcp_eml_clkd_XX_ 
hcp_eml_eng_XX_ 
hcp_fmail_eng_XX_ 
hcp_grail_sdot_XX_ 
hcp_grail_vnrx_XX_ 
hcp_npp_eng_XX_ 
hcp_osrch_sessions_XX_ 
hcp_rdtl_totdet_XX_
hcp_disp_imp_XX_
pp_hcc_XX_
pp_hcp_XX_
pp_any_XX_
web_md_XX_
cw_comm_XX_
;

%PUT &ADSTK_COLS.;
** C) CONVERT INTO STRINGS FOR SQL TO ITERATE THROUGH. YOU WILL GET ERRORS BUT THAT IS OKAY. THE PROGRAM WOULD STILL RUN **;
%LET CALLADSTK = ;

PROC SQL;
	SELECT '%ADSTK1('||TRIM(LEFT(PUT(ADSTOCK_LAMBDA, 
		BEST.)))||','||TRIM(LEFT(ADSTOCK_SUFFIX))||');' INTO :CALLADSTK SEPARATED BY 
		'  ' FROM CONF_ADSTOCK_LAMBDA;
QUIT;

%PUT &CALLADSTK.;


** D) GET ADSTOCKS **;

PROC SORT DATA=MASTERDATA;
	BY dmaname yearmo;
RUN;

DATA TEMP2;
	SET MASTERDATA;
	BY DMANAME YEARMO;
	ARRAY GRPS(*) %SYSFUNC(TRANWRD(&ADSTK_COLS., _XX_, %STR( )));

	%MACRO ADSTK1(DECAY, HLLBL);
		ARRAY ADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS., _XX_, &HLLBL.));
		RETAIN ADS&HLLBL.;

		IF FIRST.DMANAME THEN
			DO;

				DO J=1 TO DIM(ADS&HLLBL.);
					ADS&HLLBL.(J)=GRPS(J);
				END;
			END;
		ELSE
			DO;

				DO J=1 TO DIM(ADS&HLLBL.);
					ADS&HLLBL.(J)=GRPS(J) + &DECAY.*ADS&HLLBL.(J);
				END;
			END;
	%MEND;

	&CALLADSTK.;
	DROP J;
RUN;

DATA MODEL.ADS_BELSOMRA_MDB_Feb21_JAN23;
	SET TEMP2;
RUN;

/* QC */
data check;
	set MODEL.ADS_BELSOMRA_MDB_Feb21_JAN23;
	KEEP DMANAME YEARMO hcc_disp_imp: 
hcc_olv_imp: 
hcc_osrch_sessions: 
hcc_psrch_clk: 
hcc_soc_imp: 
hcp_alert_eng: 
hcp_ban_eng: 
hcp_edtl_eng: 
hcp_eml_clkd: 
hcp_eml_eng: 
hcp_fmail_eng: 
hcp_grail_sdot: 
hcp_grail_vnrx: 
hcp_npp_eng: 
hcp_osrch_sessions: 
hcp_rdtl_totdet:;
RUN;


/* QC Check  */
proc sql;
select yearmo, sum(hcp_npp_eng), sum(hcp_dox_eng) from MODEL.ADS_BELSOMRA_MDB_Feb21_JAN23 group by 1 order by 1;
Run;

proc sql;
select yearmo, sum(hcp_grail_nrx), sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcc), sum(hcp_rdtl_totdet10), sum(hcp_rdtl_totdet) 
from MODEL.ADS_BELSOMRA_MDB_Feb21_JAN23 where yearmo<=202301 
group by 1 order by 1;
Run;
LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;
PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;
QUIT;


PROC IMPORT OUT = CONF_ADSTOCK_LAMBDA
DATAFILE = "/efs-MAIO/Team/promo_opt/MktMixPP/2022_Planning/Belsomra/input/ref/RAW_SAS_DATASETS/CONFIGURE GRP PROCESS.xlsx"
DBMS=xlsx REPLACE;
RUN;



PROC SORT DATA=CONF_ADSTOCK_LAMBDA;
BY ADSTOCK_HALF_LIFE;
where adstock_suffix IN ('10','20','30','40','50','60','70','80','90');
RUN;


proc print data=  hcp.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ(obs=5);
run;	

/* FILTER FOR FEW MONTHS */
DATA MASTER_DATA;
SET   HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ;
WHERE YEARMO >= 202101 and yearmo <=202301;
/* 25 Months of Ad-stocking */
RUN;


proc print data=MASTER_DATA (obs=10);
Run;

%LET ADSTK_COLS =
hcp_rdtl_totdet_XX_
hcp_grail_sdot_XX_
hcp_grail_vnrx_XX_
hcp_mmf_attend_XX_
hcp_dpint_eng_XX_
hcp_dox_eng_XX_
hcp_edh_eng_XX_
hcp_epoc_eng_XX_
hcp_field_eng_XX_
hcp_mscap_eng_XX_
hcp_mng_eng_XX_
hcp_sfmc_eng_XX_
hcp_alert_eng_XX_
hcp_ban_eng_XX_
hcp_edtl_eng_XX_
hcp_eml_eng_XX_
hcp_fmail_eng_XX_
hcp_field_clkd_XX_
hcp_mng_clkd_XX_
hcp_sfmc_clkd_XX_
hcp_sfmc_eng_post_XX_ 
hcp_sfmc_eng_pre_XX_ 
hcp_field_eng_post_XX_ 
hcp_field_eng_pre_XX_
;
%PUT &ADSTK_COLS.;




** C) CONVERT INTO STRINGS FOR SQL TO ITERATE THROUGH. YOU WILL GET ERRORS BUT THAT IS OKAY. THE PROGRAM WOULD STILL RUN **;

%LET CALLADSTK = ;

PROC SQL;
SELECT '%ADSTK1('||TRIM(LEFT(PUT(ADSTOCK_LAMBDA,BEST.)))||','||TRIM(LEFT(ADSTOCK_SUFFIX))||');'
INTO :CALLADSTK SEPARATED BY '  '
FROM CONF_ADSTOCK_LAMBDA;
QUIT;


%PUT &CALLADSTK.;

** D) GET ADSTOCKS **;
PROC SORT DATA = MASTER_DATA;
BY PARTY_ID yearmo;RUN;

DATA TEMP2;
SET MASTER_DATA;
BY PARTY_ID YEARMO;
ARRAY GRPS(*)  %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,%STR( )));
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY ADS&HLLBL.(*) %SYSFUNC(TRANWRD(&ADSTK_COLS.,_XX_,&HLLBL.));
    RETAIN ADS&HLLBL.;
    IF FIRST.PARTY_ID THEN DO;
      DO J=1 TO DIM(ADS&HLLBL.);
        ADS&HLLBL.(J) = GRPS(J);
      END;
    END;
    ELSE DO;
          DO J=1 TO DIM(ADS&HLLBL.);
            ADS&HLLBL.(J) = GRPS(J) + &DECAY.*ADS&HLLBL.(J);
          END;
    END;
  %MEND;
&CALLADSTK.;
DROP J;
RUN;


/* QC Check  */
proc sql;
select distinct(yearmo) from Temp2;
select count(distinct(party_id)) from temp2;
/* IDs:178403 */
run;

DATA  HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23; 
SET TEMP2; 
RUN;

PROC CONTENTS DATA=HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23; 
RUN;

/* QC Check */
proc sql;
select sum(hcp_dox_eng70), sum(hcp_dpint_eng30), sum(hcp_edh_eng), sum(hcp_epoc_eng90), 
sum(hcp_field_eng60), sum(hcp_grail_nrx_lag), sum(hcp_grail_sdot60), sum(hcp_grail_vnrx40), 
sum(hcp_mng_eng), sum(hcp_mscap_eng40), sum(hcp_rdtl_totdet40), sum(hcp_sfmc_eng70) from HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23 
where yearmo>=202102 and yearmo<=202301;
/* 45883.39	5084.011	1366	103169.9	127409.8	471890.9	6006831	18193.59	4328	70341.88	562696.9	1066114 */
Run;


PROC SUMMARY DATA= HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23 
(where = (yearmo >=202102 and yearmo <=202301 )) NWAY SUM;
VAR  party_id	yearmo	hcp_rdtl_dtl	hcp_rdtl_nbg	hcp_rdtl_rfm	hcp_rdtl_totdet	hcp_dpint_clkd	hcp_dox_clkd	hcp_edh_clkd	hcp_epoc_clkd	hcp_field_clkd	hcp_mscap_clkd	hcp_mng_clkd	hcp_sfmc_clkd	hcp_dpint_del	hcp_dox_del	hcp_edh_del	hcp_epoc_del	hcp_field_del	hcp_mscap_del	hcp_mng_del	hcp_sfmc_del	hcp_dpint_eng	hcp_dox_eng	hcp_edh_eng	hcp_epoc_eng	hcp_field_eng	hcp_mscap_eng	hcp_mng_eng	hcp_sfmc_eng	hcp_alert_clkd	hcp_ban_clkd	hcp_edtl_clkd	hcp_eml_clkd	hcp_fmail_clkd	hcp_alert_del	hcp_ban_del	hcp_edtl_del	hcp_eml_del	hcp_fmail_del	hcp_alert_eng	hcp_ban_eng	hcp_edtl_eng	hcp_eml_eng	hcp_fmail_eng	hcp_alert_dox_clkd	hcp_alert_edh_clkd	hcp_alert_epoc_clkd	hcp_alert_mscap_clkd	hcp_ban_dpint_clkd	hcp_ban_dox_clkd	hcp_edtl_edh_clkd	hcp_eml_mng_clkd	hcp_eml_sfmc_clkd	hcp_fmail_field_clkd	hcp_alert_dox_del	hcp_alert_edh_del	hcp_alert_epoc_del	hcp_alert_mscap_del	hcp_ban_dpint_del	hcp_ban_dox_del	hcp_edtl_edh_del	hcp_eml_mng_del	hcp_eml_sfmc_del	hcp_fmail_field_del	hcp_alert_dox_eng	hcp_alert_edh_eng	hcp_alert_epoc_eng	hcp_alert_mscap_eng	hcp_ban_dpint_eng	hcp_ban_dox_eng	hcp_edtl_edh_eng	hcp_eml_mng_eng	hcp_eml_sfmc_eng	hcp_fmail_field_eng	hcp_mmf_attend	hcp_grail_mnrx	hcp_grail_mtrx	hcp_grail_nrx	hcp_grail_sdot	hcp_grail_trx	hcp_grail_vnrx	hcp_grail_vtrx;
OUTPUT OUT =  SUMM(DROP = _:) SUM=;
RUN;

proc export data = summ outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks.xlsx" dbms= xlsx replace;
sheet = BEL_24M_SUMM_HCP_ADS_MAR22;
run;

proc sql;
select sum(hcp_field_eng_pre70), sum(hcp_sfmc_eng_pre70) from HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23 where yearmo >= 202201 and yearmo <=202212;
Run;
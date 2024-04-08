LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;
PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;

%*** Define macro for time array ***;;


**************************************************** GET FUNCTIONAL FORMS FOR PROMOTION ADSTOCKS
*****************************************;

DATA TEMP;  
SET HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23;
RUN;

/* Monthly Numbers */
proc sql;
select yearmo, sum(hcp_rdtl_totdet) as hcp_rdtl_totdet, 
sum(hcp_grail_sdot10) as hcp_grail_sdot10, 
sum(hcp_grail_vnrx20) as hcp_grail_vnrx20,
sum(hcp_dpint_eng30) as hcp_dpint_eng30,
sum(hcp_dox_eng40) as hcp_dox_eng40,
sum(hcp_edh_eng50) as hcp_edh_eng50,
sum(hcp_epoc_eng60) as hcp_epoc_eng60,
sum(hcp_field_eng70) as hcp_field_eng70,
sum(hcp_mscap_eng80) as hcp_mscap_eng80,
sum(hcp_mng_eng90) as hcp_mng_eng90,
sum(hcp_sfmc_eng10) as hcp_sfmc_eng10 
from HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23 
group by 1 order by 1;
Run;

** A) INTRODUCE FUNCTIONS TO X VARIABLES. 6 FUCTIONS ARE USED HERE: POWER OF 0.3, 0.4, 0.5, 0.6 (BASED ON BAYESION MODELS BY IMS WHERE
THE ROOT
OF TERMS ARE TRIED TO BE KEPT CLOSE TO 0.5 (0 - CONSTANT IMPACT W. NO SLOPE AND 1 - LINEAR IMPACT), SQUARE FOR CANNIBALIZATION, LN AND
X/(1+X)
WHICH IS SIMILAR TO (1/(1+E-X), WHERE SLOPE CONSTANTLY DECREASES FOR EVERY INCREMENTAL VALUE OF X VARIABLE. HERE ASYMPTOTE IS REALLY 1
BUT HOPING
THAT COEFFECIENT IS HIGH SO THAT GIVES COEFFICIENT*1 = COEFFICIENT WHICH IS MAX CONTRIBUTION OF A PARTICULAR CHANNEL **;


%MACRO FUNCTIONS(DS);
        DATA TEMP1;
        SET TEMP;

   %MACRO VARLOOP(NM);
		%DO I = 1 %TO 9 %BY 1;
            &NM._RT&I. = (&NM.)**(&I./10);
        %END;
		&NM._LOG = LOG(&NM.+1);
        %DO HL=10 %TO 90 %BY 10;
                        *ROOT: POWER OF 0.1 TO 0.9;
                               %DO J = 1 %TO 9 %BY 1;
                                  &NM.&HL._RT&J. = (&NM.&HL.)**(&J./10);
                               %END;


                        *LN - NATURAL LOG;
                                &NM.&HL._LOG = LOG(&NM.&HL.+1);
                                
                        *SIGMOID ;
/*                         		 &NM.&HL._sig = logistic(&NM.&HL.) */



        %END;
   %MEND;

 %varloop(hcp_rdtl_totdet);
 %varloop(hcp_grail_sdot);
 %varloop(hcp_mmf_attend);
 %varloop(hcp_dpint_eng);
 %varloop(hcp_dox_eng);
 %varloop(hcp_edh_eng);
 %varloop(hcp_epoc_eng);
 %varloop(hcp_field_eng);
 %varloop(hcp_mscap_eng);
 %varloop(hcp_mng_clkd);
 %varloop(hcp_sfmc_clkd);
 %varloop(hcp_mng_eng);
 %varloop(hcp_sfmc_eng);
 %varloop(hcp_alert_eng);
 %varloop(hcp_ban_eng);
 %varloop(hcp_edtl_eng);
 %varloop(hcp_eml_eng);
 %varloop(hcp_fmail_eng);
 %varloop(hcp_field_clkd);
 %varloop(hcp_grail_vnrx);
 %varloop(hcp_sfmc_eng_post);
 %varloop(hcp_sfmc_eng_pre); 
 %varloop(hcp_field_eng_post); 
 %varloop(hcp_field_eng_pre);
 
RUN;

%MEND;
%FUNCTIONS(TEMP);
RUN; QUIT;


** B) WRITE TO PERM LIBRARY **;

DATA  HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
SET TEMP1;
RUN;

proc contents data=HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
run;

PROC SUMMARY DATA=  HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23
(where = (yearmo >=202002 and yearmo <=202301)) NWAY SUM;
VAR  party_id	yearmo	hcp_rdtl_dtl	hcp_rdtl_nbg	hcp_rdtl_rfm	hcp_rdtl_totdet	hcp_dpint_clkd	hcp_dox_clkd	hcp_edh_clkd	hcp_epoc_clkd	hcp_field_clkd	hcp_mscap_clkd	hcp_mng_clkd	hcp_sfmc_clkd	hcp_dpint_del	hcp_dox_del	hcp_edh_del	hcp_epoc_del	hcp_field_del	hcp_mscap_del	hcp_mng_del	hcp_sfmc_del	hcp_dpint_eng	hcp_dox_eng	hcp_edh_eng	hcp_epoc_eng	hcp_field_eng	hcp_mscap_eng	hcp_mng_eng	hcp_sfmc_eng	hcp_alert_clkd	hcp_ban_clkd	hcp_edtl_clkd	hcp_eml_clkd	hcp_fmail_clkd	hcp_alert_del	hcp_ban_del	hcp_edtl_del	hcp_eml_del	hcp_fmail_del	hcp_alert_eng	hcp_ban_eng	hcp_edtl_eng	hcp_eml_eng	hcp_fmail_eng	hcp_alert_dox_clkd	hcp_alert_edh_clkd	hcp_alert_epoc_clkd	hcp_alert_mscap_clkd	hcp_ban_dpint_clkd	hcp_ban_dox_clkd	hcp_edtl_edh_clkd	hcp_eml_mng_clkd	hcp_eml_sfmc_clkd	hcp_fmail_field_clkd	hcp_alert_dox_del	hcp_alert_edh_del	hcp_alert_epoc_del	hcp_alert_mscap_del	hcp_ban_dpint_del	hcp_ban_dox_del	hcp_edtl_edh_del	hcp_eml_mng_del	hcp_eml_sfmc_del	hcp_fmail_field_del	hcp_alert_dox_eng	hcp_alert_edh_eng	hcp_alert_epoc_eng	hcp_alert_mscap_eng	hcp_ban_dpint_eng	hcp_ban_dox_eng	hcp_edtl_edh_eng	hcp_eml_mng_eng	hcp_eml_sfmc_eng	hcp_fmail_field_eng	hcp_mmf_attend	hcp_grail_mnrx	hcp_grail_mtrx	hcp_grail_nrx	hcp_grail_sdot	hcp_grail_trx	hcp_grail_vnrx	hcp_grail_vtrx;
OUTPUT OUT =  SUMM(DROP = _:) SUM=;
RUN;

proc export data = summ outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks.xlsx" dbms= xlsx replace;
sheet = BEL_24M_SUMM_HCP_FT_MAR22;
run;


PROC SUMMARY DATA=  HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23
(where = (yearmo >=202102 and yearmo <=202301)) NWAY SUM;
VAR  party_id	yearmo	hcp_rdtl_dtl	hcp_rdtl_nbg	hcp_rdtl_rfm	hcp_rdtl_totdet	hcp_dpint_clkd	hcp_dox_clkd	hcp_edh_clkd	hcp_epoc_clkd	hcp_field_clkd	hcp_mscap_clkd	hcp_mng_clkd	hcp_sfmc_clkd	hcp_dpint_del	hcp_dox_del	hcp_edh_del	hcp_epoc_del	hcp_field_del	hcp_mscap_del	hcp_mng_del	hcp_sfmc_del	hcp_dpint_eng	hcp_dox_eng	hcp_edh_eng	hcp_epoc_eng	hcp_field_eng	hcp_mscap_eng	hcp_mng_eng	hcp_sfmc_eng	hcp_alert_clkd	hcp_ban_clkd	hcp_edtl_clkd	hcp_eml_clkd	hcp_fmail_clkd	hcp_alert_del	hcp_ban_del	hcp_edtl_del	hcp_eml_del	hcp_fmail_del	hcp_alert_eng	hcp_ban_eng	hcp_edtl_eng	hcp_eml_eng	hcp_fmail_eng	hcp_alert_dox_clkd	hcp_alert_edh_clkd	hcp_alert_epoc_clkd	hcp_alert_mscap_clkd	hcp_ban_dpint_clkd	hcp_ban_dox_clkd	hcp_edtl_edh_clkd	hcp_eml_mng_clkd	hcp_eml_sfmc_clkd	hcp_fmail_field_clkd	hcp_alert_dox_del	hcp_alert_edh_del	hcp_alert_epoc_del	hcp_alert_mscap_del	hcp_ban_dpint_del	hcp_ban_dox_del	hcp_edtl_edh_del	hcp_eml_mng_del	hcp_eml_sfmc_del	hcp_fmail_field_del	hcp_alert_dox_eng	hcp_alert_edh_eng	hcp_alert_epoc_eng	hcp_alert_mscap_eng	hcp_ban_dpint_eng	hcp_ban_dox_eng	hcp_edtl_edh_eng	hcp_eml_mng_eng	hcp_eml_sfmc_eng	hcp_fmail_field_eng	hcp_mmf_attend	hcp_grail_mnrx	hcp_grail_mtrx	hcp_grail_nrx	hcp_grail_sdot	hcp_grail_trx	hcp_grail_vnrx	hcp_grail_vtrx;
OUTPUT OUT =  SUMM(DROP = _:) SUM=;
RUN;

proc export data = summ outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks.xlsx" dbms= xlsx replace;
sheet = BEL_24M_SUMM_HCP_FT_MAR22;
run;

PROC SQL;
SELECT COUNT(DISTINCT PARTY_ID) FROM HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
/* IDs:178403  */
SELECT SUM(PP_ANY) FROM HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
RUN;

proc sql;
select sum(hcp_field_eng_pre), sum(hcp_sfmc_eng_pre) from HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23 where yearmo >= 202201 and yearmo <=202212;
Run;
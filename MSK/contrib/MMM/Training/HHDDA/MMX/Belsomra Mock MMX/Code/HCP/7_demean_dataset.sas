LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;

PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;

/* QC Checks */
proc print data=HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23 (obs=10);
run;

proc sql;
select distinct yearmo from HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
run;


PROC STANDARD DATA= HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23 (where = (yearmo >=202102 and yearmo <=202301)) MEAN=0 REPLACE OUT=party;
BY party_id;
VAR hcp:;
RUN;


data hcp.FT_bel_hcp_mdb_Feb21_Jan23_DM;
SET PARTY;
RUN;

proc sql;
select distinct yearmo from hcp.FT_bel_hcp_mdb_Feb21_Jan23_DM;
run;

PROC SUMMARY DATA=  HCP.FT_bel_hcp_mdb_Feb21_Jan23_DM NWAY SUM;
VAR  party_id	hcp_rdtl_dtl	hcp_rdtl_nbg	hcp_rdtl_rfm	hcp_rdtl_totdet	hcp_dpint_clkd	hcp_dox_clkd	hcp_edh_clkd	hcp_epoc_clkd	hcp_field_clkd	hcp_mscap_clkd	hcp_mng_clkd	hcp_sfmc_clkd	hcp_dpint_del	hcp_dox_del	hcp_edh_del	hcp_epoc_del	hcp_field_del	hcp_mscap_del	hcp_mng_del	hcp_sfmc_del	hcp_dpint_eng	hcp_dox_eng	hcp_edh_eng	hcp_epoc_eng	hcp_field_eng	hcp_mscap_eng	hcp_mng_eng	hcp_sfmc_eng	hcp_alert_clkd	hcp_ban_clkd	hcp_edtl_clkd	hcp_eml_clkd	hcp_fmail_clkd	hcp_alert_del	hcp_ban_del	hcp_edtl_del	hcp_eml_del	hcp_fmail_del	hcp_alert_eng	hcp_ban_eng	hcp_edtl_eng	hcp_eml_eng	hcp_fmail_eng	hcp_alert_dox_clkd	hcp_alert_edh_clkd	hcp_alert_epoc_clkd	hcp_alert_mscap_clkd	hcp_ban_dpint_clkd	hcp_ban_dox_clkd	hcp_edtl_edh_clkd	hcp_eml_mng_clkd	hcp_eml_sfmc_clkd	hcp_fmail_field_clkd	hcp_alert_dox_del	hcp_alert_edh_del	hcp_alert_epoc_del	hcp_alert_mscap_del	hcp_ban_dpint_del	hcp_ban_dox_del	hcp_edtl_edh_del	hcp_eml_mng_del	hcp_eml_sfmc_del	hcp_fmail_field_del	hcp_alert_dox_eng	hcp_alert_edh_eng	hcp_alert_epoc_eng	hcp_alert_mscap_eng	hcp_ban_dpint_eng	hcp_ban_dox_eng	hcp_edtl_edh_eng	hcp_eml_mng_eng	hcp_eml_sfmc_eng	hcp_fmail_field_eng	hcp_mmf_attend	hcp_grail_mnrx	hcp_grail_mtrx	hcp_grail_nrx	hcp_grail_sdot	hcp_grail_trx	hcp_grail_vnrx	hcp_grail_vtrx;
OUTPUT OUT =  SUMM(DROP = _:) SUM=;
RUN;

proc export data = summ 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks.xlsx" 
dbms= xlsx replace;
sheet = BEL_24M_SUMM_HCP_FT_MAR22_DM;
run;

PROC SQL;
SELECT COUNT(DISTINCT PARTY_ID) FROM  HCP.FT_bel_hcp_mdb_Feb21_Jan23_DM;
/* 178403 */
RUN;
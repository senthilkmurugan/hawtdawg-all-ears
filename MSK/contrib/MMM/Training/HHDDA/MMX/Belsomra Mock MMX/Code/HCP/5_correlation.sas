LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;
PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;


DATA model_dataset;
SET  HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23;
WHERE YEARMO >= 202102 and yearmo <=202301;
RUN;

PROC CONTENTS DATA=model_dataset(OBS=5); RUN;

PROC CORR DATA= model_dataset out=corr_matrix;
VAR 
hcp_grail_nrx
hcp_rdtl_totdet
hcp_grail_sdot
hcp_grail_vnrx
hcp_grail_nrx_lag 
RTIME 
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_clkd
hcp_sfmc_clkd
hcp_mng_eng
hcp_sfmc_eng
hcp_alert_eng
hcp_ban_eng
hcp_edtl_eng
hcp_eml_eng
hcp_fmail_eng
hcp_field_clkd
hcp_sfmc_eng_post
hcp_sfmc_eng_pre 
hcp_field_eng_post 
hcp_field_eng_pre
;
RUN;

proc export data=corr_matrix dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/belsomra_corr_matrix_RESULTS.XLSX" 
		replace;
	sheet='HCP_24 corr Matrix';
run;


DATA model_dataset1;
SET  HCP.ADS_BEL_PRO_HCP_MDB_Feb20_Feb23;
WHERE YEARMO >= 202202 and yearmo <=202301;
RUN;



PROC CORR DATA= model_dataset1 out=corr_matrix;
VAR 
hcp_grail_nrx
hcp_rdtl_totdet
hcp_grail_sdot
hcp_grail_vnrx
hcp_grail_nrx_lag 
RTIME 
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_clkd
hcp_sfmc_clkd
hcp_mng_eng
hcp_sfmc_eng
hcp_alert_eng
hcp_ban_eng
hcp_edtl_eng
hcp_eml_eng
hcp_fmail_eng
hcp_field_clkd
hcp_sfmc_eng_post
hcp_sfmc_eng_pre 
hcp_field_eng_post 
hcp_field_eng_pre

;
RUN;

proc export data=corr_matrix dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/belsomra_corr_matrix_RESULTS.XLSX" 
		replace;
	sheet='HCP_12 corr Matrix';
run;




/* Dpint Adstock Correl */


PROC CORR DATA= model_dataset1 out=corr_matrix;
VAR 
hcp_grail_nrx
hcp_dpint_eng
hcp_dpint_eng10
hcp_dpint_eng20
hcp_dpint_eng30
hcp_dpint_eng40
hcp_dpint_eng50
hcp_dpint_eng60
hcp_dpint_eng70
hcp_dpint_eng80
hcp_dpint_eng90
;
RUN;




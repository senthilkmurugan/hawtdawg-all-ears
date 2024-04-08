LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";

/* BELSOMRA HCC MODELLLING 2022 */
PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

DATA MASTER_DATA;
	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	where rtime <= 24 and DMANAME  <> 'ZZUNASSIGNED';
RUN;

proc sql;
select Distinct yearmo, RTime, month, T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,
T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36 
from master_data;
run;

/* Correlation  */
PROC CORR DATA= MASTER_DATA out=corr_matrix;
VAR 
hcp_grail_nrx
hcc_disp_imp  
hcc_osrch_sessions 
hcc_psrch_clk 
hcc_soc_imp
hcp_disp_imp
hcp_grail_sdot 
hcp_grail_vnrx
hcp_rdtl_totdet
hcp_grail_nrx_lag
hcp_npp_eng
PP_HCP
PP_HCC
webmd
cw_comm
;
RUN;

proc export data=corr_matrix dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/belsomra_hcc_corr_matrix_RESULTS.XLSX" 
		replace;
	sheet='HCC_24 corr Matrix';
run;



/* Data Check; */
/* 	set MASTER_DATA; */
/* 	KEEP DMANAME YEARMO  */
/* 	hcp_grail_nrx */
/* 	hcc_disp_imp */
/* 	hcc_olv_imp */
/* 	hcc_osrch_sessions */
/* 	hcc_psrch_clk */
/* 	hcc_soc_imp */
/* 	hcp_alert_eng */
/* 	hcp_ban_eng */
/* 	hcp_edtl_eng */
/* 	hcp_eml_clkd */
/* 	hcp_eml_eng */
/* 	hcp_fmail_eng */
/* 	hcp_grail_sdot */
/* 	hcp_grail_vnrx */
/* 	hcp_npp_eng */
/* 	hcp_osrch_sessions */
/* 	hcp_rdtl_totdet; */
/* RUN; */
/*  */
/* proc export data=check dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/check.XLSX"  */
/* 		replace; */
/* 	sheet='check'; */
/* run; */
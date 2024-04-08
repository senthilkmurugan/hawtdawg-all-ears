/* Exporting Data from Athena For HCC */
libname MDB "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MDB";

proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCC_MDB_1.csv"
			out = temp1;
			guessingrows= 5 ;
			run;
			
proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCC_MDB_2.csv"
			out = temp2;
			guessingrows= 5 ;
			run;

data data1;
set temp1;
where var1 ne -999;
drop var1;
run;

data data2;
set temp2;
where var1 ne -999;
drop var1;
run;

data MDB.BELSOMRA_HCC_MDB_May19_Mar23;
set data1 data2;
run;

/* Checks */

proc print data=MDB.BELSOMRA_HCC_MDB_May19_Mar23 (obs=20);
run;

proc sql;
select distinct(yearmo) from MDB.BELSOMRA_HCC_MDB_May19_Mar23;
run;

data check;
set MDB.BELSOMRA_HCC_MDB_May19_Mar23;
where dmaname = "CHICAGO";
run;

proc summary data= MDB.BELSOMRA_HCC_MDB_May19_Mar23  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;

proc export data = summ 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/HCC_QC_MDB.xlsx" 
dbms= xlsx replace;
sheet = BEL_MDB_SUM_HCC;
run;

/* Use the below code to get the column names */
proc contents data=MDB.BELSOMRA_HCC_MDB_May19_Mar23
out=meta (keep=NAME); 
run;

proc print data=meta;
run;


proc sql;
create table Belsomra_HCC_Monthly_Agg_Data as 
select yearmo,
sum(hcc_osrch_sessions) as hcc_osrch_sessions,
sum(hcp_disp_una_imp) as hcp_disp_una_imp,
sum(hcp_disp_imp) as hcp_disp_imp,
sum(hcp_grail_mnrx) as hcp_grail_mnrx,
sum(hcp_grail_mtrx) as hcp_grail_mtrx,
sum(hcp_grail_nrx) as hcp_grail_nrx,
sum(hcp_grail_sdot) as hcp_grail_sdot,
sum(hcp_grail_trx) as hcp_grail_trx,
sum(hcp_grail_vnrx) as hcp_grail_vnrx,
sum(hcp_grail_vtrx) as hcp_grail_vtrx,
sum(hcp_dpint_clkd) as hcp_dpint_clkd,
sum(hcp_dox_clkd) as hcp_dox_clkd,
sum(hcp_edh_clkd) as hcp_edh_clkd,
sum(hcp_epoc_clkd) as hcp_epoc_clkd,
sum(hcp_field_clkd) as hcp_field_clkd,
sum(hcp_mscap_clkd) as hcp_mscap_clkd,
sum(hcp_mng_clkd) as hcp_mng_clkd,
sum(hcp_sfmc_clkd) as hcp_sfmc_clkd,
sum(hcp_dpint_del) as hcp_dpint_del,
sum(hcp_dox_del) as hcp_dox_del,
sum(hcp_edh_del) as hcp_edh_del,
sum(hcp_epoc_del) as hcp_epoc_del,
sum(hcp_field_del) as hcp_field_del,
sum(hcp_mscap_del) as hcp_mscap_del,
sum(hcp_mng_del) as hcp_mng_del,
sum(hcp_sfmc_del) as hcp_sfmc_del,
sum(hcp_dpint_eng) as hcp_dpint_eng,
sum(hcp_dox_eng) as hcp_dox_eng,
sum(hcp_edh_eng) as hcp_edh_eng,
sum(hcp_epoc_eng) as hcp_epoc_eng,
sum(hcp_field_eng) as hcp_field_eng,
sum(hcp_mscap_eng) as hcp_mscap_eng,
sum(hcp_mng_eng) as hcp_mng_eng,
sum(hcp_sfmc_eng) as hcp_sfmc_eng,
sum(hcp_alert_una_clkd) as hcp_alert_una_clkd,
sum(hcp_ban_una_clkd) as hcp_ban_una_clkd,
sum(hcp_edtl_una_clkd) as hcp_edtl_una_clkd,
sum(hcp_eml_una_clkd) as hcp_eml_una_clkd,
sum(hcp_fmail_una_clkd) as hcp_fmail_una_clkd,
sum(hcp_alert_una_del) as hcp_alert_una_del,
sum(hcp_ban_una_del) as hcp_ban_una_del,
sum(hcp_edtl_una_del) as hcp_edtl_una_del,
sum(hcp_eml_una_del) as hcp_eml_una_del,
sum(hcp_fmail_una_del) as hcp_fmail_una_del,
sum(hcp_alert_una_eng) as hcp_alert_una_eng,
sum(hcp_ban_una_eng) as hcp_ban_una_eng,
sum(hcp_edtl_una_eng) as hcp_edtl_una_eng,
sum(hcp_eml_una_eng) as hcp_eml_una_eng,
sum(hcp_fmail_una_eng) as hcp_fmail_una_eng,
sum(hcp_alert_clkd) as hcp_alert_clkd,
sum(hcp_ban_clkd) as hcp_ban_clkd,
sum(hcp_edtl_clkd) as hcp_edtl_clkd,
sum(hcp_eml_clkd) as hcp_eml_clkd,
sum(hcp_fmail_clkd) as hcp_fmail_clkd,
sum(hcp_alert_del) as hcp_alert_del,
sum(hcp_ban_del) as hcp_ban_del,
sum(hcp_edtl_del) as hcp_edtl_del,
sum(hcp_eml_del) as hcp_eml_del,
sum(hcp_fmail_del) as hcp_fmail_del,
sum(hcp_alert_eng) as hcp_alert_eng,
sum(hcp_ban_eng) as hcp_ban_eng,
sum(hcp_edtl_eng) as hcp_edtl_eng,
sum(hcp_eml_eng) as hcp_eml_eng,
sum(hcp_fmail_eng) as hcp_fmail_eng,
sum(hcp_alert_dox_clkd) as hcp_alert_dox_clkd,
sum(hcp_alert_edh_clkd) as hcp_alert_edh_clkd,
sum(hcp_alert_epoc_clkd) as hcp_alert_epoc_clkd,
sum(hcp_alert_mscap_clkd) as hcp_alert_mscap_clkd,
sum(hcp_ban_dpint_clkd) as hcp_ban_dpint_clkd,
sum(hcp_ban_dox_clkd) as hcp_ban_dox_clkd,
sum(hcp_edtl_edh_clkd) as hcp_edtl_edh_clkd,
sum(hcp_eml_mng_clkd) as hcp_eml_mng_clkd,
sum(hcp_eml_sfmc_clkd) as hcp_eml_sfmc_clkd,
sum(hcp_fmail_field_clkd) as hcp_fmail_field_clkd,
sum(hcp_alert_dox_del) as hcp_alert_dox_del,
sum(hcp_alert_edh_del) as hcp_alert_edh_del,
sum(hcp_alert_epoc_del) as hcp_alert_epoc_del,
sum(hcp_alert_mscap_del) as hcp_alert_mscap_del,
sum(hcp_ban_dpint_del) as hcp_ban_dpint_del,
sum(hcp_ban_dox_del) as hcp_ban_dox_del,
sum(hcp_edtl_edh_del) as hcp_edtl_edh_del,
sum(hcp_eml_mng_del) as hcp_eml_mng_del,
sum(hcp_eml_sfmc_del) as hcp_eml_sfmc_del,
sum(hcp_fmail_field_del) as hcp_fmail_field_del,
sum(hcp_alert_dox_eng) as hcp_alert_dox_eng,
sum(hcp_alert_edh_eng) as hcp_alert_edh_eng,
sum(hcp_alert_epoc_eng) as hcp_alert_epoc_eng,
sum(hcp_alert_mscap_eng) as hcp_alert_mscap_eng,
sum(hcp_ban_dpint_eng) as hcp_ban_dpint_eng,
sum(hcp_ban_dox_eng) as hcp_ban_dox_eng,
sum(hcp_edtl_edh_eng) as hcp_edtl_edh_eng,
sum(hcp_eml_mng_eng) as hcp_eml_mng_eng,
sum(hcp_eml_sfmc_eng) as hcp_eml_sfmc_eng,
sum(hcp_fmail_field_eng) as hcp_fmail_field_eng,
sum(hcp_rdtl_dtl) as hcp_rdtl_dtl,
sum(hcp_rdtl_nbg) as hcp_rdtl_nbg,
sum(hcp_rdtl_rfm) as hcp_rdtl_rfm,
sum(hcp_rdtl_totdet) as hcp_rdtl_totdet,
sum(hcc_disp_una_imp) as hcc_disp_una_imp,
sum(hcc_disp_imp) as hcc_disp_imp,
sum(hcc_soc_fb_una_clk) as hcc_soc_fb_una_clk,
sum(hcc_soc_tw_una_clk) as hcc_soc_tw_una_clk,
sum(hcc_soc_fb_una_imp) as hcc_soc_fb_una_imp,
sum(hcc_soc_tw_una_imp) as hcc_soc_tw_una_imp,
sum(hcc_soc_una_clk) as hcc_soc_una_clk,
sum(hcc_soc_una_imp) as hcc_soc_una_imp,
sum(hcc_soc_clk) as hcc_soc_clk,
sum(hcc_soc_imp) as hcc_soc_imp,
sum(hcc_soc_fb_clk) as hcc_soc_fb_clk,
sum(hcc_soc_tw_clk) as hcc_soc_tw_clk,
sum(hcc_soc_fb_imp) as hcc_soc_fb_imp,
sum(hcc_soc_tw_imp) as hcc_soc_tw_imp,
sum(hcp_osrch_sessions) as hcp_osrch_sessions,
sum(hcc_olv_una_imp) as hcc_olv_una_imp,
sum(hcc_olv_imp) as hcc_olv_imp,
sum(hcc_psrch_goog_una_clk) as hcc_psrch_goog_una_clk,
sum(hcc_psrch_msft_una_clk) as hcc_psrch_msft_una_clk,
sum(hcc_psrch_una_clk) as hcc_psrch_una_clk,
sum(hcc_psrch_clk) as hcc_psrch_clk,
sum(hcc_psrch_goog_clk) as hcc_psrch_goog_clk,
sum(hcc_psrch_msft_clk) as hcc_psrch_msft_clk,
sum(hcp_mmf_una_attend) as hcp_mmf_una_attend,
sum(hcp_mmf_attend) as hcp_mmf_attend,
sum(field_mdcnt) as field_mdcnt,
sum(mcm_mdcnt) as mcm_mdcnt 
from MDB.BELSOMRA_HCC_MDB_May19_Mar23
group by yearmo order by 1;
Quit;

proc export data = Belsomra_HCC_Monthly_Agg_Data 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/Belsomra_HCC_Monthly_Agg.xlsx" 
dbms= xlsx replace;
sheet = BEL_MON_AGG_HCC;
run;


PROC SQL;
SELECT COUNT(DISTINCT dmaname) FROM MDB.BELSOMRA_HCC_MDB_May19_Mar23;
/* 211 */
select distinct yearmo from MDB.BELSOMRA_HCC_MDB_May19_Mar23;
/*  Months: 47, May'19-Mar'23*/
select sum(hcp_grail_nrx), sum(hcc_psrch_clk), sum(hcc_soc_imp) from MDB.BELSOMRA_HCC_MDB_May19_Mar23 
where yearmo>=202102 and yearmo <= 202301;
/* 493963.4	478760	3.2405E8 */
RUN;

Proc SQL;
select yearmo, sum(hcp_grail_nrx), sum(hcp_dpint_eng), sum(hcp_dox_eng) 
from MDB.BELSOMRA_HCC_MDB_May19_Mar23 group by 1 order by 1;
Run;

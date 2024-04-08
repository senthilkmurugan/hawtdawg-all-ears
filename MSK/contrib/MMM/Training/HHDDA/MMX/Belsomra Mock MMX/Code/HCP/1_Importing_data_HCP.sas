/* 
Combining Data for HCP:
 	1. The raw data is pulled from Athena (in parquet format having 10-30 individual files).
 	2. The raw data from Athena is then feed into an Python code which combines files in batches into csv format (2-5 files).
 	3. The csv files are then combined in SAS with the requied processing and filters. 
*/


/* Defining the path */
libname MDB "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/MDB";

/* Pulling Each File for HCP level Data */
proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCP_MDB_1.csv"
			out = temp1;
			guessingrows= 5;
			run;
			
proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCP_MDB_2.csv"
			out = temp2;
			guessingrows= 5;
			run;
proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCP_MDB_3.csv"
			out = temp3;
			guessingrows= 5;
			run;
proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCP_MDB_4.csv"
			out = temp4;
			guessingrows= 5;
			run;

proc import datafile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/input/project_data/BELSOMRA_HCP_MDB_5.csv"
			out = temp5;
			guessingrows= 5;
			run;

/* Removing not required columns */
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

data data3;
set temp3;
where var1 ne -999;
drop var1;
run;

data data4;
set temp4;
where var1 ne -999;
drop var1;
run;

data data5;
set temp5;
where var1 ne -999;
drop var1;
run;


/* Combining All data and Filtering from a specific month */
data MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
set data1 data2 data3 data4 data5;
where yearmo >=202002;
run;

proc sort data=MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
by party_id yearmo;
run;

/* QC Checks */
proc sql;
select distinct(yearmo) from mdb.belsomra_hcp_mdb_feb20_feb23;
/* 202002 - 202302  */
run;

proc print data=mdb.belsomra_hcp_mdb_feb20_feb23 (obs=20);
run;

data check;
set MDB.BELSOMRA_HCP_MDB_Feb20_Feb23;
where party_id = 55449865;
run;

/* Creating Agg Sum of all the Columns  */
proc summary data= MDB.BELSOMRA_HCP_MDB_Feb20_Feb23  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;

proc export data = summ 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/HCP_QC_MDB.xlsx" 
dbms= xlsx replace;
sheet = BEL_MDB_SUMM_HCP;
run;


/* Use the below code to get the column names */
/* proc contents data=mdb.belsomra_hcp_mdb_feb20_feb23 */
/* out=meta (keep=NAME);  */
/* run; */
/* proc print data=meta; */
/* run; */


/* SQl code to get Agg Data at Monthly level */
proc sql;
create table Belsomra_HCP_Monthly_AGG_Data as 
select yearmo,
sum(hcp_alert_clkd) as hcp_alert_clkd,
sum(hcp_alert_del) as hcp_alert_del,
sum(hcp_alert_dox_clkd) as hcp_alert_dox_clkd,
sum(hcp_alert_dox_del) as hcp_alert_dox_del,
sum(hcp_alert_dox_eng) as hcp_alert_dox_eng,
sum(hcp_alert_edh_clkd) as hcp_alert_edh_clkd,
sum(hcp_alert_edh_del) as hcp_alert_edh_del,
sum(hcp_alert_edh_eng) as hcp_alert_edh_eng,
sum(hcp_alert_eng) as hcp_alert_eng,
sum(hcp_alert_epoc_clkd) as hcp_alert_epoc_clkd,
sum(hcp_alert_epoc_del) as hcp_alert_epoc_del,
sum(hcp_alert_epoc_eng) as hcp_alert_epoc_eng,
sum(hcp_alert_mscap_clkd) as hcp_alert_mscap_clkd,
sum(hcp_alert_mscap_del) as hcp_alert_mscap_del,
sum(hcp_alert_mscap_eng) as hcp_alert_mscap_eng,
sum(hcp_alert_una_clkd) as hcp_alert_una_clkd,
sum(hcp_alert_una_del) as hcp_alert_una_del,
sum(hcp_alert_una_eng) as hcp_alert_una_eng,
sum(hcp_ban_clkd) as hcp_ban_clkd,
sum(hcp_ban_del) as hcp_ban_del,
sum(hcp_ban_dox_clkd) as hcp_ban_dox_clkd,
sum(hcp_ban_dox_del) as hcp_ban_dox_del,
sum(hcp_ban_dox_eng) as hcp_ban_dox_eng,
sum(hcp_ban_dpint_clkd) as hcp_ban_dpint_clkd,
sum(hcp_ban_dpint_del) as hcp_ban_dpint_del,
sum(hcp_ban_dpint_eng) as hcp_ban_dpint_eng,
sum(hcp_ban_eng) as hcp_ban_eng,
sum(hcp_ban_una_clkd) as hcp_ban_una_clkd,
sum(hcp_ban_una_del) as hcp_ban_una_del,
sum(hcp_ban_una_eng) as hcp_ban_una_eng,
sum(hcp_dox_clkd) as hcp_dox_clkd,
sum(hcp_dox_del) as hcp_dox_del,
sum(hcp_dox_eng) as hcp_dox_eng,
sum(hcp_dpint_clkd) as hcp_dpint_clkd,
sum(hcp_dpint_del) as hcp_dpint_del,
sum(hcp_dpint_eng) as hcp_dpint_eng,
sum(hcp_edh_clkd) as hcp_edh_clkd,
sum(hcp_edh_del) as hcp_edh_del,
sum(hcp_edh_eng) as hcp_edh_eng,
sum(hcp_edtl_clkd) as hcp_edtl_clkd,
sum(hcp_edtl_del) as hcp_edtl_del,
sum(hcp_edtl_edh_clkd) as hcp_edtl_edh_clkd,
sum(hcp_edtl_edh_del) as hcp_edtl_edh_del,
sum(hcp_edtl_edh_eng) as hcp_edtl_edh_eng,
sum(hcp_edtl_eng) as hcp_edtl_eng,
sum(hcp_edtl_una_clkd) as hcp_edtl_una_clkd,
sum(hcp_edtl_una_del) as hcp_edtl_una_del,
sum(hcp_edtl_una_eng) as hcp_edtl_una_eng,
sum(hcp_eml_clkd) as hcp_eml_clkd,
sum(hcp_eml_del) as hcp_eml_del,
sum(hcp_eml_eng) as hcp_eml_eng,
sum(hcp_eml_mng_clkd) as hcp_eml_mng_clkd,
sum(hcp_eml_mng_del) as hcp_eml_mng_del,
sum(hcp_eml_mng_eng) as hcp_eml_mng_eng,
sum(hcp_eml_sfmc_clkd) as hcp_eml_sfmc_clkd,
sum(hcp_eml_sfmc_del) as hcp_eml_sfmc_del,
sum(hcp_eml_sfmc_eng) as hcp_eml_sfmc_eng,
sum(hcp_eml_una_clkd) as hcp_eml_una_clkd,
sum(hcp_eml_una_del) as hcp_eml_una_del,
sum(hcp_eml_una_eng) as hcp_eml_una_eng,
sum(hcp_epoc_clkd) as hcp_epoc_clkd,
sum(hcp_epoc_del) as hcp_epoc_del,
sum(hcp_epoc_eng) as hcp_epoc_eng,
sum(hcp_field_clkd) as hcp_field_clkd,
sum(hcp_field_del) as hcp_field_del,
sum(hcp_field_eng) as hcp_field_eng,
sum(hcp_fmail_clkd) as hcp_fmail_clkd,
sum(hcp_fmail_del) as hcp_fmail_del,
sum(hcp_fmail_eng) as hcp_fmail_eng,
sum(hcp_fmail_field_clkd) as hcp_fmail_field_clkd,
sum(hcp_fmail_field_del) as hcp_fmail_field_del,
sum(hcp_fmail_field_eng) as hcp_fmail_field_eng,
sum(hcp_fmail_una_clkd) as hcp_fmail_una_clkd,
sum(hcp_fmail_una_del) as hcp_fmail_una_del,
sum(hcp_fmail_una_eng) as hcp_fmail_una_eng,
sum(hcp_grail_mnrx) as hcp_grail_mnrx,
sum(hcp_grail_mtrx) as hcp_grail_mtrx,
sum(hcp_grail_nrx) as hcp_grail_nrx,
sum(hcp_grail_sdot) as hcp_grail_sdot,
sum(hcp_grail_trx) as hcp_grail_trx,
sum(hcp_grail_vnrx) as hcp_grail_vnrx,
sum(hcp_grail_vtrx) as hcp_grail_vtrx,
sum(hcp_mmf_attend) as hcp_mmf_attend,
sum(hcp_mng_clkd) as hcp_mng_clkd,
sum(hcp_mng_del) as hcp_mng_del,
sum(hcp_mng_eng) as hcp_mng_eng,
sum(hcp_mscap_clkd) as hcp_mscap_clkd,
sum(hcp_mscap_del) as hcp_mscap_del,
sum(hcp_mscap_eng) as hcp_mscap_eng,
sum(hcp_rdtl_dtl) as hcp_rdtl_dtl,
sum(hcp_rdtl_nbg) as hcp_rdtl_nbg,
sum(hcp_rdtl_rfm) as hcp_rdtl_rfm,
sum(hcp_rdtl_totdet) as hcp_rdtl_totdet,
sum(hcp_sfmc_clkd) as hcp_sfmc_clkd,
sum(hcp_sfmc_del) as hcp_sfmc_del,
sum(hcp_sfmc_eng) as hcp_sfmc_eng
from MDB.BELSOMRA_HCP_MDB_Feb20_Feb23 
group by yearmo order by 1;
run;

proc export data = Belsomra_HCP_Monthly_AGG_Data 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/Belsomra_HCP_Monthly_Agg.xlsx" 
dbms= xlsx replace;
sheet = BEL_MON_MDB_HCP;
run;


/* Check */
PROC SQL;
SELECT COUNT(DISTINCT PARTY_ID) FROM MDB.BELSOMRA_HCP_MDB_Feb20_Feb23; 
/* ID's: 632559 */

SELECT COUNT(*) FROM MDB.BELSOMRA_HCP_MDB_Feb20_Feb23; 
/* Count: 15666598 */

SELECT COUNT(*), COUNT(distinct party_id), sum(hcp_grail_nrx) 
FROM MDB.BELSOMRA_HCP_MDB_Feb20_Feb23 
where yearmo >=202102 and yearmo <=202301; 
/* Count: 14941647, ID's: 628204, Sales: 493963.4 */
RUN;

proc means data=MDB.BELSOMRA_HCP_MDB_Feb20_Feb23 NMISS N; 
run;
LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;

PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;


DATA TEMP;
	SET  HCP.FT_bel_hcp_mdb_Feb21_Jan23_DM;
RUN;

DATA OL;
	SET TEMP;
	z_nrx=hcp_grail_nrx;
RUN;

PROC STANDARD DATA=OL MEAN=0 STD=1 OUT=ZOL;
	VAR z_nrx;
	by party_id;
RUN;

DATA OL6;
	SET ZOL;
	WHERE z_nrx between -6 and 6;
RUN;

DATA OL12;
	SET ZOL;
	WHERE z_nrx between -12 and 12;
RUN;

data HCP.SD6_BEL_PRO_HCP_MDB_FEB21_JAN23;
	set OL6;
run;

data HCP.SD12_BEL_PRO_HCP_MDB_FEB21_JAN23;
	set OL12;
run;

proc sort data=HCP.SD6_BEL_PRO_HCP_MDB_FEB21_JAN23; by party_id yearmo;run;

proc sql;
create table SD6_QD as
select party_id,sum(hcp_grail_nrx) as NRx
,sum(hcp_rdtl_totdet) as Details,sum(hcp_grail_sdot) as samples,sum(hcp_dpint_eng) as dpint,
sum(hcp_dox_eng) as doximity,sum(hcp_edh_eng) as edh,sum(hcp_epoc_eng) as epocrates,
sum(hcp_field_eng) as field,sum(hcp_mscap_eng) as medscape
from HCP.SD6_BEL_PRO_HCP_MDB_FEB21_JAN23
 group by party_id;
run;

/*  */
/* data SD6_qd_party_id; */
/* set SD6_QD; */
/* by party_id; */
/* run; */

proc sort data=HCP.SD12_BEL_PRO_HCP_MDB_FEB21_JAN23; 
by party_id yearmo;run;

proc sql;
create table SD12_QD as
select party_id,sum(hcp_grail_nrx) as NRx
,sum(hcp_rdtl_totdet) as Details,sum(hcp_grail_sdot) as samples,sum(hcp_dpint_eng) as dpint,
sum(hcp_dox_eng) as doximity,sum(hcp_edh_eng) as edh,sum(hcp_epoc_eng) as epocrates,
sum(hcp_field_eng) as field,sum(hcp_mscap_eng) as medscape
from HCP.SD12_BEL_PRO_HCP_MDB_FEB21_JAN23
 group by party_id;
run;



proc export data = SD6_QD outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks_Outliers.xlsx" dbms= xlsx replace;
sheet = BEL_HCP_SD6;
run;


proc export data = SD12_QD outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks_Outliers.xlsx" dbms= xlsx replace;
sheet = BEL_HCP_SD12;
run;


proc summary data=SD6_QD  sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;


proc summary data=  HCP.SD12_BEL_PRO_HCP_MDB_FEB21_JAN23 sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;
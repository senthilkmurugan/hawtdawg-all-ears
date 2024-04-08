libname MDB "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/MDB";
LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";


/* Check the Months */
proc sql;
select distinct yearmo from MDB.BELSOMRA_HCP_Feb20_Feb23_Final;
run;


proc sql;
select yearmo, sum(pp_hcc) as pp_hcc, sum(pp_hcp) as pp_hcp, sum(webmd) as webmd, 
sum(cw_comm), sum(pp_hcc_agg) from MDB.BELSOMRA_HCP_Feb20_Feb23_Final group by 1 order by 1;
Run;

proc sql;
select count(*), count(distinct party_id),  sum(hcp_grail_nrx) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final where hcp_grail_nrx>1;
/* 269062	64494	436090.5 */
run;

proc sql;
select count(*), count(distinct party_id), sum(hcp_grail_nrx) 
from MDB.BELSOMRA_HCP_Feb20_Feb23_Final where hcp_grail_nrx>0;
/* 328179	73171	493963.4 */
run;

proc sql;
select distinct yearmo from MDB.BELSOMRA_HCP_Feb20_Feb23_Final;
run;


/* Overlap Summary for 24 Months */

/* Overlap I is at HCP x Month lvl */
data overlap_I;
	set  MDB.BELSOMRA_HCP_Feb20_Feb23_Final;
	ind_sales=0;
	ind_pp=0;
	ind_mcm=0;
	
	if hcp_grail_nrx > 0 then
		ind_sales=1;

	if sum(hcp_rdtl_totdet,hcp_grail_sdot,hcp_grail_vnrx,
		pp_hcp, pp_hcc, cw_comm, webmd) > 0 then
		ind_pp=1;

	if sum(hcp_dpint_del,hcp_dox_del,hcp_edh_del,hcp_epoc_del,
		hcp_field_del,hcp_mscap_del,hcp_mng_del,hcp_sfmc_del) > 0 then
		ind_mcm=1;	
	where yearmo between 202102 and 202301;
run;



/*  Check */
proc sql;
select distinct yearmo from overlap_I;
select count(*),count(distinct party_id), sum(hcp_grail_nrx) from overlap_I;
/* 15488448	645352	493963.4 */
select sum(ind_sales), sum(ind_pp), sum(ind_mcm) from overlap_I;
/* ind_sales:328179, ind_pp:1147974,ind_mcm:1633448 */
select count(*),count(distinct party_id), sum(hcp_grail_nrx),
 sum(ind_sales+ind_mcm+ind_pp) from overlap_I 
where ind_sales > 0 or ind_pp > 0 or ind_mcm > 0;
/* 2444662	178403	493963.4	3109601 */
run;

Proc sql;
select count(distinct party_id), sum(hcp_grail_nrx) from overlap_I where ind_sales >0;
/* 73171	493963.4 */
select sum(ind_sales), sum(ind_mcm), sum(ind_pp) from overlap_I;
/* 328179	1633448	1147974 */
select sum(hcp_rdtl_totdet+hcp_grail_sdot+hcp_grail_vnrx+pp_hcp+pp_hcc+cw_comm+webmd) from overlap_I;
/* 4104058 */
Run;


/* data char_overlap; */
/*     set overlap_I; */
/*     party_ids = put(party_id, 8.); */
/*     drop party_id */
/* run; */
/*  */
/* proc contents data=char_overlap; */


/* Overlap II is at HCP lvl */
proc sql;
	create table overlap_II as 
	select party_id, 
	sum(ind_sales) as ind_sales, 
	sum(ind_pp) as ind_pp, 
	sum(ind_mcm) as ind_mcm , 
	sum(hcp_grail_nrx) as NRx, 
	sum(hcp_rdtl_totdet) as totdet, 
	sum(hcp_grail_sdot) as samples, 
	sum(hcp_grail_vnrx) as vouchers,
	sum(hcp_dpint_del+hcp_dox_del+hcp_edh_del+hcp_epoc_del+hcp_field_del+hcp_mscap_del+hcp_mng_del+hcp_sfmc_del) as mcm_del,
	sum(hcp_dpint_eng+hcp_dox_eng+hcp_edh_eng+hcp_epoc_eng+hcp_field_eng+hcp_mscap_eng+hcp_mng_eng+hcp_sfmc_eng) as mcm_eng,
	sum(pp_hcp+pp_hcc+cw_comm+webmd) as poc
	from overlap_I group by party_id; 
	run;

proc sort data= overlap_II ;
by party_id;
run;

/* QC Check */
proc sql;
select sum(ind_sales), sum(ind_pp), sum(ind_mcm), sum(nrx), sum(totdet),
sum(samples), sum(vouchers), sum(mcm_del), sum(mcm_eng), sum(poc) 
from overlap_II;
/* Sales:328179,	PP:1147974,	MCM:1633448, 	NRx:493963.4	TotDet:345654,	Samples:2527725,	
Voucher:11192.33,	MCM_Del:5388198,	MCM_Eng:474327,	POC:1219487 */
run;


/* At HCP level converting > 0 to 1  */
data overlap_III;
	set overlap_II;

	if ind_sales > 0 then
		ind_sales=1;

	if ind_pp > 0 then
		ind_pp=1;

	if ind_mcm > 0 then
		ind_mcm=1;
run;


/* QC Check */
proc sql;
select max(ind_sales), max(ind_pp), max(ind_mcm) from overlap_II;
/* 24	24	24 */
select max(ind_sales), max(ind_pp), max(ind_mcm) from overlap_III;
/* 1	1	1 */
run;

proc sql;
Select count(distinct party_id) from overlap_III where sum(ind_sales,ind_pp,ind_mcm)>0;
/* 178403 */
Select count(distinct party_id) from overlap_III where ind_sales>0 or ind_pp>0 or ind_mcm>0;
/* 178403 */
Select sum(ind_sales), sum(ind_mcm), sum(ind_pp) from overlap_III where ind_sales>0 or ind_pp>0 or ind_mcm>0 ;
/* 73171	118376	93361 */
select count(*) from overlap_III where ind_sales>0 or ind_pp>0 or ind_mcm>0;
/* 178403 */
run;


proc sql;
	create table overlap_F as 
	select ind_sales, ind_pp, ind_mcm, count(party_id) 
		as HCP, sum(NRx) as NRX, sum( totdet) as DETAILS,
		sum(samples) as SAMPLES,sum(vouchers) as VOUCHERS, 
		sum(mcm_del) as MCM_DEL, SUM(mcm_eng) as MCM_ENG,
		sum(poc) as POC
		from WORK.OVERLAP_III 
		group by ind_sales , ind_pp , ind_mcm;
	run;
	
proc export data = overlap_F 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/Belsomra_overlap24_prod.xlsx" 
dbms=xlsx replace;
run;



/* Overlap Summary for 12 Months */

data overlap_4;
	set  MDB.BELSOMRA_HCP_Feb20_Feb23_Final;
	ind_sales=0;
	ind_pp=0;
	ind_mcm=0;
	
	if hcp_grail_nrx > 0 then
		ind_sales=1;

	if sum(hcp_rdtl_totdet,hcp_grail_sdot,hcp_grail_vnrx,
		pp_hcp, pp_hcc, cw_comm, webmd) > 0 then
		ind_pp=1;

	if sum(hcp_dpint_del,hcp_dox_del,hcp_edh_del,hcp_epoc_del,hcp_field_del,
	hcp_mscap_del,hcp_mng_del,hcp_sfmc_del) > 0 then
			ind_mcm=1;
		where yearmo between 202202 and 202301;
run;

proc sql;
	select distinct(yearmo) from overlap_4;
run;


proc sql;
	create table overlap_5 as select party_id, sum(ind_sales) as ind_sales, 
		sum(ind_pp) as ind_pp, sum(ind_mcm) as ind_mcm , sum(hcp_grail_nrx) as NRx, 
		sum(hcp_rdtl_totdet) as totdet, sum(hcp_grail_sdot) as samples, sum(hcp_grail_vnrx) as vouchers,
		sum(hcp_dpint_del+hcp_dox_del+hcp_edh_del+hcp_epoc_del+hcp_field_del+hcp_mscap_del+hcp_mng_del+hcp_sfmc_del) as mcm_del,
		sum(hcp_dpint_eng+hcp_dox_eng+hcp_edh_eng+hcp_epoc_eng+hcp_field_eng+hcp_mscap_eng+hcp_mng_eng+hcp_sfmc_eng) as mcm_eng,
		sum(pp_hcp+pp_hcc+cw_comm+webmd) as poc
		from overlap_4 group by party_id;
	run;

data overlap_6;	
	set overlap_5;

	if ind_sales > 0 then
		ind_sales=1;

	if ind_pp > 0 then
		ind_pp=1;

	if ind_mcm > 0 then
		ind_mcm=1;
run;

proc sql;
	create table overlap_F12 as 
	select ind_sales, ind_pp, ind_mcm, count(party_id) 
		as HCP, sum(NRx) as NRX, sum( totdet) as DETAILS,
		sum(samples) as SAMPLES,sum(vouchers) as VOUCHERS, 
		sum(mcm_del) as MCM_DEL, SUM(mcm_eng) as MCM_ENG,
		sum(poc) as POC 
		from WORK.OVERLAP_6 
		group by ind_sales , ind_pp , ind_mcm;
	run;
	
proc export data = overlap_F12 
outfile= "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/Belsomra_overlap12_prod.xlsx" 
dbms=xlsx replace;
run;



/* Removing HCP having No Contributions */

proc sql;
create table bel_prod as 
select * from  MDB.BELSOMRA_HCP_Feb20_Feb23_Final where party_id in 
(select distinct(party_id) as party_id from overlap_III group by party_id 
having sum(ind_sales+ind_pp+ind_mcm) > 0);
run;

/*  Checks */
proc sql;
select sum(hcp_grail_nrx), sum(hcp_rdtl_totdet), sum(hcp_grail_sdot), sum(hcp_grail_vnrx),
		sum(hcp_dpint_del+hcp_dox_del+hcp_edh_del+hcp_epoc_del+hcp_field_del+hcp_mscap_del+hcp_mng_del+hcp_sfmc_del), 
		sum(hcp_dpint_eng+hcp_dox_eng+hcp_edh_eng+hcp_epoc_eng+hcp_field_eng+hcp_mscap_eng+hcp_mng_eng+hcp_sfmc_eng), 
		sum(pp_hcp+pp_hcc+cw_comm+webmd) 
from bel_prod where yearmo between 202102 and 202301;
/* NRx:493963.4,	TotDet:345654,	Samples:2527725, Voucher:11192.33,	MCM_Del:5388198,	MCM_Eng:474327,	POC:1219487 */
run;


proc sql;
select count(distinct party_id) from MDB.BELSOMRA_HCP_Feb20_Feb23_Final 
where yearmo between 202102 and 202301;
/* IDs:645352 */

select count(distinct party_id) from bel_prod where yearmo between 202102 and 202301;
/* IDs:178403 */

select count(party_id) from (select Distinct(party_id) as party_id from overlap_III group by party_id 
having sum(ind_sales+ind_pp+ind_mcm)> 0);
/* IDs:178403 */
/* 27.6% is carried forward */
/* The Athena is a collection of HCP who are in the system for 4-5 years hence you will have HCPs with No sales and hence we are 
observing a huge drop in HCPs */
run;


/* data check; */
/* set bel_prod; */
/* where party_id = 55449865; */
/* run; */


/* Creating Standardized Dataset*/

/*  All Party ID(s)*/
proc sql;
create table party_id as 
select distinct party_id from bel_prod;
run;

/*  All Yearmo(s)*/
proc sql; create table yearmo as select distinct yearmo 
as yearmo from bel_prod where yearmo<=202301 order by yearmo;
run;

/* Cross Join */
proc sql;
create table dummy as select party_id, yearmo from yearmo 
cross join party_id ;
run;

/* sort dummy data */
proc  sort data= dummy; 
by party_id yearmo; 
run;

proc sort data= MDB.BELSOMRA_HCP_Feb20_Feb23_Final; 
by yearmo; 
run;

/* Keep required variables from MDB  */
data bel_hcp_merge;
set bel_prod;
keep
 hcp_rdtl_dtl	hcp_rdtl_nbg	hcp_rdtl_rfm	hcp_rdtl_totdet	hcp_dpint_clkd	hcp_dox_clkd	hcp_edh_clkd	
 hcp_epoc_clkd	hcp_field_clkd	hcp_mscap_clkd	hcp_mng_clkd	hcp_sfmc_clkd	hcp_dpint_del	hcp_dox_del	
 hcp_edh_del	hcp_epoc_del	hcp_field_del	hcp_mscap_del	hcp_mng_del	hcp_sfmc_del	hcp_dpint_eng	
 hcp_dox_eng	hcp_edh_eng	hcp_epoc_eng	hcp_field_eng	hcp_mscap_eng	hcp_mng_eng	hcp_sfmc_eng	
 hcp_alert_clkd	hcp_ban_clkd	hcp_edtl_clkd	hcp_eml_clkd	hcp_fmail_clkd	hcp_alert_del	hcp_ban_del	
 hcp_edtl_del	hcp_eml_del	hcp_fmail_del hcp_alert_eng	hcp_ban_eng	hcp_edtl_eng	hcp_eml_eng	hcp_fmail_eng	
 hcp_alert_dox_clkd	hcp_alert_edh_clkd	hcp_alert_epoc_clkd	hcp_alert_mscap_clkd	hcp_ban_dpint_clkd	hcp_ban_dox_clkd	
 hcp_edtl_edh_clkd	hcp_eml_mng_clkd	hcp_eml_sfmc_clkd	hcp_fmail_field_clkd	hcp_alert_dox_del	hcp_alert_edh_del	
 hcp_alert_epoc_del	hcp_alert_mscap_del	hcp_ban_dpint_del	hcp_ban_dox_del	hcp_edtl_edh_del	hcp_eml_mng_del	
 hcp_eml_sfmc_del	hcp_fmail_field_del	hcp_alert_dox_eng	hcp_alert_edh_eng	hcp_alert_epoc_eng	
 hcp_alert_mscap_eng	hcp_ban_dpint_eng	hcp_ban_dox_eng	hcp_edtl_edh_eng	hcp_eml_mng_eng	hcp_eml_sfmc_eng	
 hcp_fmail_field_eng hcp_sfmc_eng_post hcp_sfmc_eng_pre hcp_field_eng_post hcp_field_eng_pre
 hcp_mmf_attend	hcp_grail_mnrx	hcp_grail_mtrx	hcp_grail_nrx	hcp_grail_sdot	hcp_grail_trx	
 hcp_grail_vnrx	hcp_grail_vtrx pp_hcp pp_hcc cw_comm webmd 
 pp_hcp_agg pp_hcc_agg cw_comm_agg webmd_agg pp_any party_id yearmo;
run;

/* SORT AND MERGE */
PROC SORT DATA=bel_hcp_merge; 
BY PARTY_ID YEARMO; 
RUN;


PROC SQL ;
CREATE TABLE bel_hcp AS
SELECT A.*, B.* FROM DUMMY AS A LEFT JOIN bel_hcp_merge AS B 
ON A.PARTY_ID = B.PARTY_ID AND A.YEARMO = B.YEARMO;
RUN;


proc stdize data=bel_hcp
	out=bel_hcp1
	reponly missing=0;
run;

/* QC Check  */
proc sql;
select count(*) from bel_prod;
select count(*) from bel_hcp1;
select sum(hcp_rdtl_dtl) from bel_prod;
run;

proc means data=bel_prod sum nway;
where yearmo<=202301; 
run;
proc means data=bel_hcp1 sum nway; 
run;

proc means data=bel_prod NMISS N; 
run;
proc means data=bel_hcp1 NMISS N; 
run;


/* ADDING MONTH AND RTIME */
proc sort data= yearmo; 
by descending yearmo; 
/* by yearmo; */
/* where yearmo >= 202102 and yearmo <= 202301;  */
run;


data month;
	set YEARMO;
	format MONTH $CHAR5.;
	RTIME=_n_;
	MONTH=cat('MTH', PUT(RTIME, $Z2.));
run;


proc sql;
	CREATE TABLE bel_hcp2 AS 
	select a.*, b.RTIME, B.MONTH 
	FROM bel_hcp1 as a left join month as b on a.yearmo=b.yearmo;
	RUN;
	
/* Check  */
proc sql;
select Distinct RTIME, MONTH, yearmo FROM bel_hcp2;
RUN;


/* CREATING CONTROL VARIABLES */

proc sort data= bel_hcp2;
	by PARTY_ID yearmo;
run;

DATA MDB_belsomra_final;
	SET bel_hcp2;
	
/* 	tIME VARIABLES */
	ARRAY T(36) T1-T36;

	DO I=1 TO DIM(T);

		IF RTIME=I THEN
			T(I)=1;
		ELSE
			T(I)=0;
	END;
	DROP I;
	
/* 	LAGS */
	hcp_grail_nrx_lag=lag(hcp_grail_nrx);
	
	
/* 	NEW ADJUSTMENTS */
/* 	hcp_newalt_eng = hcp_alert_eng + hcp_alv_eng + hcp_eban_eng; */
/* 	hcp_newban_eng = hcp_ban_eng - hcp_ban_dpint_eng; */
/* 	hcp_3PVeml_eng = hcp_eml_eng - hcp_eml_sfmc_eng; */
	
/* 	MONTH VARIABLES */
	IF mod(yearmo, 100)=1 THEN
		M1=1;
	ELSE
		M1=0;

	IF mod(yearmo, 100)=2 THEN
		M2=1;
	ELSE
		M2=0;

	IF mod(yearmo, 100)=3 THEN
		M3=1;
	ELSE
		M3=0;

	IF mod(yearmo, 100)=4 THEN
		M4=1;
	ELSE
		M4=0;

	IF mod(yearmo, 100)=5 THEN
		M5=1;
	ELSE
		M5=0;

	IF mod(yearmo, 100)=6 THEN
		M6=1;
	ELSE
		M6=0;

	IF mod(yearmo, 100)=7 THEN
		M7=1;
	ELSE
		M7=0;

	IF mod(yearmo, 100)=8 THEN
		M8=1;
	ELSE
		M8=0;

	IF mod(yearmo, 100)=9 THEN
		M9=1;
	ELSE
		M9=0;

	IF mod(yearmo, 100)=10 THEN
		M10=1;
	ELSE
		M10=0;

	IF mod(yearmo, 100)=11 THEN
		M11=1;
	ELSE
		M11=0;

	IF mod(yearmo, 100)=12 THEN
		M12=1;
	ELSE
		M12=0;
	
/* 	RTIME EXPONENTS  */
	RTIME_SQ=RTIME*RTIME;
	RTIME_CUB=RTIME*RTIME*RTIME;
RUN;

DATA HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ;
SET MDB_BELSOMRA_FINAL;
RUN;

/* QC Check  */
proc means data=HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ NMISS N; 
run;

proc sql;
select Distinct yearmo, RTime, month, T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,
T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36 
from HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ;
run;

proc sql;
select Distinct RTime, month, yearmo, M1,M2,M3,M4,M5,M6,M7,M8,M9,M10,M11,M12 
from HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ;
run;
 

data HCP.BEL_PRO_HCP_MDB_FEB21_JAN23;
SET HCP.BEL_PRO_HCP_MDB_FEB20_FEB23_Univ;
WHERE YEARMO >= 202102 AND YEARMO <= 202301;
RUN;

/* proc summary data=  HCP.BEL_PRO_HCP_MDB_HCP_APR20_MAR22(where = (yearmo >=202004 and yearmo <=202203  )) sum nway; */
/* var _numeric_; */
/* output out = summ(drop = _:) sum=; */
/* run; */

proc summary data=  HCP.BEL_PRO_HCP_MDB_FEB21_JAN23 sum nway;
var _numeric_;
output out = summ(drop = _:) sum=;
run;


proc export data = summ outfile=
 "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/QC_Checks.xlsx" dbms= xlsx replace;
sheet = BEL_24M_SUMM_HCP_JAN23;
run;


PROC SQL;
SELECT COUNT(DISTINCT PARTY_ID) FROM HCP.BEL_PRO_HCP_MDB_FEB21_JAN23;
/* IDs:178403 */
RUN;

data check;
set HCP.BEL_PRO_HCP_MDB_FEB21_JAN23;
where party_id = 55449865;
run;

proc sql;
select sum(hcp_field_eng_pre), sum(hcp_sfmc_eng_pre) from HCP.BEL_PRO_HCP_MDB_FEB21_JAN23 where yearmo >= 202201 and yearmo <=202212;
Run; 

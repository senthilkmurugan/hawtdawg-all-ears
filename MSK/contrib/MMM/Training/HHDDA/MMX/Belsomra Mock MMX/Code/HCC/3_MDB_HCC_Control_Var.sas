/* Defining Libraries */
LIBNAME HCC "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/FINAL_DATASET";

/* Coagulating Feb20_Mar22; */
DATA TEMP;
SET HCC.BELSOMRA_HCC_Feb20_Jan23_Final;
RUN;

/* QC Check */
PROC SQL;
SELECT yearmo , sum(hcp_grail_nrx), sum(pp_hcc) FROM TEMP 
group by yearmo 
order by yearmo;
RUN;

/* Selecting Necessary Variables */
data temp_HCC;
	set temp;
	keep dmaname yearmo hcp_alert_clkd hcp_alert_del hcp_alert_dox_clkd 
		hcp_alert_dox_del hcp_alert_dox_eng hcp_alert_edh_clkd hcp_alert_edh_del 
		hcp_alert_edh_eng hcp_alert_eng hcp_alert_epoc_clkd hcp_alert_epoc_del 
		hcp_alert_epoc_eng hcp_alert_mscap_clkd hcp_alert_mscap_del 
		hcp_alert_mscap_eng hcp_ban_clkd hcp_ban_del hcp_ban_dox_clkd hcp_ban_dox_del 
		hcp_ban_dox_eng hcp_ban_dpint_clkd hcp_ban_dpint_del hcp_ban_dpint_eng 
		hcp_ban_eng hcp_disp_imp hcp_dox_clkd hcp_dox_del hcp_dox_eng hcp_dpint_clkd 
		hcp_dpint_del hcp_dpint_eng hcp_edh_clkd hcp_edh_del hcp_edh_eng 
		hcp_edtl_clkd hcp_edtl_del hcp_edtl_edh_clkd hcp_edtl_edh_del 
		hcp_edtl_edh_eng hcp_edtl_eng hcp_eml_clkd hcp_eml_del hcp_eml_eng 
		hcp_eml_mng_clkd hcp_eml_mng_del hcp_eml_mng_eng hcp_eml_mscap_clkd 
		hcp_eml_mscap_del hcp_eml_mscap_eng hcp_eml_sfmc_clkd hcp_eml_sfmc_del 
		hcp_eml_sfmc_eng hcp_epoc_clkd hcp_epoc_del hcp_epoc_eng hcp_field_clkd 
		hcp_field_del hcp_field_eng hcp_fmail_clkd hcp_fmail_del hcp_fmail_eng 
		hcp_fmail_field_clkd hcp_fmail_field_del hcp_fmail_field_eng hcp_grail_mnrx 
		hcp_grail_mtrx hcp_grail_nrx hcp_grail_sdot hcp_grail_trx hcp_grail_vnrx 
		hcp_grail_vtrx hcp_mmf_attend hcp_mng_clkd hcp_mng_del hcp_mng_eng 
		hcp_mscap_clkd hcp_mscap_del hcp_mscap_eng hcp_npp_clkd hcp_npp_del 
		hcp_npp_eng hcp_osrch hcp_osrch_sessions hcp_rdtl_dtl hcp_rdtl_nbg 
		hcp_rdtl_rfm hcp_rdtl_totdet hcp_sfmc_clkd hcp_sfmc_del hcp_sfmc_eng 
		pop18plus pop2554 popf2554 hcc_disp_imp hcc_olv_imp hcc_osrch 
		hcc_osrch_sessions hcc_psrch_clk hcc_soc_imp pp_hcp pp_hcc pp_any webmd cw_comm;
run;

proc sort data=temp_HCC out=HCC.BELSOMRA_HCC_Feb20_Jan23_Final;
	by dmaname yearmo;
run;


/* *********Selecting Unique Months************************ */
proc sql; 
create table yearmo 
as select distinct yearmo as yearmo from HCC.BELSOMRA_HCC_Feb20_Jan23_Final 
order by yearmo;
run;

/* ADDING MONTH AND RTIME */
proc sort data= yearmo; 
by descending yearmo; 
run;

data month;
	set YEARMO;
	format MONTH $CHAR5.;
	RTIME=_n_;
	MONTH=cat('MTH', PUT(RTIME, $Z2.));
run;

proc sql;
	CREATE TABLE bel_hcc AS 
	select a.*, b.RTIME, B.MONTH 
	FROM temp_HCC as a left join month as b on a.yearmo=b.yearmo;
	RUN;

/* proc stdize data=cube4 */
/* 	out=cube5 */
/* 	reponly missing=0; */
/* run; */

/* Check  */
proc sql;
select Distinct RTIME, MONTH, yearmo FROM bel_hcc;
RUN;

proc sql;
select sum(hcp_grail_nrx), sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcp) from temp_hcc;
Run;


/* CREATING CONTROL VARIABLES */
proc sort data= bel_hcc;
	by dmaname yearmo;
run;

DATA HCC_belsomra_final;
	SET bel_hcc;
	
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


DATA HCC.BELSOMRA_PRO_HCC_Feb20_JAN23;
SET HCC_BELSOMRA_FINAL;
RUN;

/* QC Check  */
proc sql;
select yearmo, sum(hcp_npp_eng), sum(hcp_dox_eng) from HCC.BELSOMRA_PRO_HCC_Feb20_JAN23 group by 1 order by 1;
Run;

proc sql;
select Distinct yearmo, RTime, month, T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,
T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36 
from HCC.BELSOMRA_PRO_HCC_Feb20_JAN23;
run;

proc sql;
select sum(hcp_grail_nrx), sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcp), sum(pp_any) from HCC.BELSOMRA_PRO_HCC_Feb20_JAN23;
/* 493963.4	631489	24557	65930	1029300 */

select sum(hcp_grail_nrx), sum(hcp_npp_eng), sum(hcp_dox_eng), sum(pp_hcp), sum(pp_any) from HCC.BELSOMRA_PRO_HCC_Feb20_JAN23 where dmaname = "ZZUNASSIGNED";
/* 43.059	84	3	38	902 */
Run;

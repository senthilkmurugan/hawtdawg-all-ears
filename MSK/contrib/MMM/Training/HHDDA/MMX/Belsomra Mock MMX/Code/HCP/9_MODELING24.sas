LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;

PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;


%MACRO ols_regression(cnt, master ,DEP_VAR, IND_VAR);
	*INDEPENDENT VARIABLE;
	*ODS LISTING CLOSE;

	DATA INTERMEDIATE;
		SET &master. (KEEP=&DEP_VAR. &IND_VAR. RTIME);
	RUN;

	ODS OUTPUT PARAMETERESTIMATES=PEST;

	PROC REG DATA=INTERMEDIATE;
		MODEL &DEP_VAR. = &IND_VAR./vif;
		RUN;
		*ODS LISTING;

		/* PROC PRINT DATA=PEST; RUN; */
	DATA TEMP&cnt.;
		SET PEST;
		length key 6.;
		key=&cnt.;
	RUN;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		var _numeric_;
		output out=col_sums sum=;
	run;

	data col_sums;
		set col_sums;
		Rename _Freq_=Intercept;
	run;

	proc transpose data=col_sums out=col_sums_t;
	run;

	data sums_w_sales_temp (drop=_name_);
		length variable $25;
		set col_sums_t;

		/* 	total_sales = 493963.4; FY'22 = 253603.1 ; */
		Variable=_name_;
		rename col1=Activity;
	run;

	proc sql;
		create table sums_w_sales as select *, (select sum(Activity) from 
			sums_w_sales_temp where variable="hcp_grail_nrx") as total_sales from 
			sums_w_sales_temp;
	quit;

	proc sort data=sums_w_sales;
		by variable;
	run;

	data results (drop=Model Dependent key);
		set temp&cnt.;
	run;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		where RTIME<=13 and RTIME>1;
		var _numeric_;
		output out=col_sums_annual sum=;
	run;

	data col_sums_annual;
		set col_sums_annual;
		Rename _Freq_=Intercept;
	run;

	proc transpose data=col_sums_annual out=col_sums_annual_t;
	run;

	data sums_w_sales_annual_temp (drop=_name_);
		length variable $25;
		set col_sums_annual_t;

		/* 	total_sales = 493963.4; FY'22 = 253603.1 ; */
		Variable=_name_;
		rename col1=Annual_Activity;
	run;

	proc sql;
		create table sums_w_sales_annual as select *, (select sum(Annual_Activity) 
			from sums_w_sales_annual_temp where variable="hcp_grail_nrx") as Annual_total_sales 
			from sums_w_sales_annual_temp;
	quit;

	proc sort data=sums_w_sales_annual;
		by variable;
	run;

	proc sort data=results;
		by variable;
	run;

	proc sort data=sums_w_sales;
		by variable;
	run;

	proc sort data=sums_w_sales_annual;
		by variable;
	run;

	proc sql;
		create table result_w_colsum as select * from results as a left join 
			sums_w_sales as b on a.variable=b.variable left join sums_w_sales_annual as 
			c on a.variable=c.variable;
	quit;

	data p_impactable;
		set result_w_colsum;
		percentage=((estimate*Activity)/total_sales);
		Annual_percentage=((estimate*Annual_Activity)/Annual_total_sales);
	run;

	PROC PRINT DATA=p_impactable;
	RUN;

%MEND;


/* Tranformed Data Models */
data model_dataset;
set   HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
where YEARMO>=202102 AND YEARMO <=202301;
Run;


/* Data Pull */
/* proc sql;  */
/* create table filtered_data as */
/* select * from model_dataset where party_id in (37338,37859,37862,37645); */
/* Run; */
/*  */
/* proc export data=filtered_data dbms=xlsx */
/* outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/filtered_data.xlsx" */
/* replace; */
/* sheet='data'; */
/* run; */


/* Check */
/* proc means data=model_dataset sum nway;  */
/* run; */

proc sql;
select sum(hcp_grail_nrx), sum(pp_hcc_agg), sum(pp_hcp_agg), sum(pp_any) from model_dataset 
where yearmo >=202201 and yearmo<=202212;
/* FY'22 = 253603.1	, PP_HCC:459630,  PP_HCP: 31572 */
/* 253603.1	388601	31572	400172 */
/* 253603.1	388601	31572	400172 */
run;

proc sql;
select sum(hcp_sfmc_eng_post70_RT4), sum(hcp_sfmc_eng_pre70_RT4) from model_dataset 
where yearmo >=202201 and yearmo<=202212;
/* 384654.3	70698.87 */
run;

proc sql;
select sum(hcp_sfmc_eng_post70_RT4), sum(hcp_sfmc_eng_pre70_RT4) from model_dataset;
/* 446503.2	242143.3 */
/* 446503.2	242143.3 */
run;

proc sql;
select sum(hcp_sfmc_eng_pre70_RT4) from model_dataset where yearmo >=202201;
/* 446503.2	242143.3 */
run;

proc sql;
select Distinct yearmo, RTime, month, T1,T2,T3,T4,T5,T6,T7,T8,T9,T10,T11,T12,T13,T14,
T15,T16,T17,T18,T19,T20,T21,T22,T23,T24,T25,T26,T27,T28,T29,T30,T31,T32,T33,T34,T35,T36 
from model_dataset;
run;


/* Correlation Check */

/* data Correl1; */
/* set   HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23; */
/* keep hcp_grail_nrx */
/* hcp_grail_nrx_lag */
/* RTIME */
/* M1-M12 */
/* hcp_rdtl_totdet */
/* hcp_grail_sdot */
/* hcp_grail_vnrx */
/* hcp_dpint_eng */
/* hcp_dox_eng */
/* hcp_edh_eng */
/* hcp_epoc_eng */
/* hcp_field_eng */
/* hcp_mscap_eng */
/* hcp_mng_eng */
/* hcp_sfmc_eng */
/* PP_HCP */
/* cw_comm */
/* webmd; */
/* where YEARMO>=202102 AND YEARMO <=202301;  */
/* run; */
/*  */
/* PROC CORR DATA= Correl1 out=corr_matrix; */
/* run; */



/* Model 1 */
/* Linear Model */

%ols_regression(201, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet
hcp_grail_sdot
hcp_grail_vnrx
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 1';
run;


/* Model 2 */
/* Linear Model (with out sessionality var) */

%ols_regression(202, model_dataset, hcp_grail_nrx,
hcp_grail_nrx_lag
hcp_rdtl_totdet
hcp_grail_sdot
hcp_grail_vnrx
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
PP_HCP
cw_comm
webmd
);

proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 2';
run;


/* Model 3 */
/* Linear Model with Month Flag*/

%ols_regression(203, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet
hcp_grail_sdot
hcp_grail_vnrx
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
M1-M11
);

proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 3';
run;


/* Model 4 */
/* Optimizing control variables */

%ols_regression(204, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
hcp_grail_nrx_lag
PP_HCP
cw_comm
webmd
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 4';
run;


/* Model 5 */
/* Optimizing field */

%ols_regression(205, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng70
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 5';
run;


/* Model 6 */
/* Dpint p-value significant */

%ols_regression(206, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng70
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);



proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 6';
run;


/* Model 7 */
/* Final model*/

%ols_regression(207, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 7';
run;


/* Model 14 */
/* Final model*/

%ols_regression(214, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP
pp_hcc
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 14';
run;


/* Model 12 */
/* Final model with M1-M12*/

%ols_regression(212, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
M1-M11
);


proc export data=p_impactable dbms=xlsx outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
		replace;
	sheet='Model 12';
run;



/* Model 8 (SFMC and Field Email Pre and Post) */

%ols_regression(208, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre60
hcp_field_eng_post60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre70_rt4
hcp_sfmc_eng_post70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 8';
run;


/* Model 15 (SFMC and Field Email Pre and Post with PP_HCC) */

%ols_regression(215, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre60
hcp_field_eng_post60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre70_rt4
hcp_sfmc_eng_post70_rt4
PP_HCP
PP_HCC
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 15';
run;


/* Model 16 (SFMC and Field Email Pre and Post with PP_ANY) */

%ols_regression(216, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre60
hcp_field_eng_post60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre70_rt4
hcp_sfmc_eng_post70_rt4
PP_ANY
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 16';
run;

/* Model 17 (SFMC and Field Email Pre and Post with deepintent del) */

%ols_regression(217, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_del
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre60
hcp_field_eng_post60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre70_rt4
hcp_sfmc_eng_post70_rt4
PP_HCP
PP_HCC
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 17';
run;


/* Model 18 (SFMC and Field Email Pre and Post without adstk or trf) */

%ols_regression(218, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_del
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre
hcp_field_eng_post
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre
hcp_sfmc_eng_post
PP_HCP
PP_HCC
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 18';
run;


/* Model 19 (SFMC and Field Email Pre and Post without adstk or trf) */

%ols_regression(219, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre
hcp_field_eng_post
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre
hcp_sfmc_eng_post
PP_HCP
PP_HCC
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 19';
run;



/* Model 9 (POC Agg) */

%ols_regression(209, model_dataset, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP_agg
cw_comm_agg
webmd_agg
hcp_grail_nrx_lag
RTIME
T1-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 9';
run;


/* Tranformed Data Models */
data model_dataset3;
set  HCP.FT_bel_hcp_mdb_Feb21_Jan23_DM;
where YEARMO>=202102 AND YEARMO <=202301;
run;

proc sql;
select sum(hcp_grail_nrx) from model_dataset3;
/* 9.41E-13 */
select sum(hcp_grail_nrx) from model_dataset3 where yearmo>= 202201 and yearmo <= 202212;
/* 6621.374 */
run;

/* Model 13 */
/* Final model with demean data*/

%ols_regression(213, model_dataset3, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 13';
run;


/* OSL Model for 20 Months Run  */

%MACRO ols_regression2(cnt, master ,DEP_VAR, IND_VAR);
	*INDEPENDENT VARIABLE;
	*ODS LISTING CLOSE;

	DATA INTERMEDIATE;
		SET &master. (KEEP=&DEP_VAR. &IND_VAR. RTIME);
	RUN;

	ODS OUTPUT PARAMETERESTIMATES=PEST;

	PROC REG DATA=INTERMEDIATE;
		MODEL &DEP_VAR. = &IND_VAR./vif;
		RUN;
		*ODS LISTING;

		/* PROC PRINT DATA=PEST; RUN; */
	DATA TEMP&cnt.;
		SET PEST;
		length key 6.;
		key=&cnt.;
	RUN;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		var _numeric_;
		output out=col_sums sum=;
	run;

	data col_sums;
		set col_sums;
		Rename _Freq_=Intercept;
	run;

	proc transpose data=col_sums out=col_sums_t;
	run;

	data sums_w_sales_temp (drop=_name_);
		length variable $25;
		set col_sums_t;

		/* 	total_sales = 493963.4; FY'22 = 253603.1 ; */
		Variable=_name_;
		rename col1=Activity;
	run;

	proc sql;
		create table sums_w_sales as select *, (select sum(Activity) from 
			sums_w_sales_temp where variable="hcp_grail_nrx") as total_sales from 
			sums_w_sales_temp;
	quit;

	proc sort data=sums_w_sales;
		by variable;
	run;

	data results (drop=Model Dependent key);
		set temp&cnt.;
	run;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		where RTIME<=13 and RTIME>4;
		var _numeric_;
		output out=col_sums_annual sum=;
	run;

	data col_sums_annual;
		set col_sums_annual;
		Rename _Freq_=Intercept;
	run;

	proc transpose data=col_sums_annual out=col_sums_annual_t;
	run;

	data sums_w_sales_annual_temp (drop=_name_);
		length variable $25;
		set col_sums_annual_t;

		/* 	total_sales = 493963.4; FY'22 = 253603.1 ; */
		Variable=_name_;
		rename col1=Annual_Activity;
	run;

	proc sql;
		create table sums_w_sales_annual as select *, (select sum(Annual_Activity) 
			from sums_w_sales_annual_temp where variable="hcp_grail_nrx") as Annual_total_sales 
			from sums_w_sales_annual_temp;
	quit;

	proc sort data=sums_w_sales_annual;
		by variable;
	run;

	proc sort data=results;
		by variable;
	run;

	proc sort data=sums_w_sales;
		by variable;
	run;

	proc sort data=sums_w_sales_annual;
		by variable;
	run;

	proc sql;
		create table result_w_colsum as select * from results as a left join 
			sums_w_sales as b on a.variable=b.variable left join sums_w_sales_annual as 
			c on a.variable=c.variable;
	quit;

	data p_impactable;
		set result_w_colsum;
		percentage=((estimate*Activity)/total_sales);
		Annual_percentage=((estimate*Annual_Activity)/Annual_total_sales);
	run;

	PROC PRINT DATA=p_impactable;
	RUN;

%MEND;


/* Tranformed Data Models */
data model_dataset2;
set   HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
where YEARMO>=202102 AND YEARMO <=202209;
run;

proc sql;
select sum(hcp_sfmc_eng70_rt4) from model_dataset2 
where YEARMO>=202110 AND YEARMO <=202209;
/* 186184.5 */
run;


/* Model 10 (20 Month Model SFMC & Field Email Pre and Post) */

%ols_regression2(210, model_dataset2, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng_pre60
hcp_field_eng_post60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng_pre70_rt4
hcp_sfmc_eng_post70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T5-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 10';
run;


/* Model 11 (20 mon model) */

%ols_regression2(211, model_dataset2, hcp_grail_nrx,
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_dpint_eng30_rt4
hcp_dox_eng70_rt8
hcp_edh_eng
hcp_epoc_eng90_rt4
hcp_field_eng60
hcp_mscap_eng40_rt4
hcp_mng_eng
hcp_sfmc_eng70_rt4
PP_HCP
cw_comm
webmd
hcp_grail_nrx_lag
RTIME
T5-T23
);


proc export data=p_impactable dbms=xlsx 
outfile="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP/out_data/BELSOMRA_HCP_MCM_MODEL_RESULTS_24.XLSX" 
replace;
sheet='Model 11';
run;

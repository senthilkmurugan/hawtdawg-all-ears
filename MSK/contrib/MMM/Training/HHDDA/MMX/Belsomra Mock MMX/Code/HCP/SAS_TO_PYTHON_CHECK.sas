LIBNAME HCP "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCP";
OPTIONS COMPRESS=YES NOLABEL NOCENTER ERROR=1 MACROGEN SYMBOLGEN ;

PROC DATASETS LIBRARY = WORK NOLIST KILL;
RUN;QUIT;

data model_dataset;
set   HCP.FT_BEL_PRO_HCP_MDB_FEB20_FEB23;
where YEARMO>=202102 AND YEARMO <=202301;
run;

data sas_data;
set model_dataset;
keep hcp_grail_nrx
hcp_grail_nrx_lag
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
hcp_grail_nrx_lag_1
PP_HCP
cw_comm
webmd
RTIME
T1-T23;
where YEARMO>=202102 AND YEARMO <=202301; 
run;

data sas_data2;
set model_dataset;
keep party_id
yearmo
hcp_rdtl_totdet40
hcp_grail_sdot60
hcp_grail_vnrx40
hcp_grail_nrx_lag_1
hcp_rdtl_totdet
PP_HCP
cw_comm
webmd
RTIME
T1-T23;
where YEARMO>=202102 AND YEARMO <=202301; 
run;


/* Tranformed Data Models */
PROC IMPORT OUT=DATASET DATAFILE="/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/BelsomraCopy/input/project_data/modeldata1/part-00000-7561c384-2218-4224-89a3-bdf8655c8031-c000.csv" 
DBMS=csv REPLACE;
RUN;

DATA model_dataset2;
set DATASET;
where YEARMO>=202102 AND YEARMO <=202301;
Run;

data python_data;
set model_dataset2;
keep hcp_grail_nrx
hcp_rdtl_totdet_adstk_40
hcp_grail_sdot_adstk_60
hcp_grail_vnrx_adstk_40
hcp_dpint_eng
hcp_dox_eng
hcp_edh_eng
hcp_epoc_eng
hcp_field_eng
hcp_mscap_eng
hcp_mng_eng
hcp_sfmc_eng
hcp_grail_nrx_lag_1
PP_HCP
cw_comm
webmd
RTIME
T1-T23;
where YEARMO>=202102 AND YEARMO <=202301; 
run;


data python_data2;
set model_dataset2;
keep party_id
yearmo
hcp_rdtl_totdet_adstk_40
hcp_grail_sdot_adstk_60
hcp_grail_vnrx_adstk_40
hcp_grail_nrx_lag_1
PP_HCP
cw_comm
webmd
RTIME
T1-T23;
where YEARMO>=202102 AND YEARMO <=202301; 
run;

PROC MEANS DATA = sas_data;  
RUN; 
PROC MEANS DATA = python_data;  
RUN; 

PROC UNIVARIATE DATA = sas_data; 
VAR hcp_rdtl_totdet40; 
RUN;

PROC UNIVARIATE DATA = python_data; 
VAR hcp_rdtl_totdet_adstk_40; 
RUN;

proc sql;
create table combdata as select * from sas_data2 as a left join python_data2 as b on (a.party_id=b.party_id and a.yearmo=b.yearmo);
run;

proc means data=combdata NMISS N; 
run;

proc sql;
select party_id, yearmo, hcp_grail_vnrx_adstk_40, hcp_grail_vnrx40, hcp_rdtl_totdet, hcp_rdtl_totdet_adstk_40,hcp_rdtl_totdet40 from combdata where party_id in (37862) ;
run;




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





%ols_regression(201, model_dataset2, hcp_grail_nrx,
CW_COMM
hcp_dox_eng_adstk_70_power_8
hcp_dpint_eng_adstk_30_power_4
hcp_edh_eng
hcp_epoc_eng_adstk_90_power_4
hcp_field_eng_adstk_60
hcp_grail_nrx_lag_1
hcp_grail_sdot_adstk_60
hcp_grail_vnrx_adstk_40
hcp_mng_eng
hcp_mscap_eng_adstk_40_power_4
hcp_rdtl_totdet_adstk_40
hcp_sfmc_eng_adstk_70_power_4
PP_HCP
WEBMD
RTIME
T1-T23
);


%ols_regression(202, model_dataset, hcp_grail_nrx,
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
);


%ols_regression(201, model_dataset2, hcp_grail_nrx,
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
hcp_grail_nrx_lag_1
PP_HCP
cw_comm
webmd
);


%ols_regression(202, model_dataset, hcp_grail_nrx,
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
hcp_grail_nrx_lag
PP_HCP
cw_comm
webmd
);




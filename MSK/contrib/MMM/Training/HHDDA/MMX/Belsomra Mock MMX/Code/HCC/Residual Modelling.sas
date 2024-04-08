LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";

/* BELSOMRA HCC MODELLLING 2022 */
PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

/* 22 Months Data */
DATA MASTER_DATA;
	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	where yearmo>=202104 and yearmo <=202301 and DMANAME  <> 'ZZUNASSIGNED';
RUN;

/* 12 Months Data  */
DATA MASTER_DATA2;
	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	where yearmo>=202201 and yearmo <=202212 and DMANAME  <> 'ZZUNASSIGNED';
RUN;


%MACRO ols_regression(cnt, master, DEP_VAR, IND_VAR);
	*INDEPENDENT VARIABLE;
	*ODS LISTING CLOSE;

	DATA INTERMEDIATE;
		SET &master. (KEEP=&DEP_VAR. &IND_VAR. RTIME);
	RUN;

	/*ODS GRAPHICS ON;*/
	ODS OUTPUT PARAMETERESTIMATES=PEST;

	PROC REG DATA=INTERMEDIATE;
		/* 	PLOTS(MAXPOINTS=NONE ONLY)= (COOKSD(LABEL) DFBETAS(LABEL UNPACK)) OUTEST=OUT_MOD OUTSEB OUTVIF RIDGE = 0 to 0.5 by 0.01; */
		MODEL &DEP_VAR.=&IND_VAR./vif;

		/* 	ID ZIPYEARMO; */
		/* 	plot / ridgeplot nomodel nostat; */
		/* 	ods output OutputStatistics=OUTSTATS; */
		RUN;

		/* 	ODS GRAPHICS OFF; */
		/* PROC PRINT DATA=PEST; RUN; */
		ODS OUTPUT PARAMETERESTIMATES=PEST;

	PROC REG DATA=INTERMEDIATE;
		MODEL &DEP_VAR.=&IND_VAR./vif;
		RUN;

	DATA TEMP&cnt.;
		SET PEST;
		length key 6.;
		key=&cnt.;
	RUN;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		where RTIME <=24;
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

		/* TOTAL_NRX_24 = 23889414; * 1242806 1063272; */
		Variable=_name_;
		rename col1=Activity_24;
	run;

	proc sql;
		create table sums_w_sales as select *, (select sum(Activity_24) from 
			sums_w_sales_temp where variable="hcp_grail_nrx") as TOTAL_NRX_24 from 
			sums_w_sales_temp;
	quit;

	proc sort data=sums_w_sales;
		by variable;
	run;

	data results (drop=Model Dependent key);
		set temp&cnt.;
	run;

	proc means data=INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		where RTIME <=13 and RTIME >1 ;
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

		/* TOTAL_NRX_24 = 23889414; * 1242806 1063272; */
		Variable=_name_;
		rename col1=Annual_Activity_12;
	run;

	proc sql;
		create table sums_w_sales_annual as select *, (select sum(Annual_Activity_12) 
			from sums_w_sales_annual_temp where variable="hcp_grail_nrx") as 
			ANNUAL_NRX_12 from sums_w_sales_annual_temp;
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
		PERCENTAGE_24=((estimate*Activity_24)/TOTAL_NRX_24);
		PERCENTAGE_12=((estimate*Annual_Activity_12)/ANNUAL_NRX_12);
	run;

	PROC PRINT DATA=p_impactable;
	RUN;

%MEND;

%MACRO deols_regression(cnt, master, DEP_VAR, IND_VAR);
	*INDEPENDENT VARIABLE;
	*ODS LISTING CLOSE;

	DATA INTERMEDIATE;
		SET &master. (KEEP=&DEP_VAR. &IND_VAR. RTIME );
	RUN;

	/*ODS GRAPHICS ON;*/
	ODS OUTPUT PARAMETERESTIMATES=PEST;
	PROC REG DATA=INTERMEDIATE;
/* 	PLOTS(MAXPOINTS=NONE ONLY)= (COOKSD(LABEL) DFBETAS(LABEL UNPACK)) OUTEST=OUT_MOD OUTSEB OUTVIF RIDGE = 0 to 0.5 by 0.01; */
	MODEL &DEP_VAR.=&IND_VAR./vif;
/* 	ID ZIPYEARMO; */
/* 	plot / ridgeplot nomodel nostat; */
/* 	ods output OutputStatistics=OUTSTATS; */
	RUN;
/* 	ODS GRAPHICS OFF; */
	/* PROC PRINT DATA=PEST; RUN; */
	
	ODS OUTPUT PARAMETERESTIMATES=PEST;

	PROC REG DATA=INTERMEDIATE;
		MODEL &DEP_VAR.=&IND_VAR./vif;
		RUN;

	DATA TEMP&cnt.;
		SET PEST;
		length key 6.;
		key=&cnt.;
	RUN;

	proc means data=  WORK.MASTER_DATA sum nway nonobs maxdec=2 noprint;
		where RTIME <=24;
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

		/* TOTAL_NRX_24 = 23889414; * 1242806 1063272; */
		Variable=_name_;
		rename col1=Activity_24;
	run;

	proc sql;
		create table sums_w_sales as select *, (select sum(Activity_24) from 
			sums_w_sales_temp where variable="hcp_grail_nrx") as TOTAL_NRX_24 from 
			sums_w_sales_temp;
	quit;

	proc sort data=sums_w_sales;
		by variable;
	run;

	data results (drop=Model Dependent key);
		set temp&cnt.;
	run;

	proc means data= WORK.MASTER_DATA sum nway nonobs maxdec=2 noprint;
		where RTIME <=13 and RTIME > 1;
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

		/* TOTAL_NRX_24 = 23889414; * 1242806 1063272; */
		Variable=_name_;
		rename col1=Annual_Activity_12;
	run;

	proc sql;
		create table sums_w_sales_annual as select *, (select sum(Annual_Activity_12) 
			from sums_w_sales_annual_temp where variable="hcp_grail_nrx") as 
			ANNUAL_NRX_12 from sums_w_sales_annual_temp;
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
		PERCENTAGE_24=((estimate*Activity_24)/TOTAL_NRX_24);
		PERCENTAGE_12=((estimate*Annual_Activity_12)/ANNUAL_NRX_12);
	run;

	PROC PRINT DATA=p_impactable;
	RUN;

%MEND;





/* ******************************************************************* */
/* *************************RESIDUAL MODELLING ***************************/
/* ******************************************************************* */
/* Tips : If spend is decreasing, slopes should be less than the last time */

/*  */
/* %OLS_REGRESSION(111, MASTER_DATA, hcp_grail_nrx, */
/* hcc_disp_imp  */
/* hcc_osrch_sessions20 */
/* hcc_psrch_clk */
/* hcc_soc_imp */
/* hcp_disp_imp */
/* hcp_osrch_sessions20 */
/* hcp_grail_sdot20 */
/* hcp_grail_vnrx20 */
/* hcp_rdtl_totdet20 */
/* hcp_grail_nrx_lag */
/* hcp_npp_eng_RT4 */
/* PP_HCP */
/* PP_HCC */
/* PP_Any20 */
/* webmd */
/* cw_comm */
/* RTIME */
/* T1-T21 */
/* ); */



%OLS_REGRESSION(111, MASTER_DATA, hcp_grail_nrx,
/* hcc_disp_imp  */
/* hcc_osrch_sessions */
hcc_psrch_clk60
/* hcc_soc_imp */
/* hcp_disp_imp */
/* hcp_osrch_sessions */
/* hcp_grail_sdot20 */
hcp_grail_vnrx20
hcp_rdtl_totdet60
hcp_grail_nrx_lag
/* hcp_npp_eng50_RT4 */
/* PP_HCP */
/* PP_HCC */
/* PP_Any20 */
/* webmd */
/* cw_comm */
/* RTIME */
/* T1-T21 */
);
proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 12';
run;

/* Substraacting hcc_psrch_clk50 from The Data */
data step2;
	set master_data;
	hcp_grail_nrx=hcp_grail_nrx - 0.01131	*hcc_psrch_clk60;
run;



%OLS_REGRESSION(111, step2, hcp_grail_nrx,
/* hcc_disp_imp20  */
hcc_osrch_sessions20
/* hcc_psrch_clk */
hcc_soc_imp
/* hcp_disp_imp20 */
hcp_osrch_sessions20
hcp_grail_sdot20
hcp_grail_vnrx40
hcp_rdtl_totdet40
hcp_grail_nrx_lag
hcp_npp_eng40_RT4
/* PP_HCP */
/* PP_HCC */
PP_Any20
/* webmd */
cw_comm
RTIME
T1-T21
);

%OLS_REGRESSION(111, step2, hcp_grail_nrx,
/* hcc_disp_imp20  */
						hcc_osrch_sessions
						/* hcc_psrch_clk */
						hcc_soc_imp20
/* 						hcp_disp_imp20 */
						hcp_osrch_sessions
/* 						hcp_grail_sdot20 */
						hcp_grail_vnrx10
						hcp_rdtl_totdet20
						hcp_grail_nrx_lag
						hcp_npp_eng10
						PP_HCP
						PP_HCC
						/* webmd */
						cw_comm
						RTIME
						T1-T21
);

/* proc reg data=step2 outvif outseb plots(only)=ridge(unpack VIFaxis=log)  */
/* 		outest=out_est_2 ridge=0 to 0.4 by 0.01; */
/* 	model hcp_grail_nrx= */
/* 						hcc_disp_imp20  */
/* 						hcc_osrch_sessions */
/* 						hcc_psrch_clk */
/* 						hcc_soc_imp20 */
/* 						hcp_disp_imp20 */
/* 						hcp_osrch_sessions */
/* 						hcp_grail_sdot20 */
/* 						hcp_grail_vnrx10 */
/* 						hcp_rdtl_totdet20 */
/* 						hcp_grail_nrx_lag */
/* 						hcp_npp_eng40_RT3 */
/* 						PP_HCP */
/* 						PP_HCC */
/* 						webmd */
/* 						cw_comm */
/* 						RTIME */
/* 						T1-T21 */
/* /VIF; */
/* 	plot / ridgeplot nomodel nostat; */
/* 	run; */
/* quit; */


proc reg data=step2 outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
		outest=out_est_2 ridge=0 to 0.4 by 0.01;
	model hcp_grail_nrx=
						/* hcc_disp_imp20  */
						hcc_osrch_sessions
						/* hcc_psrch_clk */
						hcc_soc_imp20
/* 						hcp_disp_imp */
						hcp_osrch_sessions
/* 						hcp_grail_sdot20 */
						hcp_grail_vnrx10
						hcp_rdtl_totdet20
						hcp_grail_nrx_lag
						hcp_npp_eng
						PP_HCP
						PP_HCC
						/* webmd */
						cw_comm
						RTIME
						T1-T21
/VIF;
	plot / ridgeplot nomodel nostat;
	run;
quit;

proc print data=out_est_2;
run;

proc sql;
select sum(hcc_soc_imp20), sum(hcp_grail_nrx) from step2 where yearmo>=202201 and yearmo <=202212;
run;

proc export data=out_est_2 dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Ridge Models 6';
run;



/* Model 13: 12 Month Model */
%OLS_REGRESSION(101, MASTER_DATA2, hcp_grail_nrx,
hcp_grail_nrx_lag
hcc_disp_imp  
hcc_osrch_sessions 
hcc_psrch_clk
hcc_soc_imp
hcp_disp_imp
hcp_osrch_sessions  
hcp_grail_sdot 
hcp_grail_vnrx
hcp_rdtl_totdet
hcp_npp_eng
PP_HCP
PP_HCC
webmd
cw_comm
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 13';
run;

/* Model 14: 12 months with adstk and trf */
%OLS_REGRESSION(114, MASTER_DATA2, hcp_grail_nrx,
hcc_disp_imp 
hcc_osrch_sessions20
hcc_psrch_clk
hcc_soc_imp
hcp_disp_imp
hcp_osrch_sessions20
hcp_grail_sdot20
hcp_grail_vnrx20
hcp_rdtl_totdet20
hcp_grail_nrx_lag
hcp_npp_eng_RT4
PP_HCP
PP_HCC
/* PP_Any20 */
webmd
cw_comm
RTIME
T1-T21
);


proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 14';
run;
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
select sum(hcp_rdtl_totdet40_RT4) from master_data;
select sum(hcp_rdtl_totdet40_RT4) from master_data where yearmo >=202201 and yearmo <=202212;
run;

/* DATA pre_data; */
/* 	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23; */
/* 	where yearmo>=202104 and yearmo <=202301; */
/* RUN; */
/*  */
/* DATA MASTER_DATA2; */
/* 	SET  pre_data; */
/* 	where  DMANAME  <> 'ZZUNASSIGNED' and DMANAME <> 'NEW YORK' and DMANAME <> 'DALLAS-FT. WORTH'; */
/* RUN; */


%MACRO ols_regression(cnt, master, DEP_VAR, IND_VAR);
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

	proc means data= INTERMEDIATE sum nway nonobs maxdec=2 noprint;
		where RTIME<=24;
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



/* Linear Model */
%OLS_REGRESSION(101, MASTER_DATA, hcp_grail_nrx,
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
	sheet='Model 1';
run;


/* Model 2 : with M1-M11 */
%OLS_REGRESSION(102, MASTER_DATA, hcp_grail_nrx,
hcc_disp_imp  
hcc_osrch_sessions 
hcc_psrch_clk
hcc_soc_imp
hcp_disp_imp
hcp_osrch_sessions  
hcp_grail_sdot 
hcp_grail_vnrx
hcp_rdtl_totdet
hcp_grail_nrx_lag
hcp_npp_eng
PP_HCP
PP_HCC
webmd
cw_comm
RTIME
M1-M11
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 2';
run;


/*  Model 3: Without POC*/
%OLS_REGRESSION(103, MASTER_DATA, hcp_grail_nrx,
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
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 3';
run;


/* Model 4: Including Rtime and Rtime_sq in the model */
%OLS_REGRESSION(104, MASTER_DATA, hcp_grail_nrx,
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
RTIME_SQ
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 4';
run;


/* Model 5: Adstocking similar to previous time around */
%OLS_REGRESSION(105, MASTER_DATA, hcp_grail_nrx,
hcp_grail_nrx_lag
hcc_disp_imp  
hcc_osrch_sessions 
hcc_psrch_clk70
hcc_soc_imp70
hcp_disp_imp
hcp_osrch_sessions_RT6  
hcp_grail_sdot 
hcp_grail_vnrx
hcp_rdtl_totdet70
hcp_npp_eng
PP_ANY
webmd
cw_comm
RTIME
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 5';
run;



/* Ridge Reg 1: With previous years adstock and trf*/
proc reg data=Master_data outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
         outest=out_est_2 ridge=0 to 0.5 by 0.01; 
         model hcp_grail_nrx = hcp_grail_nrx_lag
         						hcc_disp_imp
								hcc_osrch_sessions 
								hcc_psrch_clk70
								hcc_soc_imp70
								hcp_disp_imp
								hcp_osrch_sessions_RT6  
								hcp_grail_sdot 
								hcp_grail_vnrx
								hcp_rdtl_totdet70
								hcp_npp_eng
								PP_ANY
								webmd
								cw_comm
								RTIME
								T1-T23
/VIF;
plot / ridgeplot nomodel nostat; 
run;
quit;

proc print data=out_est_2;
run;

proc export data=out_est_2 dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Ridge Models 1';
run;

proc sql;
select sum(hcc_psrch_clk), sum(hcp_grail_nrx) from master_data where yearmo>=202201 and yearmo<=202212;
run;


/* OLS Model to check for Ridge */
%OLS_REGRESSION(101, MASTER_DATA, hcp_grail_nrx,
hcc_disp_imp 
hcc_osrch_sessions20
hcc_psrch_clk
hcc_soc_imp60_RT6
hcp_disp_imp40
hcp_osrch_sessions60_RT4
hcp_grail_sdot
hcp_grail_vnrx30
hcp_rdtl_totdet60
hcp_grail_nrx_lag
hcp_npp_eng60_RT6
PP_HCP
PP_HCC
webmd
cw_comm
RTIME
T1-T23
);

/* Ridge Reg 2: with adstk and trf activity */
proc reg data=Master_data outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
         outest=out_est_2 ridge=0 to 0.5 by 0.01; 
         model hcp_grail_nrx = hcp_grail_nrx_lag
         						hcc_disp_imp 
								hcc_osrch_sessions20
								hcc_psrch_clk
								hcc_soc_imp60_RT6
								hcp_disp_imp40
								hcp_osrch_sessions60_RT4
								hcp_grail_sdot
								hcp_grail_vnrx30
								hcp_rdtl_totdet60
								hcp_npp_eng60_RT6
								PP_HCP
								PP_HCC
								webmd
								cw_comm
								RTIME
								T1-T23
/VIF;
plot / ridgeplot nomodel nostat; 
run;
quit;

proc print data=out_est_2;
run;

proc export data=out_est_2 dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Ridge Models 2';
run;


/* OLS Model to check for Ridge */
%OLS_REGRESSION(101, MASTER_DATA, hcp_grail_nrx,
hcc_disp_imp 
hcc_osrch_sessions20
hcc_psrch_clk
hcc_soc_imp60_RT6
hcp_disp_imp40
hcp_osrch_sessions60_RT4
hcp_grail_sdot
hcp_grail_vnrx30
hcp_rdtl_totdet60
hcp_grail_nrx_lag
hcp_npp_eng60_RT6
PP_HCP
PP_HCC
webmd
cw_comm
RTIME
RTIME_SQ
T1-T23
);

/* Ridge Reg 3: with adstk and trf activity adding RTime_Sq */
proc reg data=Master_data outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
         outest=out_est_2 ridge=0 to 0.5 by 0.01; 
         model hcp_grail_nrx = hcp_grail_nrx_lag
         						hcc_disp_imp 
								hcc_osrch_sessions20
								hcc_psrch_clk
								hcc_soc_imp60_RT6
								hcp_disp_imp40
								hcp_osrch_sessions60_RT4
								hcp_grail_sdot
								hcp_grail_vnrx30
								hcp_rdtl_totdet60
								hcp_npp_eng60_RT6
								PP_HCP
								PP_HCC
								webmd
								cw_comm
								RTIME
								RTIME_SQ
								T1-T23
/VIF;
plot / ridgeplot nomodel nostat; 
run;
quit;

proc print data=out_est_2;
run;

proc export data=out_est_2 dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Ridge Models 3';
run;

LIBNAME MODEL "/efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/HCC/MODEL_DATASET";

/* BELSOMRA HCC MODELLLING 2022 */
PROC DATASETS LIBRARY=WORK NOLIST KILL;
	RUN;
QUIT;

DATA MASTER_DATA;
	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	where rtime <= 24 and DMANAME  <> 'ZZUNASSIGNED';
RUN;


proc reg data=Master_data plots=NONE; 
   model hcp_grail_nrx=hcc_psrch_clk / influence;
   id DMANAME YEARMO;
   ods output OutputStatistics=OutputStats;      /* save influence statistics */
run; quit;

proc sql;
create table outlier_check as select DMANAME, yearmo, sum(hcc_psrch_clk) as hcc_psrch_clk, sum(hcp_grail_nrx) as hcp_grail_nrx from MASTER_DATA group by 1,2 order by 1,2;
run;


/* proc reg data=outlier_check; */
/*    model hcp_grail_nrx=hcc_psrch_clk / influence; */
/* run; */

ods output on;
proc mixed data=outlier_check  covtest noclprint; *(where=(outlier_dma_ind=0)); 
   class DMANAME yearmo;
   model hcp_grail_nrx=hcc_psrch_clk 
      / solution outpred=pred_2  influence(iter=5 /*effect=DMANAME*/ est);
/*    RANDOM intercept / subject=dma s; */
/*    REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr; */
   ods output influence=inf1 fitstatistics=fit1 solutionf=fixed1;
run;


proc reg data=outlier_check;
	id DMANAME;
   model hcp_grail_nrx=hcc_psrch_clk / influence;
   output out =temp;
   ods output fitstatistics=fit1 DFFITS=df1 DFBETAS=df2; 
run;



ods output on;
proc reg data=outlier_check;
	id DMANAME;
   model hcp_grail_nrx=hcc_psrch_clk / influence;
   output out =temp;
   ods output influence=inf1 fitstatistics=fit1 solutionf=fixed1;
run;

proc print data=temp;
run;

/* ods graphics on; */
/* proc reg data=outlier_check */
/*       plots(label)=(CooksD RStudentByLeverage DFFITS DFBETAS); */
/*    id hcp_grail_nrx; */
/*    model hcc_psrch_clk=hcp_grail_nrx; */
/* run; */
/* ods graphics on; */

proc reg data=outlier_check
      plots(label)=(CooksD RStudentByLeverage DFFITS DFBETAS);
   id hcp_grail_nrx;
   model hcp_grail_nrx=hcc_psrch_clk;
run;

proc reg data=outlier_check
      plots(label)=(CooksD RStudentByLeverage DFFITS DFBETAS);
   id hcp_grail_nrx;
   model hcp_grail_nrx=hcc_psrch_clk;
run;


DATA pre_data;
	SET  MODEL.ADS_FN_BELSOMRA_MDB_Feb21_JAN23;
	where yearmo>=202104 and yearmo <=202301;
RUN;

DATA MASTER_DATA2;
	SET  pre_data;
	where  DMANAME  <> 'ZZUNASSIGNED' and DMANAME <> 'NEW YORK' and DMANAME <> 'DALLAS-FT. WORTH';
RUN;


DATA DEMEANED_DATA;
	SET MODEL.DM_BELSOMRA_MDB_FEB21_JAN23;
	where  rtime <= 24 and DMANAME  <> 'ZZUNASSIGNED';
RUN;


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


/* Model 6: Demean Model */
%OLS_REGRESSION(121, DEMEANED_DATA, hcp_grail_nrx,
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
T1-T23
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 6';
run;

/* Ridge Reg 4: Demean model */
proc reg data=DEMEANED_DATA outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
         outest=out_est_2 ridge=0 to 0.5 by 0.01; 
         model hcp_grail_nrx = hcp_grail_nrx_lag
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
/VIF;
plot / ridgeplot nomodel nostat; 
run;
quit;

proc print data=out_est_2;
run;

proc export data=out_est_2 dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Ridge Models 4';
run;


/* Ridge Reg 5: Demean model with adstock and trf */
proc reg data=DEMEANED_DATA outvif outseb plots(only)=ridge(unpack VIFaxis=log) 
         outest=out_est_2 ridge=0 to 0.5 by 0.01; 
         model hcp_grail_nrx = hcp_grail_nrx_lag
         						hcc_disp_imp  
								hcc_osrch_sessions20 
								hcc_psrch_clk20_RT2
								hcc_soc_imp20
								hcp_disp_imp40
								hcp_osrch_sessions20  
								hcp_grail_sdot 
								hcp_grail_vnrx20
								hcp_rdtl_totdet40_RT4
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
	sheet='Ridge Models 5';
run;



/*  Model 7: 22 months*/
%OLS_REGRESSION(107, pre_data, hcp_grail_nrx,
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
T1-T21
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 7';
run;


/*  Model 8: 22 months with adstk and Trf*/
%OLS_REGRESSION(108, pre_data, hcp_grail_nrx,
/* hcc_disp_imp  */
/* hcc_osrch_sessions */
hcc_psrch_clk
hcc_soc_imp40_RT9
/* hcp_disp_imp */
hcp_osrch_sessions20
hcp_grail_sdot
hcp_grail_vnrx
hcp_rdtl_totdet
hcp_grail_nrx_lag
hcp_npp_eng20_RT2
PP_HCP
PP_HCC
webmd
cw_comm
RTIME
T1-T21
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 8';
run;



/*  Model 9: 22 months with adstk and Trf*/
%OLS_REGRESSION(109, master_data2, hcp_grail_nrx,
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
/* PP_HCP */
/* PP_HCC */
PP_Any
/* webmd */
cw_comm
RTIME_SQ
T1-T21
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 9';
run;


/*  Model 10: 22 months with adstk and Trf*/
%OLS_REGRESSION(109, master_data2, hcp_grail_nrx,
hcc_disp_imp 
hcc_osrch_sessions20
hcc_psrch_clk
hcc_soc_imp70_RT8
hcp_disp_imp40
hcp_osrch_sessions60
hcp_grail_sdot
hcp_grail_vnrx30
hcp_rdtl_totdet60
hcp_grail_nrx_lag
hcp_npp_eng80_RT6
/* PP_HCP */
/* PP_HCC */
PP_Any60
/* webmd */
cw_comm
RTIME_SQ
T1-T21
);

proc export data=p_impactable dbms=xlsx 
outfile="//efs-MAIO/Team/promo_opt/MktMixPP/2024 Planning/Belsomra/output/outfile/DMA_MODELS_2.XLSX" 
		replace;
	sheet='Model 10';
run;




/*  Model 11: 22 months with adstk and Trf*/
%OLS_REGRESSION(109, master_data2, hcp_grail_nrx,
hcc_disp_imp 
hcc_osrch_sessions20
hcc_psrch_clk
hcc_soc_imp70_RT8
hcp_disp_imp40
hcp_osrch_sessions60
hcp_grail_sdot
hcp_grail_vnrx30
hcp_rdtl_totdet60
hcp_grail_nrx_lag
hcp_npp_eng80_RT6
/* PP_HCP */
/* PP_HCC */
PP_Any60
/* webmd */
cw_comm
RTIME_SQ
T1-T21
);



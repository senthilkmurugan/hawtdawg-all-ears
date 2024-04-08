/* ********************************************************************************
1. Get Means and Correlations of Model Variables.
******************************************************************************** */
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Visualization;
OPTIONS NOCENTER MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

data mdl1;
  set rx.MODEL_DATA_v1;
run;
proc contents data=mdl1 varnum; run;

/*
MEANS
*/
* BY Month;
proc sort data=mdl1; by yearmo; run;
proc means data=mdl1 nway mean std sum noprint;
  by yearmo;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx 
      det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx 
      detmd sammd vcrmd mc_nrp 
      detmd_30 sammd_30 vcrmd_30 grpnas_30 grpomn_30 grpotc_30 grpadv_30
      detmd_60 sammd_60 vcrmd_60 grpnas_60 grpomn_60 grpotc_60 grpadv_60
      detmd_80 sammd_80 vcrmd_80 grpnas_80 grpomn_80 grpotc_80 grpadv_80 ;
  output out = mn_std_month_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_month_means(keep=yearmo nasnrx_mean -- grpadv_80_mean)
     mn_std_month_std(keep=yearmo nasnrx_stddev -- grpadv_80_stddev) 
     mn_std_month_sum(keep=yearmo nasnrx_sum -- grpadv_80_sum);
  set mn_std_month_1;
  output mn_std_month_means;
  output mn_std_month_std;
  output mn_std_month_sum;
run;

*OVERALL;
proc means data=mdl1 nway mean std sum noprint;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx 
      det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx 
      detmd sammd vcrmd mc_nrp 
      detmd_30 sammd_30 vcrmd_30 grpnas_30 grpomn_30 grpotc_30 grpadv_30
      detmd_60 sammd_60 vcrmd_60 grpnas_60 grpomn_60 grpotc_60 grpadv_60
      detmd_80 sammd_80 vcrmd_80 grpnas_80 grpomn_80 grpotc_80 grpadv_80 ;
  output out = mn_std_all_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_all_means(keep=nasnrx_mean -- grpadv_80_mean)
     mn_std_all_std(keep=nasnrx_stddev -- grpadv_80_stddev) 
     mn_std_all_sum(keep=nasnrx_sum -- grpadv_80_sum);
  set mn_std_all_1;
  output mn_std_all_means;
  output mn_std_all_std;
  output mn_std_all_sum;
run;

/*
CORRELATIONS
*/
proc corr data=mdl1 outp=corr_all_1;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx 
      det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx lag_pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx 
      detmd sammd vcrmd  
      detmd_30 sammd_30 vcrmd_30 grpnas_30 grpomn_30 grpotc_30 grpadv_30
      detmd_60 sammd_60 vcrmd_60 grpnas_60 grpomn_60 grpotc_60 grpadv_60
      detmd_80 sammd_80 vcrmd_80 grpnas_80 grpomn_80 grpotc_80 grpadv_80 ;
run;


/*
MEANS of model variables
*/
* OVERALL (210 DMA, 24 Months, 210*24=5040recs);
proc sort data=mdl1; by yearmo; run;
proc means data=mdl1 nway mean std sum noprint;
  *by yearmo;
  var pnasnrx lag_pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx 
      detmd sammd vcrmd mc_nrp onl_score onl_score_50
	  time_idx time_idx_sq time_idx_cu q1 q2 q3 q4 jan -- dec flut_short_ind gen_all_launch 
      detmd_10 detmd_20 detmd_30 detmd_40 detmd_50 detmd_60 detmd_70 detmd_75 detmd_80 detmd_85 detmd_90  
      sammd_10 sammd_20 sammd_30 sammd_40 sammd_50 sammd_60 sammd_70 sammd_75 sammd_80 sammd_85 sammd_90  
      vcrmd_10 vcrmd_20 vcrmd_30 vcrmd_40 vcrmd_50 vcrmd_60 vcrmd_70 vcrmd_75 vcrmd_80 vcrmd_85 vcrmd_90  
      grpnas_10 grpnas_20 grpnas_30 grpnas_40 grpnas_50 grpnas_60 grpnas_70 grpnas_75 grpnas_80 grpnas_85 grpnas_90  
      grpnas_10_sq grpnas_20_sq grpnas_30_sq grpnas_40_sq grpnas_50_sq grpnas_60_sq grpnas_70_sq grpnas_75_sq grpnas_80_sq grpnas_85_sq grpnas_90_sq  
      grpomn_10 grpomn_20 grpomn_30 grpomn_40 grpomn_50 grpomn_60 grpomn_70 grpomn_75 grpomn_80 grpomn_85 grpomn_90  
      grpotc_10 grpotc_20 grpotc_30 grpotc_40 grpotc_50 grpotc_60 grpotc_70 grpotc_75 grpotc_80 grpotc_85 grpotc_90  
      grpadv_10 grpadv_20 grpadv_30 grpadv_40 grpadv_50 grpadv_60 grpadv_70 grpadv_75 grpadv_80 grpadv_85 grpadv_90  
   ;
  output out = mn_std_mdldata_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_mdldata_means(keep=pnasnrx_mean -- grpadv_90_mean)
     mn_std_mdldata_std(keep=pnasnrx_stddev -- grpadv_90_stddev) 
     mn_std_mdldata_sum(keep=pnasnrx_sum -- grpadv_90_sum);
  set mn_std_mdldata_1;
  output mn_std_mdldata_means;
  output mn_std_mdldata_std;
  output mn_std_mdldata_sum;
run;

proc transpose data=mn_std_mdldata_means out=tr_mn_std_mdldata_means; run;
proc transpose data=mn_std_mdldata_std out=tr_mn_std_mdldata_std; run;
proc transpose data=mn_std_mdldata_sum out=tr_mn_std_mdldata_sum; run;

/*
Export data to excel.
*/
%MACRO ExcelExport(indata,sheet_nm);
  PROC EXPORT DATA=&indata. OUTFILE="&PATH.\RAW_MEANS_CORRS_1.XLS"
	  DBMS=EXCEL REPLACE;
	  SHEET="&sheet_nm";
  RUN;
%MEND ExcelExport;

%ExcelExport(mn_std_month_means,mn_std_month_means);
%ExcelExport(mn_std_month_std,mn_std_month_std);
%ExcelExport(mn_std_month_sum,mn_std_month_sum);

%ExcelExport(mn_std_all_means,mn_std_all_means);
%ExcelExport(mn_std_all_std,mn_std_all_std);
%ExcelExport(mn_std_all_sum,mn_std_all_sum);

%ExcelExport(tr_mn_std_mdldata_means,tr_mn_std_mdldata_means);
%ExcelExport(tr_mn_std_mdldata_std,tr_mn_std_mdldata_std);
%ExcelExport(tr_mn_std_mdldata_sum,tr_mn_std_mdldata_sum);

%ExcelExport(corr_all_1,corr_all_1);


/*
Experiment with 101 previously used (2010 study) Top DMAs
*/
/*
MEANS
*/
* BY Month;
proc sort data=mdl1(where=(prev_study_dma_ind=1)) out=mdl1_top101; by yearmo; run;
proc means data=mdl1_top101 nway mean std sum noprint;
  by yearmo;
  var nasnrx mktnrx flunrx vernrx omnnrx nastrx mkttrx flutrx vertrx omntrx 
      det sam vcr mc_nrp grpnas grpnas_sq grpomn grpotc grpadv onl_score onl_score_50
      pnasnrx pmktnrx pflunrx pvernrx pomnnrx pnastrx pmkttrx pflutrx pvertrx pomntrx 
      detmd sammd vcrmd mc_nrp 
      detmd_30 sammd_30 vcrmd_30 grpnas_30 grpomn_30 grpotc_30 grpadv_30
      detmd_60 sammd_60 vcrmd_60 grpnas_60 grpomn_60 grpotc_60 grpadv_60
      detmd_80 sammd_80 vcrmd_80 grpnas_80 grpomn_80 grpotc_80 grpadv_80 ;
  output out = mn_std_month_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_t101_month_means(keep=yearmo nasnrx_mean -- grpadv_80_mean)
     mn_std_t101_month_std(keep=yearmo nasnrx_stddev -- grpadv_80_stddev) 
     mn_std_t101_month_sum(keep=yearmo nasnrx_sum -- grpadv_80_sum);
  set mn_std_month_1;
  output mn_std_t101_month_means;
  output mn_std_t101_month_std;
  output mn_std_t101_month_sum;
run;
%ExcelExport(mn_std_t101_month_means,mn_std_t101_month_means);
%ExcelExport(mn_std_t101_month_std,mn_std_t101_month_std);
%ExcelExport(mn_std_t101_month_sum,mn_std_t101_month_sum);

* Get total target population;
proc sort data=mdl1(keep=dma pop_21_54) out=dma_pop nodupkey; by dma; run;
proc means data=dma_pop nway mean std sum;
  var pop_21_54;
run;


/*
MEANS for PROMOTION ADSTOCKS
*/
* BY Month;
proc sort data=mdl1; by yearmo; run;
proc means data=mdl1 nway mean std sum noprint;
  by yearmo;
  var semS1 semS2 spring fall 
    detmd_10 detmd_20 detmd_30 detmd_40 detmd_50 detmd_60 detmd_70 detmd_75 detmd_80 detmd_85 detmd_90  
    sammd_10 sammd_20 sammd_30 sammd_40 sammd_50 sammd_60 sammd_70 sammd_75 sammd_80 sammd_85 sammd_90  
    grpomn_10 grpomn_20 grpomn_30 grpomn_40 grpomn_50 grpomn_60 grpomn_70 grpomn_75 grpomn_80 grpomn_85 grpomn_90  
    grpotc_10 grpotc_20 grpotc_30 grpotc_40 grpotc_50 grpotc_60 grpotc_70 grpotc_75 grpotc_80 grpotc_85 grpotc_90  
    grpnas_10 grpnas_20 grpnas_30 grpnas_40 grpnas_50 grpnas_60 grpnas_70 grpnas_75 grpnas_80 grpnas_85 grpnas_90  
	grpnas_10_semS1 grpnas_20_semS1 grpnas_30_semS1 grpnas_40_semS1 grpnas_50_semS1 grpnas_60_semS1
    grpnas_70_semS1 grpnas_75_semS1 grpnas_80_semS1 grpnas_85_semS1 grpnas_90_semS1  
	grpnas_10_semS2 grpnas_20_semS2 grpnas_30_semS2 grpnas_40_semS2 grpnas_50_semS2 grpnas_60_semS2
    grpnas_70_semS2 grpnas_75_semS2 grpnas_80_semS2 grpnas_85_semS2 grpnas_90_semS2  
    ;
  output out = mn_std_ads_month_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_ads_month_means(keep=yearmo semS1_mean -- grpnas_90_semS2_mean)
     mn_std_ads_month_std(keep=yearmo semS1_stddev -- grpnas_90_semS2_stddev) 
     mn_std_ads_month_sum(keep=yearmo semS1_sum -- grpnas_90_semS2_sum);
  set mn_std_ads_month_1;
  output mn_std_ads_month_means;
  output mn_std_ads_month_std;
  output mn_std_ads_month_sum;
run;

*OVERALL;
proc means data=mdl1 nway mean std sum noprint;
  var semS1 semS2 spring fall 
    detmd_10 detmd_20 detmd_30 detmd_40 detmd_50 detmd_60 detmd_70 detmd_75 detmd_80 detmd_85 detmd_90  
    sammd_10 sammd_20 sammd_30 sammd_40 sammd_50 sammd_60 sammd_70 sammd_75 sammd_80 sammd_85 sammd_90  
    grpomn_10 grpomn_20 grpomn_30 grpomn_40 grpomn_50 grpomn_60 grpomn_70 grpomn_75 grpomn_80 grpomn_85 grpomn_90  
    grpotc_10 grpotc_20 grpotc_30 grpotc_40 grpotc_50 grpotc_60 grpotc_70 grpotc_75 grpotc_80 grpotc_85 grpotc_90  
    grpnas_10 grpnas_20 grpnas_30 grpnas_40 grpnas_50 grpnas_60 grpnas_70 grpnas_75 grpnas_80 grpnas_85 grpnas_90  
	grpnas_10_semS1 grpnas_20_semS1 grpnas_30_semS1 grpnas_40_semS1 grpnas_50_semS1 grpnas_60_semS1
    grpnas_70_semS1 grpnas_75_semS1 grpnas_80_semS1 grpnas_85_semS1 grpnas_90_semS1  
	grpnas_10_semS2 grpnas_20_semS2 grpnas_30_semS2 grpnas_40_semS2 grpnas_50_semS2 grpnas_60_semS2
    grpnas_70_semS2 grpnas_75_semS2 grpnas_80_semS2 grpnas_85_semS2 grpnas_90_semS2  
    ;
  output out = mn_std_ads_all_1(drop=_type_ _freq_) mean= std= sum= /autoname; 
run;
data mn_std_ads_all_means(keep=semS1_mean -- grpnas_90_semS2_mean)
     mn_std_ads_all_std(keep=semS1_stddev -- grpnas_90_semS2_stddev) 
     mn_std_ads_all_sum(keep=semS1_sum -- grpnas_90_semS2_sum);
  set mn_std_ads_all_1;
  output mn_std_ads_all_means;
  output mn_std_ads_all_std;
  output mn_std_ads_all_sum;
run;

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Explore HalfLife;
%ExcelExport(mn_std_ads_month_means,ads_month_means);
%ExcelExport(mn_std_ads_month_std,ads_month_std);
%ExcelExport(mn_std_ads_month_sum,ads_month_sum);

%ExcelExport(mn_std_ads_all_means,ads_all_means);
%ExcelExport(mn_std_ads_all_std,ads_all_std);
%ExcelExport(mn_std_ads_all_sum,ads_all_sum);




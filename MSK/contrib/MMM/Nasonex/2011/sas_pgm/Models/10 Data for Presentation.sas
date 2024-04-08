/***************************************************************************
10. Data for Presentation
Generate data that does not already exist for the presentation.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\FINAL;

data fnl_mdl_data;
  set rx.FINAL_MODEL_DATA;
run;

/*
Identify two DMA's that differ reasonably in terms of GRP and plot them.
Let one DMA be NY (501)
*/
proc sort data=fnl_mdl_data(where=(yearmo='201103')) out=tst(keep=dma yearmo grpnas_50); 
by descending grpnas_50; 
run;
*choose NYC(501) and Jackson, Mississippi(718);
proc summary data=fnl_mdl_data nway;
class dma; var grpnas_50; output out=try1 ;
run;
data try1m try1s;
  set try1; if _stat_ = "MEAN" then output try1m; if _stat_ = "STD" then output try1s;
run;
proc sort data=try1m out=tst2m; by descending grpnas_50; run;
proc sort data=try1s out=tst2s; by descending grpnas_50; run;

*DMAs: NYC (501), Dallas(623), Jackson, Mississippi(718), Nashville(659);
proc summary data=fnl_mdl_data(where=(dma in ('501','623','718','659'))) nway;
class dma yearmo;
var det sam mc_nrp grpnas grpnas_50
    nasnrx nastrx mktnrx mkttrx pnasnrx;
output out=sm_sum_seldma_by_month sum=;
run;
proc print data=sm_sum_seldma_by_month(obs=100);run;

%macro expt(dset,sht);
PROC EXPORT DATA=&dset.
       OUTFILE= "&PATH.\ppt_raw_data_v1.xls" 
       dbms=excel REPLACE; sheet=&sht.;
run;
%mend;
%expt(sm_sum_seldma_by_month,SUM_SELDMA_month);

/*
GET TOP 5 AND BOTTOM 5 dma'S IN TERMS OF AVERAGE NASONEX GRPs.
Get Avg/min/max for Nasonex wtd GRP's and Population Normalized NRx.
*/
proc sort data=fnl_mdl_data; by dma yearmo; run;
proc summary data=fnl_mdl_data nway;
class dma;
var grpnas pnasnrx;
output out=mn_grp_1 mean=;
run;
proc sort data=mn_grp_1; by descending grpnas; run;
proc print data=mn_grp_1; run;
/*
TOP 5 DMA: 577, 542, 659, 642, 632
Bottom 5 DMA: 749, 771, 766, 740, 747
*/
proc means data=fnl_mdl_data(where=(dma in ('577', '542', '659', '642', '632'
                                         ,'749', '771', '766', '740', '747'))); 
class dma; var grpnas pnasnrx;
run;
* copy the output to excel;














/*
Slide 1 - 
a) Nasonex NRx, Share, GRP, Adstock by month for 101 DMA
b) Nasonex NRx, Share by month for all DMA
Use out.mm_mdl2 as source (since it has longest data from 200712 to 200911)
*/
* 101 DMA;
proc sql;
create table mm_mdl2_101dma as
select * from out.mm_mdl2 
  where dma in (select distinct dma from out.mm_mdl4);
quit;
proc sql;
select count(distinct dma) from mm_mdl2_101dma;
quit;
data mm_mdl2_101dma;
  set mm_mdl2_101dma;
  * nasonex share;
  nasnrxsh=0;
  nastrxsh=0;
  if(NIS_MKTnrx > 0) then nasnrxsh = nasonexnrx / NIS_MKTnrx;
  if(NIS_MKTtrx > 0) then nastrxsh = nasonextrx / NIS_MKTtrx;
  * season var - Nasonex season: jun,jul,aug;
  if(jun+jul+aug >= 1) then seas=1; else seas=0; 
  *spring / fall vars;
  if(mar+apr+may >= 1) then spring=1; else spring=0; 
  if(aug+sep+oct >= 1) then fall=1; else fall=0; 
run;

proc summary data=mm_mdl2_101dma nway;
class month;
var pde smp vch edt tsp evt m_wtrps_nsx tv_nsx_s80 tv_nsx_s60
    nasonexnrx nasonextrx NIS_MKTnrx NIS_MKTtrx nasnrx_pop;
output out=sm_sum_101dma_by_month sum=;
run;
proc print data=sm_sum_101dma_by_month(obs=100);run;

proc means data=mm_mdl2_101dma(where=(month >= '200805' and month <= '200910')); 
var m_wtrps_nsx tv_nsx_s60; run;

*ALL dma;
proc summary data=out.mm_mdl2 nway;
class month;
var pde smp vch edt tsp evt m_wtrps_nsx tv_nsx_s80 tv_nsx_s60
    nasonexnrx nasonextrx NIS_MKTnrx NIS_MKTtrx nasnrx_pop;
output out=sm_sum_ALLdma_by_month sum=;
run;
proc print data=sm_sum_ALLdma_by_month(obs=100);run;



*Local Submit;
%macro expt(dset,sht);
PROC EXPORT DATA=uxwrk.&dset.
       OUTFILE= "S:\SALESOPS\Global Business Analytics\Personal Folders\smurugan\NAS_2010_MktMix\Presentation\VER3\Data\var_sums_3.xls" 
       dbms=excel REPLACE; sheet=&sht.;
run;
%mend;
* var sums;
%expt(sm_sum_101dma_by_month,SUM_101DMA_month);
%expt(sm_sum_ALLdma_by_month,SUM_ALLDMA_month);
*end local submit;

/*
Slide 2 - 
Get Nasonex NRx, Share, Nasonex NRx per 10K pop., GRP, Adstock by month 
          for NY DMA (501) and Dallas DMA (623)
*/
proc summary data=mm_mdl2_101dma(where=(dma in ('501','623'))) nway;
class dma month;
var pde smp vch edt tsp evt m_wtrps_nsx tv_nsx_s80 tv_nsx_s60
    nasonexnrx nasonextrx NIS_MKTnrx NIS_MKTtrx nasnrx_pop;
output out=sm_sum_seldma_by_month sum=;
run;
proc print data=sm_sum_seldma_by_month(obs=100);run;

*Local Submit;
%expt(sm_sum_seldma_by_month,SUM_SELDMA_month);
*end local submit;


/*
Get total target population in US
*/
proc sort data=out.mm_mdl2 out=pop_1(keep=DMA population pop21_60) nodupkey; by dma; run;
proc means data=pop_1 sum; var population pop21_60; run;

/*
Get overall mean
*/
proc means data=out.mm_mdl4; var nasnrx_pop; run;




/*
April/01/2010
Identify two DMA's that differ a lot in terms of GRP and plot them.
Let one DMA be NY (501)
*/
proc sort data=mm_mdl2_101dma(where=(month='200810')) out=tst(keep=dma dmaname month tv_nsx_s60); 
by descending tv_nsx_s60; 
run;
*choose NYC(501) and Jackson, Mississippi(718);

*DMA's: NYC (501), Dallas(623) and Jackson, Mississippi(718);
proc summary data=mm_mdl2_101dma(where=(dma in ('501','623','718'))) nway;
class dma month;
var pde smp vch edt tsp evt m_wtrps_nsx tv_nsx_s80 tv_nsx_s60
    nasonexnrx nasonextrx NIS_MKTnrx NIS_MKTtrx nasnrx_pop;
output out=sm_sum_seldma_by_month sum=;
run;
proc print data=sm_sum_seldma_by_month(obs=100);run;

*Local Submit;
%expt(sm_sum_seldma_by_month,SUM_SELDMA_month);
*end local submit;


/*
Get distribution of Nasonex weighted GRP's
*/
data nsx_grp_vals_1;
  set mm_mdl2_101dma(keep=dma month m_wtrps_nsx tv_nsx_s60);
  if month >= '200805';
run;

*Local Submit;
%expt(nsx_grp_vals_1,NSX_GRP_vals);
*end local submit;


/*
GET TOP 5 AND BOTTOM 5 dma'S IN TERMS OF AVERAGE NASONEX GRPs.
Get Avg/min/max for Nasonex wtd GRP's and Population Normalized NRx.
*/
proc sort data=out.mm_mdl4 out=mm_mdl4; by dma month; run;
proc summary data=mm_mdl4 nway;
class dma;
id dmaname;
var m_wtrps_nsx nasnrx_pop;
output out=mn_grp_1 mean=;
run;
proc sort data=mn_grp_1; by descending m_wtrps_nsx ; run;
proc print data=mn_grp_1; run;
/*
TOP 5 DMA: 659,542,650,544,535
Bottom 5 DMA: 770,803,807,636,649
*/
proc means data=mm_mdl4(where=(dma in ('659','542','650','544','535'
                                         ,'770','803','807','636','649'))); 
class dma dmaname; var m_wtrps_nsx nasnrx_pop;
run;



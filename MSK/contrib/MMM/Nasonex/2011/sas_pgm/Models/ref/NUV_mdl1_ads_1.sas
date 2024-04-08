
/***************************************************************************
  - This program processes DMA, Month level Rx and Promotion data.
  - The input data source is at the DMA, Month level (prepared by Blythe/Ravi)
*****************************************************************************/
libname out "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets\Model_Data";
LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;

proc contents data=out.nuvmdl_2 varnum; run;

/*
Modify model data according to the need
*/ 
data mdl2;
  set out.nuvmdl_2;
run;

/*
Try different models using proc mixed.
USE normalized Nuvaring NRx as dependent VAR.
prev coeffs from chang'smodel(uncorrelated error structure):
lagnrx, mktnrx, ads16, ads16_sq, zads16, vads16, det10, evt10, vch10
*/
proc contents data=mdl2 varnum; run;
proc sort data=mdl2; by dma yearmo; run;
proc mixed data=mdl2  COVTEST  ;
class dma yearmo;
model pnuv_nrx = 
/*fempop_18_49 avg_hh_income*/
workdays time /*time_sq time_cu*/ jan -- nov ffchg_ind pat_edu_ind
lag_pnuv_nrx prmkt_nrx ploe_nrx
detmd_s5  smpmd_s15 vchmd_s15 evtmd_s15  
adstock_f1849_16 /*adstock_f1849_16_sq int_nuv_ads_16*/
zadstock_f1849_16 vadstock_f1849_16 
radstock_f1849_16 /*sadstock_f1849_16*/ 
   /solution ddfm=bw outpred=pred_2;
random  int /*adstock_f1849_16*/
   /subject=dma type=un  gcorr s ;
/*parms /  lowerb=1e-4,.,1e-4 ;*/
repeated/type=ar(1)   subject=dma  ;
*repeated yearmo/type=un   subject=dma sscp ;
ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;
proc means data=pred_2 nway mean std noprint; var resid;
 output out = mn_resid(drop=_type_ _freq_) mean= std= /autoname;  
run;

/* Build a macro to run model and get BIC for the model */
* establish base dataset with no rows;
data est_fit;  length vars1 $100. vars2 $200. vars3 $200. descr $25. value 8 bic 8; set fit1(obs=0); run;
data est_fixed;  length vars1 $100. vars2 $200. vars3 $200. effect $20. estimate stderr df tvalue probt 8 bic 8 resid_mean 8 resid_stddev 8; set fixed1(obs=0);run;
data est_rand;  length vars1 $100. vars2 $200. vars3 $200. ;  set random1(obs=0); run;

proc sort data=mdl2 out=mdldata; by dma month; run;
*macro to build model repeatedly;
%let vList1 = workdays time jan -- nov ffchg_ind pat_edu_ind lag_pnuv_nrx prmkt_nrx ploe_nrx;
%let vList2 = ;
%macro mdlnrx(mdl_vars);
  proc mixed data=mdldata COVTEST  ;
    class dma yearmo;
    model pnuv_nrx = &vList1. &vList2. &mdl_vars.  
       /solution ddfm=bw outpred=pred_2;
    *random  int /*adstock_f1849_16*/
       /subject=dma type=un  gcorr s ;
    /*parms /  lowerb=1e-4,.,1e-4 ;*/
    repeated/type=ar(1)   subject=dma  ;
    ods output fitstatistics=fit1 solutionf=fixed1; *solutionr=random1;
  run;
  proc means data=pred_2 nway mean std noprint; var resid;
    output out = mn_resid(drop=_type_ _freq_) mean= std= /autoname;  
  run;
  data fit1; 
    length vars1 $100. vars2 $200. vars3 $200.; 
    set fit1; if _n_ = 4; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars.";
    bic = value; 
  run;
  data fixed1; 
    length vars1 $100. vars2 $200. vars3 $200.; 
    set fixed1; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars."; 
  run;
  data fixed2;
    if _n_=1 then set fit1(keep=bic);
    if _n_=1 then set mn_resid;
	set fixed1;
  run;
  data random1; 
    length vars1 $100. vars2 $200. vars3 $200. ; 
    set random1; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars."; 
  run;
  proc append base=est_fit data=fit1 force; run;
  proc append base=est_fixed data=fixed2 force; run;
  proc append base=est_rand data=random1 force; run;
%mend mdlnrx;

%let path=Y:\PRA\DTC\NuvaRing\2011 profit plan\SAS Datasets\Model_Data\Estimates1;
%macro expt(sheet);
  proc export data=est_fixed outfile="&path\mdl1_est_fixed_1.xls" dbms=excel97 replace; 
    sheet=&sheet; run;
  * reset fixed estimate dataset;
  data est_fixed; set est_fixed(obs=0); run;

  proc export data=est_fit outfile="&path\mdl1_est_fit_1.xls" dbms=excel97 replace; 
    sheet=&sheet; run;
  * reset fixed estimate dataset;
  data est_fit; set est_fit(obs=0); run;
%mend expt;

* initial model;
%let vList2 = detmd_s15 smpmd_s15 vchmd_s15 evtmd_s15 adstock_f1849_16 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx();
%expt(ini);

/*
ITERATION 1
*/
* detail exploration;
%let vList2 = smpmd_s15 vchmd_s15 evtmd_s15 adstock_f1849_16 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(detmd_s5); %mdlnrx(detmd_s10); %mdlnrx(detmd_s15); %mdlnrx(detmd_s20); %mdlnrx(detmd_s25);
%mdlnrx(detmd_s30);%mdlnrx(detmd_s35);%mdlnrx(detmd_s40);%mdlnrx(detmd_s45); 
%expt(det1);
* choose detmd_s5;

* sample exploration;
%let vList2 = detmd_s5 vchmd_s15 evtmd_s15 adstock_f1849_16 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(smpmd_s5); %mdlnrx(smpmd_s10); %mdlnrx(smpmd_s15); %mdlnrx(smpmd_s20); %mdlnrx(smpmd_s25);
%mdlnrx(smpmd_s30);%mdlnrx(smpmd_s35);%mdlnrx(smpmd_s40);%mdlnrx(smpmd_s45); 
%expt(smp1);
* choose smpmd_s15;

* vch exploration;
%let vList2 = detmd_s5 smpmd_s15 evtmd_s15 adstock_f1849_16 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(vchmd_s5); %mdlnrx(vchmd_s10); %mdlnrx(vchmd_s15); %mdlnrx(vchmd_s20); %mdlnrx(vchmd_s25);
%mdlnrx(vchmd_s30);%mdlnrx(vchmd_s35);%mdlnrx(vchmd_s40);%mdlnrx(vchmd_s45); 
%expt(vch1);
* choose vchmd_s5;

* evt exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 adstock_f1849_16 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(evtmd_s5); %mdlnrx(evtmd_s10); %mdlnrx(evtmd_s15); %mdlnrx(evtmd_s20); %mdlnrx(evtmd_s25);
%mdlnrx(evtmd_s30);%mdlnrx(evtmd_s35);%mdlnrx(evtmd_s40);%mdlnrx(evtmd_s45); 
%expt(evt1);
* choose evtmd_s30;

* Nuvaring linear adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(adstock_f1849_2); %mdlnrx(adstock_f1849_4); %mdlnrx(adstock_f1849_6); %mdlnrx(adstock_f1849_8); 
%mdlnrx(adstock_f1849_10); %mdlnrx(adstock_f1849_12); %mdlnrx(adstock_f1849_14); %mdlnrx(adstock_f1849_16); 
%mdlnrx(adstock_f1849_18); %mdlnrx(adstock_f1849_20); %mdlnrx(adstock_f1849_22); %mdlnrx(adstock_f1849_24); 
%expt(nuvl1);
* choose adstock_f1849_6;

* Nuvaring Square term adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6 zadstock_f1849_16 vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(adstock_f1849_6_sq); 
%expt(nuvs1);
* choose adstock_f1849_6_sq;

* Yaz adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq vadstock_f1849_16 radstock_f1849_16;
%mdlnrx(zadstock_f1849_2); %mdlnrx(zadstock_f1849_4); %mdlnrx(zadstock_f1849_6); %mdlnrx(zadstock_f1849_8); 
%mdlnrx(zadstock_f1849_10); %mdlnrx(zadstock_f1849_12); %mdlnrx(zadstock_f1849_14); %mdlnrx(zadstock_f1849_16); 
%mdlnrx(zadstock_f1849_18); %mdlnrx(zadstock_f1849_20); %mdlnrx(zadstock_f1849_22); %mdlnrx(zadstock_f1849_24); 
%expt(yaz1);
* choose zadstock_f1849_12;

* Yaz-corrective adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 radstock_f1849_16;
%mdlnrx(vadstock_f1849_2); %mdlnrx(vadstock_f1849_4); %mdlnrx(vadstock_f1849_6); %mdlnrx(vadstock_f1849_8); 
%mdlnrx(vadstock_f1849_10); %mdlnrx(vadstock_f1849_12); %mdlnrx(vadstock_f1849_14); %mdlnrx(vadstock_f1849_16); 
%mdlnrx(vadstock_f1849_18); %mdlnrx(vadstock_f1849_20); %mdlnrx(vadstock_f1849_22); %mdlnrx(vadstock_f1849_24); 
%expt(yazc1);
* choose vadstock_f1849_6;

* Mirena adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6;
%mdlnrx(); * no mirena;
%mdlnrx(radstock_f1849_2); %mdlnrx(radstock_f1849_4); %mdlnrx(radstock_f1849_6); %mdlnrx(radstock_f1849_8); 
%mdlnrx(radstock_f1849_10); %mdlnrx(radstock_f1849_12); %mdlnrx(radstock_f1849_14); %mdlnrx(radstock_f1849_16); 
%mdlnrx(radstock_f1849_18); %mdlnrx(radstock_f1849_20); %mdlnrx(radstock_f1849_22); %mdlnrx(radstock_f1849_24); 
%expt(mir1);
* choose radstock_f1849_14;

* Seasonique adstock exploration;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(sadstock_f1849_2); %mdlnrx(sadstock_f1849_4); %mdlnrx(sadstock_f1849_6); %mdlnrx(sadstock_f1849_8); 
%mdlnrx(sadstock_f1849_10); %mdlnrx(sadstock_f1849_12); %mdlnrx(sadstock_f1849_14); %mdlnrx(sadstock_f1849_16); 
%mdlnrx(sadstock_f1849_18); %mdlnrx(sadstock_f1849_20); %mdlnrx(sadstock_f1849_22); %mdlnrx(sadstock_f1849_24); 
%expt(sea1);
* DO NOT choose sadstock_f1849_**;

/*
The Selected model from above iteration is (Fxd.Eff. AR(1) error structure):
pnuv_nrx = 
workdays time jan -- nov ffchg_ind pat_edu_ind lag_pnuv_nrx prmkt_nrx ploe_nrx;
detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 
adstock_f1849_6 adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
*/

/*********
STEP 2:
Hold above selected model as constant in terms of promotion variable and explore 
the following:
1) Explore time, ffchg_ind and pat_edu_ind inclusions and interactions.
2) Explore excluding smp var or replacing it with lagged smp var to avoid multi collinearity
   with details.
************/
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx;
%let vList2 = detmd_s5 smpmd_s15 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 
              vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(time time_sq time_cu ffchg_ind pat_edu_ind); %mdlnrx(time time_sq ffchg_ind pat_edu_ind);
%mdlnrx(time ffchg_ind pat_edu_ind); %mdlnrx(ffchg_ind pat_edu_ind); 
%mdlnrx(ffchg_ind); %mdlnrx(pat_edu_ind); %mdlnrx(); 
%mdlnrx(cq2 - cq10); %mdlnrx(cq2 - cq4);
%expt(tim1);
* No Time variables or continuing quarters selected. ff_chg_ind and pat_edu_ind are retained;

* Explore detail, lagged sample terms;
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s5 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 
              vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(lagsmpmd5); %mdlnrx(lagsmpmd10); %mdlnrx(lagsmpmd15); %mdlnrx(lagsmpmd20); 
%mdlnrx(lagsmpmd25); %mdlnrx(lagsmpmd30);%mdlnrx(lagsmpmd35);%mdlnrx(lagsmpmd40);
%mdlnrx(lagsmpmd45); 
%expt(lsmp1);
* choose lagsmpmd20, but search for other detail levels;

* Explore detail, given a lagged sample term;
%let vList2 = lagsmpmd20 vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 
              vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(detmd_s5); %mdlnrx(detmd_s10); %mdlnrx(detmd_s15); %mdlnrx(detmd_s20); 
%mdlnrx(detmd_s25); %mdlnrx(detmd_s30); %mdlnrx(detmd_s35); %mdlnrx(detmd_s40); 
%mdlnrx(detmd_s45);
%expt(lsd1);
* Drop exploration of lagged samples as none of detail decay rates are significant;

* Explore just detail term;
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = vchmd_s5 evtmd_s30 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 
              vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(detmd_s5 smpmd_s15); 
%mdlnrx(detmd_s5); %mdlnrx(detmd_s10); %mdlnrx(detmd_s15); %mdlnrx(detmd_s20); 
%mdlnrx(detmd_s25); %mdlnrx(detmd_s30); %mdlnrx(detmd_s35); %mdlnrx(detmd_s40);
%mdlnrx(detmd_s45);
%expt(dnos1);
* choose detmd_s20, when considering to drop samples;

/*
As of now we have two possible models using AR(1) structure.
1. When both details and samples are included:
pnuv_nrx = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind
vchmd_s5 evtmd_s30 detmd_s5 smpmd_s15
adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14

2. When only details are included:
pnuv_nrx = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind
vchmd_s5 evtmd_s30 detmd_s20
adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14

For the second iteration, consider the 2nd model above for further exploration.
*/

/*****************************************************
ITERATION 2:
******************************************************/

%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;

*Explore events. details were already explored in the final step of last iteration;
%let vList2 = vchmd_s5 detmd_s20 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(evtmd_s5); %mdlnrx(evtmd_s10); %mdlnrx(evtmd_s15); %mdlnrx(evtmd_s20); %mdlnrx(evtmd_s25);
%mdlnrx(evtmd_s30);%mdlnrx(evtmd_s35);%mdlnrx(evtmd_s40);%mdlnrx(evtmd_s45); 
%expt(evt2);
* choose evtmd_s20;

*Explore voucher.;
%let vList2 = detmd_s20 evtmd_s20 adstock_f1849_6  adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(vchmd_s5); %mdlnrx(vchmd_s10); %mdlnrx(vchmd_s15); %mdlnrx(vchmd_s20); %mdlnrx(vchmd_s25);
%mdlnrx(vchmd_s30);%mdlnrx(vchmd_s35);%mdlnrx(vchmd_s40);%mdlnrx(vchmd_s45); 
%expt(vch2);
* choose vchmd_s5;

*Explore NUV Adstocks;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s5 zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(adstock_f1849_1  adstock_f1849_1_sq); %mdlnrx(adstock_f1849_2  adstock_f1849_2_sq); 
%mdlnrx(adstock_f1849_3  adstock_f1849_3_sq); %mdlnrx(adstock_f1849_4  adstock_f1849_4_sq);
%mdlnrx(adstock_f1849_5  adstock_f1849_5_sq); %mdlnrx(adstock_f1849_6  adstock_f1849_6_sq);
%mdlnrx(adstock_f1849_7  adstock_f1849_7_sq); %mdlnrx(adstock_f1849_8  adstock_f1849_8_sq); 
%mdlnrx(adstock_f1849_9  adstock_f1849_9_sq); %mdlnrx(adstock_f1849_10  adstock_f1849_10_sq); 
%mdlnrx(adstock_f1849_11  adstock_f1849_11_sq); %mdlnrx(adstock_f1849_12  adstock_f1849_12_sq); 
%mdlnrx(adstock_f1849_13  adstock_f1849_13_sq); %mdlnrx(adstock_f1849_14  adstock_f1849_14_sq); 
%mdlnrx(adstock_f1849_15  adstock_f1849_15_sq); %mdlnrx(adstock_f1849_16  adstock_f1849_16_sq); 
%expt(nuv2);
* choose adstock_f1849_5  adstock_f1849_5_sq;
/*
NOTE:
Since the model parameters (i.e., decay rate) did not change much up to selecting
the Nuvaring Adstocks, it is anticipated that the other adstock parameters also may not
change much.
*/

* RUN for final fixed effects AR(1) error structure model parameters;
*Model with details only;
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s5 adstock_f1849_5  adstock_f1849_5_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(); 
*Model with details and samples;
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s5 smpmd_s15 evtmd_s20 vchmd_s5 adstock_f1849_5  adstock_f1849_5_sq zadstock_f1849_12 vadstock_f1849_6 radstock_f1849_14;
%mdlnrx(); 
%expt(FxdEffAR1Models);






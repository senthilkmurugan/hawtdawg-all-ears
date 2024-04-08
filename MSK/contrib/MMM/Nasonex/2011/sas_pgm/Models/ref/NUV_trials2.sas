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

/* CORRELATIONS */
proc sort data=mdl2 out=tmp; by dma yearmo; run;
proc corr data=tmp outp=corr_1;
  by dma;
  var adstock_f1849_6 adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 ladstock_f1849_12 
      sadstock_f1849_12 radstock_f1849_14; 
run;

data corr2;
set corr_1;
if _NAME_ = "ADSTOCK_F1849_6";
run;
proc univariate data=corr2;
var adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 ladstock_f1849_12 
      sadstock_f1849_12 radstock_f1849_14;
*output out=univar1;
run;

/*
MEANS
*/
proc means data=tmp;
  var adstock_f1849_6 adstock_f1849_6_sq zadstock_f1849_12 vadstock_f1849_6 ladstock_f1849_12 
      sadstock_f1849_12 radstock_f1849_14;
run;


/*
OLS Regression exploration for some models
*/
%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s10 zadstock_f1849_12 vadstock_f1849_6;
* radstock_f1849_14;
%let mdlvars = adstock_f1849_6 adstock_f1849_6_sq;

data regdata;
  set mdl2;
  if rtime >= 6; * starts from july08 (24 months);
run;
proc sort data=regdata; by dma yearmo; run;
proc reg data=regdata outest=out_est_2 tableout outsscp=sscp_2;
  * NO MIRENA;
  model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  * WITH MIRENA;
  *model pnuv_nrx = &vList1. &vList2. radstock_f1849_14 &mdlvars. / vif ss2;
run;
quit;

%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s10 zadstock_f1849_12; * vadstock_f1849_6;
%let mdlvars = adstock_f1849_6 adstock_f1849_6_sq;
proc reg data=regdata outest=out_est_2 tableout outsscp=sscp_2;
  * NO MIRENA;
  model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  * WITH MIRENA;
  *model pnuv_nrx = &vList1. &vList2. radstock_f1849_14 &mdlvars. / vif ss2;
run;
quit;

%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx /*ffchg_ind*/ pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s10 zadstock_f1849_12; * vadstock_f1849_6;
%let mdlvars = adstock_f1849_6 adstock_f1849_6_sq;
proc reg data=regdata outest=out_est_2 tableout outsscp=sscp_2;
  * NO MIRENA;
  model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  * WITH MIRENA;
  *model pnuv_nrx = &vList1. &vList2. radstock_f1849_14 &mdlvars. / vif ss2;
run;
quit;


%let vList1 = workdays jan -- nov lag_pnuv_nrx prmkt_nrx ploe_nrx ffchg_ind pat_edu_ind;
%let vList2 = detmd_s20 evtmd_s20 vchmd_s10 yadstock_f1849_12; * vadstock_f1849_6;
%let mdlvars = adstock_f1849_6 adstock_f1849_6_sq;
proc reg data=regdata outest=out_est_2 tableout outsscp=sscp_2;
  * NO MIRENA;
  model pnuv_nrx = &vList1. &vList2. &mdlvars. / vif ss2;
  * WITH MIRENA;
  *model pnuv_nrx = &vList1. &vList2. radstock_f1849_14 &mdlvars. / vif ss2;
run;
quit;



/***************************************************************************
7. Explore more on possible halflife's for possible final model structure 
   [Full Model with Interactions (FMI)].
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;

data mdl1;
  set rx.MODEL_DATA_v1;
run;

data mdl2;
  set mdl1;
  *create grpnas interactions;
  grpnas_10_semS1 = grpnas_10*semS1; grpnas_10_semS2 = grpnas_10*semS2;
  grpnas_20_semS1 = grpnas_20*semS1; grpnas_20_semS2 = grpnas_20*semS2;
  grpnas_30_semS1 = grpnas_30*semS1; grpnas_30_semS2 = grpnas_30*semS2;
  grpnas_40_semS1 = grpnas_40*semS1; grpnas_40_semS2 = grpnas_40*semS2;
  grpnas_50_semS1 = grpnas_50*semS1; grpnas_50_semS2 = grpnas_50*semS2;
  grpnas_60_semS1 = grpnas_60*semS1; grpnas_60_semS2 = grpnas_60*semS2;
  grpnas_70_semS1 = grpnas_70*semS1; grpnas_70_semS2 = grpnas_70*semS2;
  grpnas_75_semS1 = grpnas_75*semS1; grpnas_75_semS2 = grpnas_75*semS2;
  grpnas_80_semS1 = grpnas_80*semS1; grpnas_80_semS2 = grpnas_80*semS2;
  grpnas_85_semS1 = grpnas_85*semS1; grpnas_85_semS2 = grpnas_85*semS2;
  grpnas_90_semS1 = grpnas_90*semS1; grpnas_90_semS2 = grpnas_90*semS2;
run;
/*
* store as permanent data set ;
 data rx.MODEL_DATA_v1;
  set mdl2;
run;
*/

/*
Try different models using proc mixed.
*/
proc contents data=mdl1 varnum; run;
proc sort data=mdl1; by dma yearmo; run;

proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50
         grpnas_60*semS1 grpnas_60*semS2 
      / solution outpred=pred_2;
  random intercept / subject=dma s;
  *repeated/type=ar(1)   subject=dma  ;
  ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;
proc means data=pred_2 nway mean std noprint; var resid;
 output out = mn_resid(drop=_type_ _freq_) mean= std= /autoname;  
run;

/* Build a macro to run model and get BIC for the model */
* establish base dataset with no rows;
data est_fit;  length vars1 $200. vars2 $200. vars3 $200. descr $25. value 8 bic 8; set fit1(obs=0); run;
data est_fixed;  length vars1 $200. vars2 $200. vars3 $200. effect $20. estimate stderr df tvalue probt 8 bic 8 resid_mean 8 resid_stddev 8; set fixed1(obs=0);run;
data est_rand;  length vars1 $200. vars2 $200. vars3 $200. ;  set random1(obs=0); run;

proc sort data=mdl1 out=mdldata; by dma yearmo; run;
*macro to build model repeatedly;
%let vList1 = t1 - t24 mc_nrp lag_pnasnrx;
%let vList2 = detmd_30 sammd_80 grpomn_60 grpotc_60 onl_score_50 grpnas_60*semS1 grpnas_60*semS2;
%macro mdlnrx(mdl_vars);
  proc mixed data=mdldata covtest noclprint empirical; 
    class dma yearmo;
    model pnasnrx = &vList1. &vList2. &mdl_vars.   
        / solution outpred=pred_2;
    random intercept / subject=dma s;
    *repeated/type=ar(1)   subject=dma  ;
    ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
  run;
  proc means data=pred_2 nway mean std noprint; var resid;
    output out = mn_resid(drop=_type_ _freq_) mean= std= /autoname;  
  run;
  data fit1; 
    length vars1 $200. vars2 $200. vars3 $200.; 
    set fit1; if _n_ = 4; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars.";
    bic = value; 
  run;
  data fixed1; 
    length vars1 $200. vars2 $200. vars3 $200.; 
    set fixed1; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars."; 
  run;
  data fixed2;
    if _n_=1 then set fit1(keep=bic);
    if _n_=1 then set mn_resid;
	set fixed1;
  run;
  data random1; 
    length vars1 $200. vars2 $200. vars3 $200. ; 
    set random1; 
    vars1="&vList1."; vars2="&vList2."; vars3="&mdl_vars."; 
  run;
  proc append base=est_fit data=fit1 force; run;
  proc append base=est_fixed data=fixed2 force; run;
  proc append base=est_rand data=random1 force; run;
%mend mdlnrx;

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Explore HalfLife;
%macro expt(sheet);
  proc export data=est_fixed outfile="&path\FMI1_est_fixed_1.xls" dbms=excel97 replace; 
    sheet=&sheet; run;
  * reset fixed estimate dataset;
  data est_fixed; set est_fixed(obs=0); run;

  proc export data=est_fit outfile="&path\FMI1_est_fit_1.xls" dbms=excel97 replace; 
    sheet=&sheet; run;
  * reset fixed estimate dataset;
  data est_fit; set est_fit(obs=0); run;
%mend expt;

* initial model;
%let vList2 = detmd_30 sammd_80 grpomn_60 grpotc_60 grpnas_60*semS1 grpnas_60*semS2;
%mdlnrx();
%expt(ini);

/*
ITERATION 1
*/
* detail exploration;
%let vList2 = sammd_80 grpomn_60 grpotc_60 grpnas_60*semS1 grpnas_60*semS2;
%mdlnrx(detmd_10); %mdlnrx(detmd_20); %mdlnrx(detmd_30); %mdlnrx(detmd_40); 
%mdlnrx(detmd_50); %mdlnrx(detmd_60); %mdlnrx(detmd_70); %mdlnrx(detmd_75);
%mdlnrx(detmd_80); %mdlnrx(detmd_85); %mdlnrx(detmd_90); 
%expt(det1);
* choose detmd_40;

* sample exploration;
%let vList2 = detmd_40 grpomn_60 grpotc_60 grpnas_60*semS1 grpnas_60*semS2;
%mdlnrx(sammd_10); %mdlnrx(sammd_20); %mdlnrx(sammd_30); %mdlnrx(sammd_40); 
%mdlnrx(sammd_50); %mdlnrx(sammd_60); %mdlnrx(sammd_70); %mdlnrx(sammd_75);
%mdlnrx(sammd_80); %mdlnrx(sammd_85); %mdlnrx(sammd_90); 
%expt(smp1);
* choose sammd_50;

* OMN GRP exploration;
%let vList2 = detmd_40 sammd_50 grpotc_60 grpnas_60*semS1 grpnas_60*semS2;
%mdlnrx(grpomn_10); %mdlnrx(grpomn_20); %mdlnrx(grpomn_30); %mdlnrx(grpomn_40); 
%mdlnrx(grpomn_50); %mdlnrx(grpomn_60); %mdlnrx(grpomn_70); %mdlnrx(grpomn_75);
%mdlnrx(grpomn_80); %mdlnrx(grpomn_85); %mdlnrx(grpomn_90); 
%expt(omn1);
* choose grpomn_70;

* OTC GRP exploration;
%let vList2 = detmd_40 sammd_50 grpomn_70 grpnas_60*semS1 grpnas_60*semS2;
%mdlnrx(grpotc_10); %mdlnrx(grpotc_20); %mdlnrx(grpotc_30); %mdlnrx(grpotc_40); 
%mdlnrx(grpotc_50); %mdlnrx(grpotc_60); %mdlnrx(grpotc_70); %mdlnrx(grpotc_75);
%mdlnrx(grpotc_80); %mdlnrx(grpotc_85); %mdlnrx(grpotc_90); 
%expt(otc1);
* choose grpotc_60;

* NAS GRP * semS1 Interaction exploration;
%let vList2 = detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_60*semS2;
%mdlnrx(grpnas_10*semS1); %mdlnrx(grpnas_20*semS1); %mdlnrx(grpnas_30*semS1); %mdlnrx(grpnas_40*semS1); 
%mdlnrx(grpnas_50*semS1); %mdlnrx(grpnas_60*semS1); %mdlnrx(grpnas_70*semS1); %mdlnrx(grpnas_75*semS1);
%mdlnrx(grpnas_80*semS1); %mdlnrx(grpnas_85*semS1); %mdlnrx(grpnas_90*semS1); 
%expt(nas_semS1_1);
* choose grpnas_50*semS1;

* NAS GRP * semS2 Interaction exploration;
%let vList2 = detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1;
%mdlnrx(grpnas_10*semS2); %mdlnrx(grpnas_20*semS2); %mdlnrx(grpnas_30*semS2); %mdlnrx(grpnas_40*semS2); 
%mdlnrx(grpnas_50*semS2); %mdlnrx(grpnas_60*semS2); %mdlnrx(grpnas_70*semS2); %mdlnrx(grpnas_75*semS2);
%mdlnrx(grpnas_80*semS2); %mdlnrx(grpnas_85*semS2); %mdlnrx(grpnas_90*semS2); 
%expt(nas_semS2_1);
* choose grpnas_50*semS2;

******* END of Iteration 1 ****************;
/*
From Iteration 1, the chosen model is:
vList1 = t1 - t24 mc_nrp lag_pnasnrx;
vList2 = detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2;
*/

************** Iteration 2  *****************;
* search for better OMN / OTC GRP;
* OMN GRP exploration;
%let vList2 = detmd_40 sammd_50 grpotc_60 grpnas_50*semS1 grpnas_50*semS2;
%mdlnrx(grpomn_10); %mdlnrx(grpomn_20); %mdlnrx(grpomn_30); %mdlnrx(grpomn_40); 
%mdlnrx(grpomn_50); %mdlnrx(grpomn_60); %mdlnrx(grpomn_70); %mdlnrx(grpomn_75);
%mdlnrx(grpomn_80); %mdlnrx(grpomn_85); %mdlnrx(grpomn_90); 
%expt(omn2);
* leave grpomn_70 as is.;

* OTC GRP exploration;
%let vList2 = detmd_40 sammd_50 grpomn_70 grpnas_50*semS1 grpnas_50*semS2;
%mdlnrx(grpotc_10); %mdlnrx(grpotc_20); %mdlnrx(grpotc_30); %mdlnrx(grpotc_40); 
%mdlnrx(grpotc_50); %mdlnrx(grpotc_60); %mdlnrx(grpotc_70); %mdlnrx(grpotc_75);
%mdlnrx(grpotc_80); %mdlnrx(grpotc_85); %mdlnrx(grpotc_90); 
%expt(otc2);
* RETAIN grpotc_60;

******* END of Iteration 2 ****************;
/*
From Iteration 2, the sae Iter1 final model is chosen.
vList1 = t1 - t24 mc_nrp lag_pnasnrx;
vList2 = detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2;
*/
/*
Parameter estimates
effect	          estimate	    stderr	    df	   tvalue	    probt
Intercept	      -5.154011592	0.789936504	209	   -6.524589722	 0.00
t1	              -1.431525169	2.891193317	4799   -0.495132982	 0.62
t2	               1.262042741	3.639192816	4799    0.346791941	 0.73
t3	              -2.21948466	2.324693048	4799   -0.954743106	 0.34
t4	              -0.747629545	1.44036136	4799   -0.519056929	 0.60
t5	               6.97820009	1.115111922	4799    6.257847264	 0.00
t6	               0.654734927	0.725532263	4799    0.90242014	 0.37
t7	               2.862146609	0.979542874	4799    2.92192071	 0.00
t8	              12.72699705	0.899688565	4799   14.14600291	 0.00
t9	               9.827713999	0.869459643	4799   11.30324343	 0.00
t10	              -0.114691415	0.879627722	4799   -0.130386313	 0.90
t11	              -2.529306579	0.524522847	4799   -4.822109454	 0.00
t12	              -2.13622953	1.12311679	4799   -1.902054665	 0.06
t13	               2.071740941	2.200790393	4799    0.941362225	 0.35
t14	               4.752989571	2.178313617	4799    2.181958343	 0.03
t15	               0.672685444	1.247350877	4799    0.539291275	 0.59
t16	               1.367922442	0.811715977	4799    1.68522301	 0.09
t17	               4.646277674	0.73526394	4799    6.319196989	 0.00
t18	               2.990427765	0.567280814	4799    5.271512255	 0.00
t19	               1.95524101	0.825029981	4799    2.36990298	 0.02
t20	              11.94378191	0.677624629	4799   17.62595604	 0.00
t21	               3.993200827	0.657520602	4799    6.073118951	 0.00
t22	               4.791617724	0.696998317	4799    6.87464748	 0.00
t23	               0.403711792	0.584438849	4799    0.690768235	 0.49
t24	               0				
mc_nrp	           3.731917073	1.029426888	4799    3.625237611	 0.00
lag_pnasnrx	       0.903927032	0.024326071	4799   37.15877596	 0.00
detmd_40	       0.001151452	0.000405105	4799    2.842355312	 0.00
sammd_50	       0.000360708	0.000116493	4799    3.096404779	 0.00
GRPOMN_70	      -0.005729286	0.003293241	4799   -1.739710374	 0.08
GRPOTC_60	      -0.002422273	0.000616469	4799   -3.929268749	 0.00
GRPNAS_50*semS1	   0.01323155	0.003300396	4799    4.009079149	 0.00
GRPNAS_50*semS2	   0.036491011	0.009059736	4799    4.02782293	 0.00
*/

/*
AFter this step, go back to exploring variograms and several covariance structures
for the above chosen model.
After variogram exercises the same model above was chosen as appropriate as none of the covariance structures
resulted in drastic improvement in correlated residual error structure (so chose the simplest model).
*/


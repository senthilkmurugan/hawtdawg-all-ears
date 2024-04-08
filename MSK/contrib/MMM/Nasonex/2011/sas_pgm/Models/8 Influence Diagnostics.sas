
/***************************************************************************
8. Explore Outliers Through Influence Diagnostics for selected model
   [Full Model with Interactions (FMI)].

Extend influence diagnostics to close to final RI model (with SP(POW) repeated covariance structure.
****************************************************************************/
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME out "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

options nocenter compress=yes;
options mlogic mprint nosymbolgen;

data mdl1;
  set rx.MODEL_DATA_v1;
run;

proc contents data=mdl1 varnum; run;
proc sort data=mdl1; by dma yearmo; run;

/*
INFLUENCE DIAGNOSTICS
*/
* MODEL OF INTEREST - Influence Diagnostics;
proc mixed data=mdl1 covtest noclprint empirical; 
  class dma yearmo;
  model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2
      / solution outpred=pred_2  influence(iter=5 effect=dma est);
  random intercept / subject=dma s;
  *repeated yearmo /type=ar(1)   subject=dma  ;
  ods output influence=inf1 fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Influence Diagnostics;
proc export data=inf1 outfile="&path\FMI_influence_diagnostics_1.xls" dbms=excel97 replace; 
    sheet="raw_inf_diag"; 
run;

* Try removing DMA's 626, 798 and build model again;
data mdl1_reduced;
  set mdl1;
  if dma in ('626','798') then outlier_dma_ind = 1; else outlier_dma_ind = 0;
run;
proc mixed data=mdl1_reduced(where=(outlier_dma_ind=0)) covtest noclprint empirical; 
  class dma yearmo;
  model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
         detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2
      / solution outpred=pred_2;
  random intercept / subject=dma s;
  *repeated yearmo /type=ar(1)   subject=dma  ;
  ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;
****************************************** THE ABOVE SEEMS TO APPROACH THE FINAL MODEL STRUCTURE ;

/*
* store as permanent data set ;
 data rx.MODEL_DATA_v1;
  set mdl1_reduced;
run;
*/

* explore grpomn halflife as it has turned non-significant now.;
data mdl1_reduced;
  set mdl1_reduced;
  rtime = time_idx - 6;
run;
proc sort data=mdl1_reduced; by dma yearmo; run;
proc mixed data=mdl1_reduced(where=(outlier_dma_ind=0)) covtest noclprint empirical; 
  class dma yearmo;
  model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx /*pothnrx */
         detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2
      / solution outpred=pred_2;
  *random intercept / subject=dma s;
  repeated yearmo /type=UN SSCP  subject=dma rcorr ;
  ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;

* grpomn approaches p=0.06 for halflife with 90% decay rate (too high, so ignoe and go with previous structure).;

%macro rtfopen(filename);
  options ls=75 ps=3000 nodate nocenter nonumber;
  ODS LISTING CLOSE;
  ODS RTF FILE="&PATH.\&filename." STYLE=JOURNAL BODYTITLE;
%mend rtfopen;
%macro rtfclose();
  ODS RTF CLOSE;
  ODS LISTING;
%mend rtfclose;

*** MOST LATEST MODEL ********;
%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Influence Diagnostics;
proc sort data=mdl1; by dma yearmo; run;
ODS OUTPUT PARAMETERESTIMATES=e2;
%rtfopen(mdl_after_infdiag_1.rtf);
proc mixed data=mdl1(where=(outlier_dma_ind=0)) covtest noclprint empirical; 
  class dma yearmo;
  model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx /*pothnrx*/
         detmd_40 sammd_50 grpomn_70 grpotc_60 /*grpnas_50 */
          grpnas_50*semS1 grpnas_50*semS2
      / solution outpred=pred_2;
  random intercept / subject=dma s;
  *repeated yearmo /type=ar(1)   subject=dma  ;
  ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
  contrast 'nas' grpnas_50*semS1 0.6743 grpnas_50*semS2 0.3257; * significant;
  contrast 'diff' grpnas_50*semS1 0.6743 grpnas_50*semS2 -0.3257; * significant;
  estimate 'e_nas' grpnas_50*semS1 0.6743 grpnas_50*semS2 0.3257 / cl; 
  estimate 'e_diff' grpnas_50*semS1 0.6743 grpnas_50*semS2 -0.3257 / cl; 
run;
%rtfclose();

* consider Allison's Fixed Effects Model, to check the biases ;
proc sort data=mdl1; by dma yearmo; run;
%rtfopen(mdl_after_infdiag_fxdeff_1.rtf);
proc glm data=mdl1(where=(outlier_dma_ind=0));
  absorb dma;
  model pnasnrx = t1 - t23 lag_pnasnrx /*pothnrxsh*/
         detmd_40 sammd_50 grpomn_70 grpotc_60 /*grpnas_50 */
          grpnas_50*semS1 grpnas_50*semS2
      / solution;
run; quit;
%rtfclose();


/*
EXTEND INFLUENCE DIAGNOSTICS FOR CLOSE TO FINAL SELECTED MODEL (FMI+RI ACHIEVED THROUGH SP(POW) COV. STRUCTURE).
*/
/*
INFLUENCE DIAGNOSTICS
*/
* FINAL MODEL structure - Influence Diagnostics;
proc sort data=mdl1; by dma yearmo; run;
data mdl1_2;
  set mdl1;
  rtime = time_idx - 6;
run;
proc mixed data=mdl1_2  covtest noclprint empirical; *(where=(outlier_dma_ind=0)); 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 
      / solution outpred=pred_2  influence(iter=5 effect=dma est);
   RANDOM intercept / subject=dma s;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output influence=inf1 fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\MODEL_DATA\Explore_1\Influence Diagnostics\SelectedModel;
proc export data=inf1 outfile="&path\FMI_influence_diagnostics_v2.xls" dbms=excel97 replace; 
    sheet="raw_inf_diag"; 
run;

* Try removing DMA's 626, 798 and build model again;
* In dataset mdl1, the outliers 626, 798 were flagged (outlier_dma_ind=1) already;
proc means data=mdl1_2(where=(outlier_dma_ind=0));
var t1 - t24 mc_nrp lag_pnasnrx detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50  
        semS1 semS2 grpnas_50_semS1 grpnas_50_semS2;
run;
/*
Variable              N            Mean         Std Dev         Minimum         Maximum
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
mc_nrp             4992       0.8036493       0.0926593       0.4474321       0.9648734
lag_pnasnrx        4992      30.5007716      14.5936974       2.2549734     129.6236157
detmd_40           4992     528.4399872     313.1174777       0.8542778         1710.70
sammd_50           4992         3241.59         1409.21      60.6904871        10222.91
GRPOMN_70          4992     239.1301645      98.1865465      31.4704509     506.1831382
GRPOTC_60          4992         1109.16     690.8593859     180.3152425         3341.11
GRPNAS_50          4992     218.8687036     130.5433612       9.4235511     646.2445163
semS1              4992       0.5416667       0.4983108               0       1.0000000
semS2              4992       0.4583333       0.4983108               0       1.0000000
grpnas_50_semS1    4992     147.6041835     165.2160737               0     646.2445163
grpnas_50_semS2    4992      71.2645201     103.8620040               0     438.8991875
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
*/


proc mixed data=mdl1_2(where=(outlier_dma_ind=0))  covtest noclprint empirical; 
   class dma rtime;
   model pnasnrx = t1 - t24 mc_nrp lag_pnasnrx 
                   detmd_40 sammd_50 grpomn_70 grpotc_60 grpnas_50*semS1 grpnas_50*semS2 
      / solution outpred=pred_2 ;
   RANDOM intercept / subject=dma s;
   REPEATED rtime/ TYPE=SP(EXP)(RTIME) SUBJECT=dma rcorr;
   ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
  
  contrast 'nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256; * significant;
  contrast 'diff' grpnas_50*semS1 1 grpnas_50*semS2 -1; * significant;
  contrast 'wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256; * significant;

  estimate 'e_nas' grpnas_50*semS1 0.6744 grpnas_50*semS2 0.3256 / cl; 
  estimate 'e_diff' grpnas_50*semS1 1 grpnas_50*semS2 -1 / cl; 
  estimate 'e_wtddiff' grpnas_50*semS1 0.6744 grpnas_50*semS2 -0.3256 / cl; 
run;
 

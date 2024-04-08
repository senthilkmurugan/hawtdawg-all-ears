


/*******************************************************************
Try PROC LOESS for full model and get the response curve for tv_nsx_s60
1) Try to build full model using PROC LOESS and study the predicted nasnrx_pop vs. NAS Adstock.
   Also study the residuals from the full model.

2) Try proc mixed to account for some of the vars and then build proc loess to account for 
promotional variables. Plot pred. nasnrx_pop vs. NAS Adstock and residuals against NAS adstock.

********************************************************************/
* Build Scoring Dataset;
proc summary data=mm_model4c;
var lagnasnrx_pop /*spring fall3 dec tidx tidx_sq*/
              mar apr /*may jun jul aug*/ sep /*oct nov*/ dec /*jan*/
             pde_md_s30 smp_md_s80 vch_md_s50 evt_md_s50 
             tv_sng_s70  tv_nsx_s60 ; 
output out=sm_mdl_data_1 mean=;
run;
data score_data_mn(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 2200 by 25;
    tv_nsx_s60 = i;
    output;
  end;
run;
data score_data_zr(drop= _type_ _freq_ i);
  set sm_mdl_data_1;
  do i=0 to 2200 by 25;
    lagnasnrx_pop = 0; mar=0; apr=0; sep=0; dec=0; 
    pde_md_s30=0; smp_md_s80=0; vch_md_s50=0; evt_md_s50=0; 
    tv_sng_s70=0;    
    tv_nsx_s60 = i;
    output;
  end;
run;
/*
1) Try to build full model using PROC LOESS and study the predicted nasnrx_pop vs. NAS Adstock.
   Also study the residuals from the full model.
*/
*Use Local submit, since there are some memory issues in the server(error: out of memory);
proc loess data=uxwrk.mm_model4c; 
model nasnrx_pop = lagnasnrx_pop mar apr sep dec 
              pde_md_s30 smp_md_s80 vch_md_s50 evt_md_s50 
              tv_sng_s70  tv_nsx_s60 
       / smooth= 0.4 residual all;
      
	 score data=uxwrk.score_data_mn /*id=(smoothingparameter)*/ / clm;
	 ods output OutputStatistics=Results scoreresults=score_data_mn_out;
run;
proc means data=results; var residual; run; *mean 0.006, sd=4.65;

* here, exportscore_data_mn_out to excel;

symbol1 color=black value=dot;   
symbol2 color=black interpol=join value=none; 
symbol3 color=green interpol=join value=none; 
symbol4 color=green interpol=join value=none; 
%let opts=vaxis=axis1 hm=3 vm=3 overlay; 
axis1 label=(angle=90 rotate=0); 
proc gplot data=score_data_mn_out;  
 plot /*DepVar*tv_nsx_s60=1*/ P_nasnrx_pop*tv_nsx_s60=2 lcl_nasnrx_pop*tv_nsx_s60=3 ucl_nasnrx_pop*tv_nsx_s60=4  / &opts name='fit'; 
 *plot residual*tv_nsx_s60=2   / &opts name='fit'; 
run; quit;

%MACRO BOX_EQ_BIN_loess(dset,binvar,othvars,totrecs);
/*PROC GREPLAY NOFS IGOUT=WORK.GSEG; DELETE _ALL_; RUN; QUIT;*/
PROC SORT DATA=&dset. OUT=TSORTED; BY &binvar.; RUN;

DATA SORTED; SET TSORTED; *LRTIME=LOG(RTIME);
bin = ceil(10*_n_/&totrecs.);
RUN;
proc means data=sorted nolabels; class bin; var &binvar. &othvars. residual; run;

PROC SORT DATA=SORTED; BY bin; RUN; 
  TITLE3 "EXPLORE PA1N TOP-100 DMA DISTS";
  PROC BOXPLOT DATA=SORTED;
  AXIS1 LABEL=(ANGLE=90 ROTATE=0 "RESIDUAL");
  PLOT RESIDual*bin/TOTPANELS=1 VAXIS=AXIS1;
  LABEL MONTHLABEL='ANALYSIS MONTH';
  RUN; QUIT; TITLE3 ''; RUN;

%MEND BOX_EQ_BIN_loess;
%BOX_EQ_BIN_loess(results,tv_nsx_s60,,1800);
proc means data=sorted; class bin; var tv_nsx_s60 residual; run;



/*
2) Try proc mixed to account for some of the vars and then build proc loess to account for 
promotional variables. Plot pred. nasnrx_pop vs. NAS Adstock and residuals against NAS adstock.
*/

proc sort data=mm_model4c; by dma month; run;
proc mixed data=mm_model4c  COVTEST  ;
class dma month;
model nasnrx_pop = lagnasnrx_pop /*spring fall3 dec tidx tidx_sq*/
mar apr /*may jun jul aug*/ sep /*oct nov*/ dec /*jan*/
/*pde_md_s30 smp_md_s80 vch_md_s50 evt_md_s50 tv_sng_s70*/  /*tv_nsx_s60 tv_nsx_s60_sq2*/ /*logtvnsx60*/
   /solution ddfm=bw outp=mm_pred_4c;
random  int /*logtvnsx10*/
   /subject=dma type=un  gcorr s ;
/*parms /  lowerb=1e-4,.,1e-4 ;*/
repeated/type=ar(1)   subject=dma  ;
ods output fitstatistics=fit1 solutionf=fixed1 solutionr=random1;
run;


proc loess data=mm_pred_4c; 
model resid = /*lagnasnrx_pop mar apr sep dec */
              pde_md_s30 smp_md_s80 vch_md_s50 evt_md_s50 
              tv_sng_s70  tv_nsx_s60 
       / smooth= 0.4 residual all;
      
	 score data=score_data_mn /*id=(smoothingparameter)*/ / clm;
	 ods output OutputStatistics=Results scoreresults=score_data_mn_out;
run;
proc means data=results; var residual; run; *mean -0.18, sd=4.2;

%BOX_EQ_BIN_loess(uxwrk.results,tv_nsx_s60,,1800);
proc means data=sorted; class bin; var tv_nsx_s60 residual; run;





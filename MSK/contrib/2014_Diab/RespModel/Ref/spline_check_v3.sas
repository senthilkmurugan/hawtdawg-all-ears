/*
Check structures with various spline models (fixed knots)
*/
OPTIONS ls=80 ps=100 NOCENTER MLOGIC MPRINT SYMBOLGEN;
options compress=yes; 

LIBNAME musig 'C:\Documents and Settings\smuruga2\PROJECTS\CallPlan\PR_ROI\MuSigma\data\ModelStructure';  RUN;

/*data mdldata; set musig.procmixed_data; run;*/
data mdldata; set musig.mixed_data_new; run;
proc contents data=mdldata varnum; run;

data mdldata;
  set mdldata;
  samp_sq = samples*samples;
  int_det_sam = details*samples;
  int_lag_det_sam = mv_avg3_dettot*mv_avg3_samples;
  ln_sam = log(samples + 1);
  ln_det = log(details + 1);
  int_ln_det_sam = ln_sam*ln_det;
  samp_per_histjTRx_sq = samp_per_histjTRx*samp_per_histjTRx;
  * vars for spline modes;
  * assumptions: knots at samples = 6, 12, 18;
  * construct "+" (plus) functions as in Smith(1979) "Splines as a useful and convinient Statistical tool" The American Statistician;
  if samples <= 6 then do; pl1_sam = 0; pl1_sam_sq = 0; end;
  else do; pl1_sam = samples; pl1_sam_sq = samp_sq; end; 
  if samples <= 12 then do; pl2_sam = 0; pl2_sam_sq = 0; end;
  else do; pl2_sam = samples; pl2_sam_sq = samp_sq; end; 
  if samples <= 18 then do; pl3_sam = 0; pl3_sam_sq = 0; end;
  else do; pl3_sam = samples; pl3_sam_sq = samp_sq; end; 

run;

proc corr data=mdldata noprob; 
  var round_NRx refill_rate	samp_per_histjTRx sqrt_samples details
	month mv_avg3_samples mv_avg3_dettot mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty
	spec_typeSP samples samp_sq int_det_sam int_lag_det_sam
    ln_sam ln_det int_ln_det_sam
    pl1_sam pl1_sam_sq pl2_sam pl2_sam_sq pl3_sam pl3_sam_sq;
run;

proc sort data=mdldata; by seg gp_party_id month; run;
proc reg data=mdldata outest=reg_par_est;
by seg;
*proc reg data=mdldata(where=(seg="1HH")) outest=reg_par_est;
*where seg = "1HH";
where month ne 24;
p_NRx_0: model round_NRx = 
	refill_rate samp_per_histjTRx sqrt_samples mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_3: model round_NRx = 
	refill_rate samp_per_histjTRx sqrt_samples mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    details int_det_sam / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_5: model round_NRx = 
	refill_rate /*samp_per_histjTRx sqrt_samples*/ mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    samples samp_sq details int_det_sam / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_6: model round_NRx = 
    mv_avg3_NRx mv_avg3_mkttrx spec_typeSP month samples samp_sq details 
    int_det_sam / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_10: model round_NRx = 
	refill_rate /*samp_per_histjTRx sqrt_samples*/ mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    samples samp_sq 
    /*pl1_sam pl2_sam pl3_sam*/
    pl1_sam_sq pl2_sam_sq  pl3_sam_sq 
    / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_11: model round_NRx = 
	refill_rate /*samp_per_histjTRx sqrt_samples*/ mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    samples samp_sq 
    pl1_sam pl2_sam pl3_sam
    pl1_sam_sq pl2_sam_sq  pl3_sam_sq 
    / RSQUARE VIF COLLIN CLB ALPHA=0.05;
p_NRx_12: model round_NRx = 
	refill_rate /*samp_per_histjTRx sqrt_samples*/ mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    samples pl1_sam pl2_sam pl3_sam
    / RSQUARE VIF COLLIN CLB ALPHA=0.05;

run; quit;

*test proc orthoreg;
proc orthoreg data=mdldata outest=ortreg_par_est;
by seg;
*proc reg data=mdldata(where=(seg="1HH")) outest=reg_par_est;
*where seg = "1HH";
where month ne 24;
op_NRx_11: model round_NRx = 
	refill_rate /*samp_per_histjTRx sqrt_samples*/ mv_avg3_dettot month 
    mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    samples samp_sq 
    pl1_sam /*pl2_sam*/ /*pl3_sam*/
    pl1_sam_sq /*pl2_sam_sq*/  /*pl3_sam_sq*/; 
run; quit;

* try NLIN to find appropriate knot location (assume 1 knot);

proc nlin data=mdldata maxiter=1000;
  where seg = "1HH";
  parms intercept=3.438 e_refill_rate= -4.13
	e_mv_avg3_dettot= 0.000326
    e_month= -0.00981
    e_mv_avg3_samples= -0.00425
    e_mv_avg3_NRx= 0.742759
    e_mv_avg3_mkttrx= 0.005950
    e_mv_avg3_loyalty= -0.3267
    e_spec_typeSP= 0.0656
    e_samples= -0.0032
    e_samp_sq= 0.00144
    e_sam_plus1= 0.0132
    e_sam_plus1_sq= -0.00139
	knot=6
    ;
  sam_plus1 = max(samples - knot,0);
  sam_plus1_sq = sam_plus1*sam_plus1;
  model round_NRx = intercept + e_refill_rate*refill_rate
	+ e_mv_avg3_dettot*mv_avg3_dettot
    + e_month*month
    + e_mv_avg3_samples*mv_avg3_samples
    + e_mv_avg3_NRx*mv_avg3_NRx
    + e_mv_avg3_mkttrx*mv_avg3_mkttrx
    + e_mv_avg3_loyalty*mv_avg3_loyalty
    + e_spec_typeSP*spec_typeSP
    + e_samples*samples
    + e_samp_sq*samp_sq
    + e_sam_plus1*sam_plus1
    + e_sam_plus1_sq*sam_plus1_sq;
run;





/*
Build Score data set
*/
* Build Scoring Dataset;
proc summary data=mdldata /*data=mdldata(where=(seg="1HH"))*/;
by seg;
var round_NRx refill_rate mv_avg3_jTRx /*samp_per_histjTRx	sqrt_samples*/
	mv_avg3_dettot month mv_avg3_samples mv_avg3_NRx
	mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP 
    details int_lag_det_sam ln_sam ln_det int_ln_det_sam; 
output out=sm_mdldata mean=;
run;

data sm_mdldata_2(drop= _type_ _freq_ i);
  set sm_mdldata;
run;
%macro cr_score_data(seg);
  data tmp;
    set sm_mdldata_2;
	where seg = "&seg.";
    do i=0 to 24 by 0.25;
      samqty = i;
	  samples = i;
	  sqrt_samples = sqrt(i);
	  samp_per_histjTRx = i/mv_avg3_jTRx;
      samp_sq = i*i;
	  samp_per_histjTRx_sq = samp_per_histjTRx*samp_per_histjTRx;
      int_det_sam = details*i;
      ln_sam = log(samples + 1);
      int_ln_det_sam = ln_sam*ln_det;
      if samples <= 6 then do; pl1_sam = 0; pl1_sam_sq = 0; end;
      else do; pl1_sam = samples; pl1_sam_sq = samp_sq; end; 
      if samples <= 12 then do; pl2_sam = 0; pl2_sam_sq = 0; end;
      else do; pl2_sam = samples; pl2_sam_sq = samp_sq; end; 
      if samples <= 18 then do; pl3_sam = 0; pl3_sam_sq = 0; end;
      else do; pl3_sam = samples; pl3_sam_sq = samp_sq; end; 
      output;
    end;
  run;
  data score_data_mn; set score_data_mn tmp; run;
%mend cr_score_data;
data score_data_mn; set _null_; run;
%cr_score_data(1HH); 
%cr_score_data(1HM); %cr_score_data(1LM); %cr_score_data(1MH); %cr_score_data(1MM); 
%cr_score_data(2HH); %cr_score_data(2HM); %cr_score_data(2MH); %cr_score_data(2MM); 
%cr_score_data(3HH); %cr_score_data(3HM); %cr_score_data(3MM); 

data reg_par_est_2;
  set reg_par_est;
  _model_ = 'S'||trim(seg)||'_'|| trim(_model_);
run;
proc score data=score_data_mn score=reg_par_est_2 out=score_out_reg type=parms;
  var refill_rate samp_per_histjTRx	sqrt_samples mv_avg3_dettot
	/*details*/	month mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx
	mv_avg3_loyalty spec_typeSP
    int_lag_det_sam details int_det_sam samples samp_sq
    ln_sam ln_det int_ln_det_sam 
    pl1_sam pl1_sam_sq pl2_sam pl2_sam_sq pl3_sam pl3_sam_sq 
    samp_per_histjTRx_sq;
run;

%macro cr_score_out(seg,seg2);
  data tmp;
    set score_out_reg;
    where seg = "&seg.";
    retain p_nrx_ini_0 p_nrx_ini_3 p_nrx_ini_5 p_nrx_ini_6 
           p_nrx_ini_10 p_nrx_ini_11 p_nrx_ini_12;

    p_nrx_0 = &seg2._p_nrx_0; p_nrx_3 = &seg2._p_nrx_3; p_nrx_5 = &seg2._p_nrx_5;
	p_nrx_6 = &seg2._p_nrx_6; p_nrx_10 = &seg2._p_nrx_10; p_nrx_11 = &seg2._p_nrx_11;
	p_nrx_12 = &seg2._p_nrx_12;

    if _n_ = 1 then do;
      p_nrx_ini_0 = p_nrx_0; p_nrx_ini_3 = p_nrx_3; p_nrx_ini_5 = p_nrx_5;
	  p_nrx_ini_6 = p_nrx_6; p_nrx_ini_10 = p_nrx_10; p_nrx_ini_11 = p_nrx_11;
	  p_nrx_ini_12 = p_nrx_12; 
    end;
    p_incr_NRx_0 = p_nrx_0 - p_nrx_ini_0;
    p_incr_NRx_3 = p_nrx_3 - p_nrx_ini_3;
    p_incr_NRx_5 = p_nrx_5 - p_nrx_ini_5;
	p_incr_NRx_6 = p_nrx_6 - p_nrx_ini_6;
	p_incr_NRx_10 = p_nrx_10 - p_nrx_ini_10;
	p_incr_NRx_11 = p_nrx_11 - p_nrx_ini_11;
	p_incr_NRx_12 = p_nrx_12 - p_nrx_ini_12;
  run;
  /*data tmp; set tmp; drop &seg2.:; run;*/
  data score_out_reg_2; set score_out_reg_2 tmp; run;
%mend cr_score_out;
data score_out_reg_2; set _null_; run;
%cr_score_out(1HH,S1HH); 
%cr_score_out(1HM,S1HM); %cr_score_out(1LM,S1LM); %cr_score_out(1MH,S1MH); %cr_score_out(1MM,S1MM); 
%cr_score_out(2HH,S2HH); %cr_score_out(2HM,S2HM); %cr_score_out(2MH,S2MH); %cr_score_out(2MM,S2MM); 
%cr_score_out(3HH,S3HH); %cr_score_out(3HM,S3HM); %cr_score_out(3MM,S3MM); 

data score_out_reg_3; 
  set score_out_reg_2; 
  drop S1HH: S1HM: S1LM: S1MH: S1MM: S2HH: S2HM: S2MH: S2MM: S3HH: S3HM: S3MM:; 
run;











/* trials of ranges*/
proc univariate data=mdldata(where=(seg="1HH"));
  var mv_avg3_jTRx;
run;

/*
Try non-parametric models: PROC LOESS
*/
* Build Scoring Dataset;
proc summary data=mdldata(where=(seg="1HH"));
var round_NRx refill_rate mv_avg3_jTRx /*samp_per_histjTRx	sqrt_samples*/
	mv_avg3_dettot month mv_avg3_samples mv_avg3_NRx
	mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP; 
output out=sm_mdldata mean=;
run;
data score_data_mn(drop= _type_ _freq_ i);
  set sm_mdldata;
  do i=0 to 24 by 0.25;
    samqty = i;
	sqrt_samples = sqrt(i);
	samp_per_histjTRx = i/mv_avg3_jTRx;
    output;
  end;
run;

proc score data=score_data_mn score=reg_par_est out=score_out_reg type=parms;
  var refill_rate samp_per_histjTRx	sqrt_samples mv_avg3_dettot
	/*details*/	month mv_avg3_samples mv_avg3_NRx mv_avg3_mkttrx
	mv_avg3_loyalty spec_typeSP;
run;
data score_out_reg_2;
  set score_out_reg;
  retain pred_nrx_0;
  if _n_ = 1 then pred_nrx_0 = pred_nrx;
  pred_incr_NRx = pred_nrx - pred_nrx_0;
run;

* try proc loess;
proc loess data=mdldata(where=(seg="1HH")); 
model round_NRx = /*refill_rate*/ samp_per_histjTRx	sqrt_samples
	/*mv_avg3_dettot  month mv_avg3_samples mv_avg3_NRx
	mv_avg3_mkttrx mv_avg3_loyalty spec_typeSP*/ 
       / smooth= 0.8 residual all;
	 score data=score_data_mn /*id=(smoothingparameter)*/ / clm;
	 ods output OutputStatistics=Results scoreresults=score_nonpar_out;
run; 
proc means data=results; var residual; run; *mean 0.006, sd=4.65;







/* ********************************************************************************
7. Create Normalized Variables, Its adstocks and other Model Related Variables.
     Normalize Rx's using DMA target population (per 10K Target Population).
     Normalize Details, Samples and Vouchers using Rx MDs (per 1000 MDs).
     Compute adstocks for Normalized details, samples and vouchers.
     Add extra model vars like time, time_sq, time_cu, month indicators, quarters, 
     semester identifiers etc.,
******************************************************************************** */
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";
LIBNAME PREVGRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\PREV_study_mdl_data";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other;
OPTIONS NOCENTER MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. Get Normalized vars. Also get GRPOTC variable as combination of ALL, CLA, ZYR GRP's.
*/
proc contents data=rx.RX_PROMO_MC_MONGRP_ADSTK_V2 varnum; run;
data norm_rx_promo_1;
  set rx.RX_PROMO_MC_MONGRP_ADSTK_V2;
  drop det_: sam_: vcr_:;

  * get OTC TV GRP variable. OTC = ALL+CLA+ZYR;
  GRPOTC = GRPALL + GRPCLA + GRPZYR; 

  * population normalize Rx's based on target population (per 10K);
  PNASNRX = NASNRX * 10000 / POP_21_54;
  PMKTNRX = MKTNRX * 10000 / POP_21_54;
  PFLUNRX = FLUNRX * 10000 / POP_21_54;
  PVERNRX = VERNRX * 10000 / POP_21_54;
  POMNNRX = OMNNRX * 10000 / POP_21_54;
  PNASTRX = NASTRX * 10000 / POP_21_54;
  PMKTTRX = MKTTRX * 10000 / POP_21_54;
  PFLUTRX = FLUTRX * 10000 / POP_21_54;
  PVERTRX = VERTRX * 10000 / POP_21_54;
  POMNTRX = OMNTRX * 10000 / POP_21_54;

  * normalize details, samples and voucher/coupon redemptions using Rx MD's (per 1K);
  detmd = DET * 1000 / num_docs;
  sammd = SAM * 1000 / num_docs;
  vcrmd = VCR * 1000 / num_docs;
run;


/*
2. Compute Adstocks for normalized Details, Samples and Voucher/Coupon redemptions;
   Also add in GRPOTC adstocks.
*/
proc sort data=norm_rx_promo_1; by dma yearmo; run; 
DATA norm_rx_promo_2;
  SET norm_rx_promo_1;
  BY DMA;
  ARRAY arADSVARS(*) detmd sammd vcrmd GRPOTC;
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY arADS&HLLBL.(*) detmd_&HLLBL. sammd_&HLLBL. vcrmd_&HLLBL. GRPOTC_&HLLBL.;
    RETAIN arADS&HLLBL.;
    IF FIRST.DMA THEN DO;
      DO J=1 TO DIM(arADS&HLLBL.);
        arADS&HLLBL.(J) = arADSVARS(J);
      END;
    END;
    ELSE DO;
	  DO J=1 TO DIM(arADS&HLLBL.);
	    arADS&HLLBL.(J) = arADSVARS(J) + &DECAY.*arADS&HLLBL.(J);
	  END;
    END;
  %MEND;
  %ADSTK1(0.1,10); %ADSTK1(0.2,20); %ADSTK1(0.3,30); %ADSTK1(0.4,40);
  %ADSTK1(0.5,50); %ADSTK1(0.6,60); %ADSTK1(0.7,70); %ADSTK1(0.75,75);
  %ADSTK1(0.8,80); %ADSTK1(0.85,85); %ADSTK1(0.9,90);
  DROP J;
RUN;

/*
3. Get log vars. May be used in the modeling.
   Also get lag vars.
*/
proc sort data=norm_rx_promo_2; by dma yearmo; run; 
DATA norm_rx_promo_3;
  SET norm_rx_promo_2;
  BY DMA;
  array num _numeric_;
  do over num;
    if num=. then num=0;
  end;
  * set all negative voucher coupon redemptions to 0;
  array arVCR vcrmd:;
  do over arVCR;  if arVCR < 0 then arVCR=0;  end;

  %macro defvars(prfx);
       &prfx. &prfx._10 &prfx._20 &prfx._30 &prfx._40 &prfx._50 &prfx._60 &prfx._70
             &prfx._75 &prfx._80 &prfx._85 &prfx._90 
  %mend defvars;
  ARRAY arORIGVARS(*) pnasnrx pmktnrx pflunrx hh_avg_income pop_21_54 
        %defvars(detmd) %defvars(sammd) %defvars(vcrmd)
        %defvars(grpnas) %defvars(grpomn) %defvars(grpotc)
        %defvars(grpadv) ;  
  ARRAY arLOGVARS(*) logpnasnrx logpmktnrx logpflunrx loghh_avg_income logpop_21_54 
        %defvars(logdetmd) %defvars(logsammd) %defvars(logvcrmd)
        %defvars(loggrpnas) %defvars(loggrpomn) %defvars(loggrpotc)
        %defvars(loggrpadv) ;  
  DO J=1 TO DIM(arLOGVARS);
    arLOGVARS(J) = log(arORIGVARS(J)+1);
  END; 


  * lags of sammd, pnasnrx and their logs; 
  %macro glags(prfx);
     lag1&prfx. = lag(&prfx.);
     lag2&prfx. = lag2(&prfx.);
  %mend glags;
  %glags(sammd); %glags(sammd_10); %glags(sammd_20); %glags(sammd_30); %glags(sammd_40); 
  %glags(sammd_50); %glags(sammd_60); %glags(sammd_70); %glags(sammd_75); %glags(sammd_80);
  %glags(sammd_85); %glags(sammd_90);  
  %glags(logsammd); %glags(logsammd_10); %glags(logsammd_20); %glags(logsammd_30); %glags(logsammd_40); 
  %glags(logsammd_50); %glags(logsammd_60); %glags(logsammd_70); %glags(logsammd_75); %glags(logsammd_80);
  %glags(logsammd_85); %glags(logsammd_90);  
  
  *lag of pnasnrx;
  lag_pnasnrx = lag(pnasnrx); lag_logpnasnrx = lag(logpnasnrx);

  * remove recs with incorrect lags;
  lagdma=lag(dma);
  lag2dma=lag2(dma);
  if lagdma^=dma then delete;

RUN;

/*
4. Add in other model variables;
*/
data norm_rx_promo_4;
  set norm_rx_promo_3;
  * get square terms for nasonex adstocks;
  %macro sqrs(prfx);
     &prfx._sq = &prfx. * &prfx.;
  %mend sqrs;
  %sqrs(grpnas); %sqrs(grpnas_10); %sqrs(grpnas_20); %sqrs(grpnas_30); %sqrs(grpnas_40);
  %sqrs(grpnas_50); %sqrs(grpnas_60); %sqrs(grpnas_70); %sqrs(grpnas_75); %sqrs(grpnas_80);
  %sqrs(grpnas_85); %sqrs(grpnas_90);

  * time square and cube terms;
  time_idx_sq = time_idx * time_idx;
  time_idx_cu = time_idx_sq * time_idx;
  * get quarters;
  q1=0; q2=0; q3=0; q4=0;
  tmp = substr(yearmo,5,2);
  tmp2 = substr(yearmo,1,4);
  if tmp in ('01' '02' '03') then q1 = 1;
  else if tmp in ('04' '05' '06') then q2 = 1;
  else if tmp in ('07' '08' '09') then q3 = 1;
  else if tmp in ('10' '11' '12') then q4 = 1;
  *assign semesters;
  length SEMESTER $7.;
  if (q1+q2 > 0) then SEMESTER=trim(left(tmp2))||"_S1";
  else if (q3+q4 > 0) then SEMESTER=trim(left(tmp2))||"_S2";
  if SEMESTER = "2011_S2" then SEMESTER = "2011_S1"; * mark one S2 month in 2011 as S1 of 2011.;
  * get months;
  jan=0; feb=0; mar=0; apr=0; may=0; jun=0; 
  jul=0; aug=0; sep=0; oct=0; nov=0; dec=0;
  if tmp = '01' then jan=1;   if tmp = '02' then feb=1;
  if tmp = '03' then mar=1;   if tmp = '04' then apr=1;
  if tmp = '05' then may=1;   if tmp = '06' then jun=1;
  if tmp = '07' then jul=1;   if tmp = '08' then aug=1;
  if tmp = '09' then sep=1;   if tmp = '10' then oct=1;
  if tmp = '11' then nov=1;   if tmp = '12' then dec=1;
  drop tmp tmp2;
  * assign special events;
  * 1. Fluticasone shortage;
  flut_short_ind = 0;
  if yearmo in ("201004","201005") then flut_short_ind = 1;
  * 2. Generic allegra OTC;
  gen_all_launch = 0;
  if yearmo >= "201103" then gen_all_launch = 1;
run;

/*
5. Mark 101 DMA's used in previous study (prev_study_dma_ind = 1)
*/
proc sort data=prevgrp.mm_mdl4 out=prev_dmas(keep=dma) nodupkey; by dma; run;
proc sort data=norm_rx_promo_4; by dma yearmo; run;
data norm_rx_promo_5;
  merge norm_rx_promo_4(in=a) prev_dmas(in=b);
  by dma;
  if a;
  prev_study_dma_ind = 0;
  if b then prev_study_dma_ind = 1;
run;
proc sql;
  select prev_study_dma_ind, count(distinct dma) as count from norm_rx_promo_5
  group by prev_study_dma_ind;
quit; * 101 previous study DMA's have been marked successfully;


/*
6. Retain model data only for 24 months.
*/
data norm_rx_promo_6;
  set norm_rx_promo_5;
  if yearmo < "200908" then delete; * retain from Aug 2009 to Jul 2011.;
run;

/* * Store as permanent dataset;
DATA rx.MODEL_DATA_v1; SET norm_rx_promo_6; RUN;
*/

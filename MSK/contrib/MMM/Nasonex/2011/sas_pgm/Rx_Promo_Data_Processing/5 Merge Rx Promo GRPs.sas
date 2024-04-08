***************************************************************************;
* 5. Merge Rx, MgdCare, Details, Samples, and GRPs datasets.               ;
*    Adstocks have been already computed for Details, Samples, GRPs        ;
*    Data is organized by DMA x YEARMO for 30 months                       ;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRP "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing\OUTPUT";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. Merge DMA Population and Income to Rx dataset.
*/
proc sql noprint;
create table rx_pop as 
select a.DMA, a.YEARMO, a.TIME_IDX, 
       a.NASNRX, a.MKTNRX, a.NASTRX, a.MKTTRX, a.DET, a.SAM, a.num_docs,
       b.pop_total as POP_TOTAL, b.pop_21_54 as POP_21_54, 
	   b.hh_count as HH_COUNT, b.hh_avg_income as HH_AVG_INCOME, 
	   a.DET_10, a.DET_20, a.DET_30, a.DET_40, a.DET_50, 
       a.DET_60, a.DET_70, a.DET_75, a.DET_80, a.DET_85, a.DET_90, 
	   a.SAM_10, a.SAM_20, a.SAM_30, a.SAM_40, a.SAM_50, 
       a.SAM_60, a.SAM_70, a.SAM_75, a.SAM_80, a.SAM_85, a.SAM_90 
from rx.rx_det_sam_adstk a, rx.pop_income_dma b
where a.dma = b.dma;
quit;

/*
2. Merge Rx dataset with Mgd. Care dataset.
   Note: Mgd care dataset does not vary over time as it is the most latest snap shot.
*/
proc sql noprint;
create table rx_mc as 
select a.DMA, a.YEARMO, a.TIME_IDX, 
       a.NASNRX, a.MKTNRX, a.NASTRX, a.MKTTRX, a.DET, a.SAM, a.num_docs,
       a.POP_TOTAL, a.POP_21_54, a.HH_COUNT, a.HH_AVG_INCOME, 
       b.rp as mc_rp, b.nrp as mc_nrp, b.offp as mc_offp,
	   a.DET_10, a.DET_20, a.DET_30, a.DET_40, a.DET_50, 
       a.DET_60, a.DET_70, a.DET_75, a.DET_80, a.DET_85, a.DET_90, 
	   a.SAM_10, a.SAM_20, a.SAM_30, a.SAM_40, a.SAM_50, 
       a.SAM_60, a.SAM_70, a.SAM_75, a.SAM_80, a.SAM_85, a.SAM_90 
from rx_pop a, rx.mgdcare_dma b
where a.dma = b.dma;
quit;

/*
3. Merge Voucher Coupon Redemptions Adstocks.
*/ 
proc sort data=rx_mc; by dma yearmo; run;
proc sort data=rx.vcr_adstk out=vcr_adstk(drop=inset); by dma yearmo; run;
data rx_mc_vcr;
  merge rx_mc(in=a) vcr_adstk(in=b);
  by dma yearmo;
  if a;
run;

/*
4. Merge Competitor RX dataset with rx_mc. For missing months let the competitor Rx be null.
*/ 
proc sort data=rx_mc_vcr; by dma yearmo; run;
proc sort data=rx.comp_rx_dma_yearmo out=comp_rx_dma_yearmo; by dma yearmo; run;
data rx_mc_vcr_comp;
  merge rx_mc_vcr(in=a) comp_rx_dma_yearmo(in=b drop=time_idx);
  by dma yearmo;
  if a;
run;

/*
6. Get work days;
*/
* define holidays. This would be used to get proper count of work days;
* note: 2007 holidays ignored as 2007 will be dropped later in the analysis;
%MACRO HOLIDAYS (ARRAY=HOLIDAY);
     &ARRAY(36) _TEMPORARY_ 
		("01JAN2009"D "19JAN2009"D "25MAY2009"D "03JUL2009"D "07SEP2009"D
         "26NOV2009"D "27NOV2009"D "24DEC2009"D "25DEC2009"D 
		 "01JAN2010"D "18JAN2010"D "31MAY2010"D "05JUL2010"D "06SEP2010"D 
         "25NOV2010"D "26NOV2010"D "23DEC2010"D "24DEC2010"D 
		 "03JAN2011"D "17JAN2011"D "30MAY2011"D "04JUL2011"D "05SEP2011"D 
         "24NOV2011"D "25NOV2011"D "23DEC2011"D "26DEC2011"D 
         "02JAN2012"D "16JAN2012"D "28MAY2012"D "04JUL2012"D "03SEP2012"D 
         "22NOV2012"D "23NOV2012"D "24DEC2012"D "25DEC2012"D
          )
%MEND  HOLIDAYS ;
data rx_mc_vcr_comp_2;
  set rx_mc_vcr_comp;
  * get days in a month;
  som = MDY(substr(yearmo,5,2)*1,1,substr(yearmo,1,4)*1); *gets first day of the month;
  eom = intnx('month',som,0,'end'); *gets last day of the month;
  days_in_month = day(eom); *gets number of days in the month;
  
  * get weekdays in a month;
  if 1 < weekday(som) < 7 then startx=som-1; else startx=som;
  weekdays = intck('weekday',startx,eom);

  *get workdays in a month;
  ARRAY %HOLIDAYS();
  workdays = weekdays;
  DO i = 1 TO DIM ( HOLIDAY ) ;
       workdays = workdays - ( WEEKDAY(HOLIDAY(I)) NOT IN (7 1)
                    AND som <= HOLIDAY(I) <= eom ) ;
  END ;
  drop som eom days_in_month weekdays startx i;
run;

/*
7. Merge RX_MC dataset with GRP Adstocks by DMA and YEARMO
*/
proc sort data=rx_mc_vcr_comp_2; by dma yearmo; run;
proc sort data=grp.adstk_aggr_by_month out=adstk_aggr_by_month; by dma yearmo; run;
data rx_mc_vcr_comp_grp;
  merge rx_mc_vcr_comp_2(in=a) adstk_aggr_by_month(in=b);
  by dma yearmo;
  drop MM_NRADNAS: MM_NINTNAS: MM_NOTHNAS: NUM_FULL_WEEKS;
run;

/* * Store as permanent dataset;
DATA rx.RX_PROMO_MC_WKLYGRP_ADSTK_V1; SET rx_mc_vcr_comp_grp; RUN;
*/

/*
8. Merge RX_MC dataset with GRP Adstocks by DMA and YEARMO
*/
proc sort data=rx_mc_vcr_comp_2; by dma yearmo; run;
proc sort data=grp.ads_by_unit_month out=ads_by_unit_month; by dma yearmo; run;
data rx_mc_vcr_comp_mongrp;
  merge rx_mc_vcr_comp_2(in=a) ads_by_unit_month(in=b);
  by dma yearmo;
  drop MM_NRADNAS: MM_NINTNAS: MM_NOTHNAS:;
run;

/* * Store as permanent dataset;
DATA rx.RX_PROMO_MC_MONGRP_ADSTK_V1; SET rx_mc_vcr_comp_mongrp; RUN;
*/



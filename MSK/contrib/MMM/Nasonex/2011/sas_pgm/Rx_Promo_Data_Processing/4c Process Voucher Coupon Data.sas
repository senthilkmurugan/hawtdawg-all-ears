******************************************************************************;
* 4b. Import Voucher and Coupon data provided by SAM Help Desk Team           ;
******************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRAIL "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\Grail";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\VCH_COU;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. Import Coupon and Voucher Data;
*/
data WORK.IN_VCH;
  infile "&PATH\redem.txt"
  delimiter='09'x MISSOVER DSD lrecl=32767;
   informat PRODUCT $7. ZIP9 $10. MONTH_YEAR MONYY. CLAIM_TYPE_CD $3. VCHR_COUNT best32.;
   format PRODUCT $7. ZIP9 $10. MONTH_YEAR MONYY. CLAIM_TYPE_CD $3. VCHR_COUNT best32.;
   input PRODUCT $ ZIP9 $ MONTH_YEAR CLAIM_TYPE_CD $ VCHR_COUNT;
   length ZIP_CODE $5. YEARMO $6. vch_redemption 8;
   if LENGTH(TRIM(LEFT(ZIP9))) < 5 then ZIP_CODE = put(1*TRIM(LEFT(ZIP9)),Z5.);
   else ZIP_CODE = SUBSTR(TRIM(LEFT(ZIP9)),1,5);
   YEARMO = put(MONTH_YEAR,yymmn6.);
   if claim_type_cd = "+" then vch_redemption = VCHR_COUNT; 
   else if claim_type_cd = "R5" then vch_redemption = -1*VCHR_COUNT; 
   else vch_redemption = .;
run;
*QA;
data tst; set IN_VCH; if (vch_redemption = . or zip_code = "" or YEARMO = ""); run; * 0 Obs.;
proc means data=in_vch sum nway;
  class claim_type_cd;  var vchr_count vch_redemption;
run; * matches for each claim_type_cd;

data WORK.IN_COU;
  infile "&PATH\cleaned_redem_1.txt"
  delimiter='09'x MISSOVER lrecl=32767; * note: DSD option is removed for this file alone;
   informat PRODUCT $7. ZIP9 $10. MONTH_YEAR MONYY. CLAIM_TYPE_CD $3. COUP_COUNT best32.;
   format PRODUCT $7. ZIP9 $10. MONTH_YEAR MONYY. CLAIM_TYPE_CD $3. COUP_COUNT best32.;
   input PRODUCT $ ZIP9 $ MONTH_YEAR CLAIM_TYPE_CD $ COUP_COUNT;
   length ZIP_CODE $5. YEARMO $6. cou_redemption 8;
   if LENGTH(TRIM(LEFT(ZIP9))) < 5 then ZIP_CODE = put(1*TRIM(LEFT(ZIP9)),Z5.);
   else ZIP_CODE = SUBSTR(TRIM(LEFT(ZIP9)),1,5);
   YEARMO = put(MONTH_YEAR,yymmn6.);
   if claim_type_cd = "P" then cou_redemption = COUP_COUNT; 
   else if claim_type_cd = "X" then cou_redemption = -1*COUP_COUNT; 
   else cou_redemption = .;
run;
*QA;
data tst; set IN_COU; if (cou_redemption = . or zip_code = "" or YEARMO = ""); run; * 0 Obs.;
proc means data=in_cou sum nway;
  class claim_type_cd;  var coup_count cou_redemption;
run; * matches for each claim_type_cd;


/*
2. Aggregate to ZIP and then DMA level;
*/
proc means data=in_vch sum noprint nway;
  class zip_code yearmo;
  var vch_redemption;
  output out=zip_vch(drop=_type_ _freq_) sum=;
run;
proc sql; select sum(vch_redemption) from zip_vch; quit;
data zip_vch; set zip_vch;
  if yearmo < '200902' or yearmo > '201107' then delete;
run;

proc means data=in_cou sum noprint nway;
  class zip_code yearmo;
  var cou_redemption;
  output out=zip_cou(drop=_type_ _freq_) sum=;
run;
proc sql; select sum(cou_redemption) from zip_cou; quit;
data zip_cou; set zip_cou;
  if yearmo < '200902' or yearmo > '201107' then delete;
run;

* Merge both voucher and coupon dataset;
proc sort data=zip_vch; by zip_code yearmo; run;
proc sort data=zip_cou; by zip_code yearmo; run;
data zip_vch_cou;
  merge zip_cou(in=a) zip_vch(in=b);
  by zip_code yearmo;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
  vcr = vch_redemption + cou_redemption;
  keep zip_code yearmo vch_redemption cou_redemption vcr;
  rename vch_redemption = vch_rdm cou_redemption = cou_rdm;
run;
proc sql;
  select sum(vch_rdm), sum(cou_rdm), sum(vcr) from zip_vch_cou;
quit; * counts matches;

*merge to get DMA;
proc sort data=dma.zip_to_dma_2011zips_deduped out=zip_to_dma; by zip_code; run;
proc sort data=zip_vch_cou; by zip_code; run;
data dma_zip_vch_cou;
  merge zip_to_dma(in=a keep=zip_code dma) zip_vch_cou(in=b);
  by zip_code;
  inset=10*a+b;
  if a and b; 
run;
proc freq data=dma_zip_vch_cou; tables inset / list missing; run; 
data test;  set dma_zip_vch_cou; if inset=1; run;
*99.1% of recs in zip_vch_cou matched to zip_to_dma xref;

* aggregate by dma;
proc means data=dma_zip_vch_cou sum noprint nway;
  class dma yearmo;
  var vch_rdm cou_rdm vcr;
  output out=dma_vch_cou(drop=_type_ _freq_) sum=;
run;
proc sql;
  select sum(vch_rdm), sum(cou_rdm), sum(vcr) from dma_vch_cou;
quit; * 0.6% total redemptions lost during matching.;

/*
* Store as permanent dataset;
data rx.vch_cou_dma_yearmo; set dma_vch_cou; run;
*/

/*
3. Compute Adstocks for Total Redemptions (vcr);
*/
* Integrate with all dma X yearmo combinations;
proc sort data=rx.RX_DET_SAM_ADSTK out=ref_tbl(keep=dma yearmo) nodupkey; by dma yearmo; run;
proc sort data=dma_vch_cou; by dma yearmo; run; 
data dma_vch_cou_2;
  merge ref_tbl(in=a) dma_vch_cou(in=b);
  by dma yearmo;
  inset = 10*a+b;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
run;
proc freq data=dma_vch_cou_2; tables inset / list missing; run;

*compute adstock;
proc sort data=dma_vch_cou_2; by dma yearmo; run; 
DATA VCR_ADSTK;
  SET dma_vch_cou_2;
  BY DMA;
  ARRAY arADSVARS(*) VCR;
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY arADS&HLLBL.(*) VCR_&HLLBL.;
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
* Store as permanent dataset;
DATA rx.VCR_ADSTK; SET VCR_ADSTK; RUN;
*/


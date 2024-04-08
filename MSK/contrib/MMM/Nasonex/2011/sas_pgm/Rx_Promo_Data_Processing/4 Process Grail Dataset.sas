***************************************************************************;
* 4. Process Grail dataset to get 30 months of Rx, details, mfp, sfp, samples ;
* 24 months from Nasonex July 2011 Grail and selected 6 months from Jan 2011 grail;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRAIL "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\Grail";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. Get Grail data for 30 months by zip code. 
   For Time Period: Aug/2009 to Jul/2011, use July 2011 Nasonex Grail: Nasonex_grail1107.
   For Time Period: Feb/2009 to Jun/2009, 
            use Jan 2011 Nasonex Grail(indexed 18 to 24): Nasonex_grail1101.
   Note: This period covers both LSP and Merck Field Forces. 
         Details during LSP period were all captured as dettot and not separately 
           by SFP and MFP. Hence, get all details into one field.; 
*/
* 24 months - Aug2009(index=24) to July2011(index=1). File: grail.nasonex_grail1107;
data grail1;
  set grail.nasonex_grail1107(keep=imsdrnum sfp: mfp: dettot: samtot: 
                   a1n: a1t: an: at: spec zip);
  array arDET(24) DET1 - DET24; array arSFP(24) sfp1 - sfp24; 
  array arMFP(24) mfp1 - mfp24; array arDETTOT(24) dettot1 - dettot24;
  array arSAM(24) SAM1 - SAM24; array arSAMTOT(24) samtot1 - samtot24;
  do i =1 to 24; 
    arDET(i) = SUM(of arSFP(i) arMFP(i) arDETTOT(i));
    arSAM(i) = SUM(of arSAMTOT(i));
  end;
  keep imsdrnum spec zip a1n: an: a1t: at: det1 - det24 sam1 - sam24;
run;
/*data rx.raw_grail_1_to_24; set grail1; run;*/
proc means data=grail1 sum noprint nway;
  class zip;
  var a1n: an: a1t: at: det1 - det24 sam1 - sam24;
  output out=zip_grail1(drop=_type_ rename=(_freq_=num_docs)) sum=;
run;

* 6 months - Feb2009(index=24) to July2009(index=19). File: grail.nasonex_grail1101;
data grail2;
  set grail.nasonex_grail1101(keep=imsdrnum sfp19 - sfp24 mfp19 - mfp24 
                    dettot19 - dettot24  samtot19 - samtot24  
                   a1n19 - a1n24 a1t19 - a1t24 an19 - an24 at19 - at24 spec zip);
  array arDET(6) DET25 - DET30; 
  array arSAM(6) SAM25 - SAM30;
  array arSFP(6) sfp19 - sfp24; array arMFP(6) mfp19 - mfp24; 
  array arDETTOT(6) dettot19 - dettot24; array arSAMTOT(6) samtot19 - samtot24;
  do i =1 to 6; 
    arDET(i) = SUM(of arSFP(i) arMFP(i) arDETTOT(i));
    arSAM(i) = SUM(of arSAMTOT(i));
  end;
  keep imsdrnum spec zip a1n: an: a1t: at: det25 - det30 sam25 - sam30;

  reNAme A1N19 = A1N25    A1N20 = A1N26    A1N21 = A1N27 
         A1N22 = A1N28    A1N23 = A1N29    A1N24 = A1N30 
         AN19 = AN25      AN20 = AN26      AN21 = AN27 
         AN22 = AN28      AN23 = AN29      AN24 = AN30;

  reNAme A1T19 = A1T25    A1T20 = A1T26    A1T21 = A1T27 
         A1T22 = A1T28    A1T23 = A1T29    A1T24 = A1T30 
         AT19 = AT25      AT20 = AT26      AT21 = AT27 
         AT22 = AT28      AT23 = AT29      AT24 = AT30; 
run;
/*data rx.raw_grail_25_to_30; set grail2; run;*/
proc means data=grail2 sum noprint nway;
  class zip;
  var a1n: an: a1t: at: det: sam:;
  output out=zip_grail2(drop=_type_ _freq_) sum=;
run;

* Merge both grail datasets to get 30 months metrics by zip code;
proc sort data=zip_grail1; by zip; run;
proc sort data=zip_grail2; by zip; run;
data zip_grail_all;
  merge zip_grail1(in=a) zip_grail2(in=b);
  by zip;
  inset=10*a+b;
run;
proc freq data=zip_grail_all; tables inset / list missing; run; *94% match between two files;

data zip_grail_all(rename=(zip=zip_code));
  set zip_grail_all;
  array num _numeric_; do over num;  if num=. then num=0;  end; * SET ALL NULL NUMBERS TO 0;
run;

/*
2. Merge and Aggregate zip level data to DMA.
*/
*merge to get DMA;
proc sort data=dma.zip_to_dma_2011zips_deduped out=zip_to_dma; by zip_code; run;
proc sort data=zip_grail_all; by zip_code; run;
data dma_zip_grail_all;
  merge zip_to_dma(in=a keep=zip_code dma) zip_grail_all(in=b);
  by zip_code;
  inset=10*a+b;
  if a and b; 
run;
proc freq data=dma_zip_grail_all; tables inset / list missing; run; 
data test;  set dma_zip_grail_all; if inset=1; run;
*99.7% of recs in zip_grail_all matched to zip_to_dma xref;

* aggregate by dma;
proc means data=dma_zip_grail_all sum noprint nway;
  class dma;
  var num_docs a1n: an: a1t: at: det: sam:;
  output out=dma_grail_all(drop=_type_ _freq_) sum=;
run;


/*
3. Transpose the dma_grail to DMA x Yearmo structure.
*/
data tr_dma_grail;
  set dma_grail_all;
  length YEARMO $6. time_idx NASNRX MKTNRX NASTRX MKTTRX DET SAM 8;
  ref_date = MDY(7,1,2011); *July 2011 is the latest date;
  array ar_a1n {*} a1n1 - a1n30;
  array ar_an {*} an1 - an30;
  array ar_a1t {*} a1t1 - a1t30;
  array ar_at {*} at1 - at30;
  array ar_det {*} det1 - det30;
  array ar_sam {*} sam1 - sam30;
  do i=1 to 30;
    time_idx = 31 - i;
    yearmo_date = intnx('month',ref_date,1-i,'beginning');
	YEARMO = put(yearmo_date,yymmn6.);
    NASNRX = ar_a1n(i);
    MKTNRX = ar_an(i);
    NASTRX = ar_a1t(i);
    MKTTRX = ar_at(i);
    DET = ar_det(i);
    SAM = ar_sam(i);
    output;
  end;
  drop a1n1 - a1n30  an1 - an30  a1t1 - a1t30  at1 - at30  det1 - det30  sam1 - sam30;
  drop ref_date i yearmo_date;
run;

*QA;
data tst1(keep = tot_:);
  set dma_zip_grail_all;
  tot_a1n = SUM(OF a1n:); tot_an = SUM(OF an:); tot_a1t = SUM(OF a1t:); 
  tot_at = SUM(OF at:); tot_det = SUM(OF det:); tot_sam = SUM(OF sam:); 
run;
proc means data=tst1 sum noprint nway;
  var tot_:;  output out=tst1b(drop=_type_ _freq_) sum=;
run;
proc means data=tr_dma_grail sum noprint nway;
  var nasnrx mktnrx nastrx mkttrx det sam;  output out=tst2b(drop=_type_ _freq_) sum=;
run;
*both tst1a and tst1b matches. Transpose is fine.;

/*
* Store as permanent dataset;
data rx.grail_dma_yearmo; set tr_dma_grail; run;
*/

/*
4. Compute Adstocks for Details and Samples;
*/
proc sort data=tr_dma_grail; by dma yearmo; run; 
DATA RX_DET_SAM_ADSTK;
  SET tr_dma_grail;
  BY DMA;
  ARRAY arADSVARS(*) DET SAM;
  %MACRO ADSTK1(DECAY,HLLBL);
    ARRAY arADS&HLLBL.(*) DET_&HLLBL. SAM_&HLLBL.;
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
DATA rx.RX_DET_SAM_ADSTK; SET RX_DET_SAM_ADSTK; RUN;
*/



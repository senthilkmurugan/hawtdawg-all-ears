******************************************************************************;
* 4b. Extract Competitor Rxs for Fluticasone Propionate, Veramyst and Omnaris ;
*    Data is available for 24 months. Extracted by Blythe.                    ;
******************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";
LIBNAME GRAIL "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\Grail";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

/*
1. Get Zip codes for competitor Rx data from July Grail dataset.
   Retain only IMSDRNNUM found in NAS Grail, so as to have same base.
*/
proc sort data=grail.nasonex_grail1107(keep=imsdrnum zip) out=nasgr1; by imsdrnum; run;
proc sort data=grail.competitor_m1107 out=comp_rx1 nodupkey; by imsdrnum; run; * 0 dupes;
data comp_rx2;
  merge nasgr1(in=a) comp_rx1(in=b) ;
  by imsdrnum;
  if a and b;
  *inset=10*a+b;
run;
/*proc freq data=comp_rx2; tables inset / list missing; run;*/
*95% in NAS Grail matches with Competitor Rx file;

proc means data=comp_rx2(keep=imsdrnum zip flu: ver: omn:) sum noprint nway;
  class zip;
  var flu: ver: omn:;
  output out=zip_comp_rx(drop=_type_ _freq_) sum=;
run;

/*
2. Merge and Aggregate zip level data to DMA.
*/
*merge to get DMA;
proc sort data=dma.zip_to_dma_2011zips_deduped out=zip_to_dma; by zip_code; run;
proc sort data=zip_comp_rx out=zip_comp_rx(rename=(zip=zip_code)); by zip; run;
data dma_zip_comp_rx;
  merge zip_to_dma(in=a keep=zip_code dma) zip_comp_rx(in=b);
  by zip_code;
  inset=10*a+b;
  if a and b; 
run;
proc freq data=dma_zip_comp_rx; tables inset / list missing; run; 
data test;  set dma_zip_comp_rx; if inset=1; run;
*99.7% of recs in zip_comp_rx matched to zip_to_dma xref;

* aggregate by dma;
proc means data=dma_zip_comp_rx sum noprint nway;
  class dma;
  var flu: ver: omn:;
  output out=dma_comp_rx(drop=_type_ _freq_) sum=;
run;

/*
3. Transpose the dma_comp_rx to DMA x Yearmo structure.
*/
data tr_dma_comp_rx;
  set dma_comp_rx;
  length YEARMO $6. time_idx FLUNRX VERNRX OMNNRX FLUTRX VERTRX OMNTRX 8;
  ref_date = MDY(7,1,2011); *July 2011 is the latest date;
  array ar_flun {*} flunrx1 - flunrx24;
  array ar_vern {*} vernrx1 - vernrx24;
  array ar_omnn {*} omnnrx1 - omnnrx24;
  array ar_flut {*} flutrx1 - flutrx24;
  array ar_vert {*} vertrx1 - vertrx24;
  array ar_omnt {*} omntrx1 - omntrx24;
  do i=1 to 24;
    time_idx = 25 - i;
    yearmo_date = intnx('month',ref_date,1-i,'beginning');
	YEARMO = put(yearmo_date,yymmn6.);
    FLUNRX = ar_flun(i);   VERNRX = ar_vern(i);   OMNNRX = ar_omnn(i);
	FLUTRX = ar_flut(i);   VERTRX = ar_vert(i);   OMNTRX = ar_omnt(i);
    output;
  end;
  drop flunrx1 - flunrx24   vernrx1 - vernrx24   omnnrx1 - omnnrx24  
       flutrx1 - flutrx24   vertrx1 - vertrx24   omntrx1 - omntrx24;  
  drop ref_date i yearmo_date;
run;

/*
* Store as permanent dataset;
data rx.comp_rx_dma_yearmo; set tr_dma_comp_rx; run;
*/



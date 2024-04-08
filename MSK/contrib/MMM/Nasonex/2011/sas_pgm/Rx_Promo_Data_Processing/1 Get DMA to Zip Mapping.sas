***************************************************************************;
* 1. Process DMA to Zip file and QA                                        ;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\Nielsen_DMA_to_Zip;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

* 1. Import Nielsen Zip to DMA file (2011);
PROC IMPORT OUT=WORK.IN_ZIPDMA
  DATAFILE="&PATH.\DMABYZIP1011.XLS" DBMS=EXCEL REPLACE; 
  SHEET="2010_NSI_DMABYZIP"; GETNAMES=NO; RANGE="A3:M50828";
  MIXED=YES; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;
data in_zipdma_2;
  set in_zipdma;
  length zip_code $5. dma $3. dma_name $26. state $2. city $13. city_size 8 dma_rank $3. metro_ind $1. ;
  zip_code = F1; dma = F2; dma_name = F3; state = F7; city = F8; city_size = F9; 
  dma_rank = F12; metro_ind = F13;
  drop F1 - F13;
run;

/* Check the dma codes with dma codes used in TV GRP processing data. */
* Import DMA codes used in GRP data processing;
%LET PATH2=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Nielsen_Data_Processing;
%MACRO IMPORTDATA(DBNAME,TABLENM,OUTNAME);
  PROC IMPORT DATATABLE = "&TABLENM."  OUT = WORK.&OUTNAME.
    DBMS=ACCESS REPLACE;
    DATABASE = "&PATH2\INPUT\&DBNAME.";
  RUN;
%MEND;
%IMPORTDATA(Nielsen_Nasonex_Inputs.mdb,DMA_NAME_CODE_XREF,RAW_DMA_XREF);

proc sql;
create table curr_dma as
  select distinct dma, dma_name from in_zipdma_2;
quit;
proc sort data=curr_dma; by dma dma_name; run;
proc sort data=raw_dma_xref(where=(duplicate_ind=0)) 
    out=grp_dmas(keep=dma_code dma_name rename=(dma_code = dma));
by dma_code dma_name;
run;
data curr_dma; 
  set curr_dma;
  dma_name = transtrn(dma_name,',',trimn('')); * sas 9.2 function;
run;
data tst;
  merge curr_dma(in=a) grp_dmas(in=b);
  by dma dma_name;
  inset=10*a+b;
run;
proc sort data=tst; by inset; run;
proc freq data=tst; tables inset / list missing; run;
/*
Note: In GRP DMAs file a "," in the dma_name is replaced by null string. Same transformation was done for curr
   file before testing the differences in curr_dma and grp_dmas. 
  There are 7 mismatches, but these are merely due to mis-match in format of dma names and not the dma codes.
  Hence, all the 210 DMA codes in both files match well. 
*/

/* 2. DEDUPE the imported zip to dma file. */
/* Follow rules used by Blythe / Tracie while creating 2010 dedupe file */
/* PURPOSE OF PROGRAM IS TO CREATE ONE ZIP PER DMA - LOGIC ON HOW TO DEUP ZIPS WITH MORE THAN ONE DMA */
/* (1) if a zip occurs in > 1 DMA, &  one of dups is Metro, keep Metro record & drop other record(s) 
       to preferentially keep zip-DMA relationship of DMA with more population-dense part of zip if it exists */
/* (2) if dups within Metro OR dups within non-Metro, then keep record with lowest-ranked DMA (DMA_RANK) 
    DMA with lowest RANK has largest population & DMA with highest RANK has lowest population.
    This business rule would keep record of zip (in more than one DMA) that is associated with DMA with lowest value in DMA RANK */
/* Objective is to put zip in DMA that is likely to have largest population: Metro is more likely to have larger population than non-metro. 
   Also, if it is a bigger DMA, it's more likely to have larger population.  Niether statement is always true but is an assumption. */

* Split metro and non-metro zip codes into separate files;
* Dedup each file using DMA_RANK keeping zip/DMA with largest population (i.e. DMA with lowest rank);

DATA METRO NONMETRO; SET in_zipdma_2;
	IF metro_ind="M" THEN OUTPUT METRO;
	ELSE OUTPUT NONMETRO; RUN;

PROC SORT DATA=METRO OUT=METRO2; BY ZIP_CODE DMA_RANK;  RUN;
PROC SORT DATA=METRO2 OUT=METRO3 NODUPKEY; BY ZIP_CODE;  RUN; *10% of metro dupes removed;

PROC SORT DATA=NONMETRO OUT=NONMETRO2; BY ZIP_CODE DMA_RANK;  RUN;
PROC SORT DATA=NONMETRO2 OUT=NONMETRO3 NODUPKEY; BY ZIP_CODE;  RUN; *17% of non-metro dupes removed;

* Set metro and non-metro zips together, dedup keeping metro preferentially;
DATA DMA; SET METRO3 NONMETRO3; RUN;

PROC SORT DATA=DMA; BY ZIP_CODE DESCENDING METRO_IND; RUN;

PROC SORT DATA=DMA OUT=DMA.ZIP_TO_DMA_2011ZIPS_DEDUPED NODUPKEY;
BY ZIP_CODE; 
RUN; * Another 6% duplicates removed. Final record count: 41147;

*store original input file with duplicate zip codes as well;
DATA DMA.DMAZIP_JUL2011; SET in_zipdma_2; RUN;


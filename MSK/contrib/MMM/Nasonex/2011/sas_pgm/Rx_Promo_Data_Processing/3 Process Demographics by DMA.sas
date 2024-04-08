***************************************************************************;
* 3. Process Population data to aggragate by DMA                         ;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME DEMO "\\wpushh01\dinfopln\PRA\Consultation\Demographics\PCensus Docs\Claritas 2009";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";

%LET PATH=\\wpushh01\dinfopln\PRA\Consultation\Demographics\PCensus Docs\Claritas 2009;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

*1. get population by zip;
data zip_pop(keep=zip_code pop_total pop_21_54);
  set demo.popqf_2009;
  length zip_code $5. pop_total pop_21_54 8;
  zip_code = zip;
  pop_total=pop_2009;
  pop_21_54 = sum(of pop_21_24_2009 pop_25_34_2009 pop_35_44_2009 
                     pop_45_49_2009 pop_50_54_2009);
run;
proc sort data=zip_pop out=tst nodupkey; by zip_code; run; *no dupes;

*2. get income by zip;
PROC IMPORT 
  DATAFILE="&PATH.\US_2009_income_by_zip.txt" 
  OUT=WORK.IN_Income DBMS=CSV REPLACE; 
  GETNAMES=NO; DELIMITER=',';
  DATAROWS=2;
RUN;
data zip_income;
  set in_income;
  length zip_code $5. hh_count hh_avg_income 8;
  zip_code = put(var1*1, z5.);
  hh_count = var2;
  hh_avg_income = var3;
  drop var1 - var3;
run;

*3. merge and summarize by DMA;
proc sql;
create table dma_pop as
select b.dma, count(distinct a.zip_code) as num_zips,
       sum(pop_total) as pop_total, sum(pop_21_54) as pop_21_54  
from zip_pop a, dma.zip_to_dma_2011zips_deduped b
where a.zip_code = b.zip_code
group by b.dma;
quit;

proc sql;
create table dma_income as
select b.dma, count(distinct a.zip_code) as num_zips,
       sum(hh_count) as hh_count, sum(hh_avg_income) as hh_avg_income   
from zip_income a, dma.zip_to_dma_2011zips_deduped b
where a.zip_code = b.zip_code
group by b.dma;
quit;

proc sql;
create table dma_pop_income as
select a.*, b.hh_count, b.hh_avg_income 
from dma_pop a, dma_income b
where a.dma = b.dma;
quit;
data rx.pop_income_dma; set dma_pop_income; run;


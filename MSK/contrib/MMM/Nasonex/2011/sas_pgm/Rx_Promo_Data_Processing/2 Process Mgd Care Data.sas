***************************************************************************;
* 2. Process Managed Care data to aggragate by DMA                         ;
* This managed care data was obtained from PDT ;
***************************************************************************;
LIBNAME DMA  "\\WPUSHH01\DINFOPLN\PRA\ALIGNMENTS\DMA\DATA";
LIBNAME RX  "C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other";

%LET PATH=C:\Documents and Settings\smuruga2\PROJECTS\DTC\Nasonex\2011\Data\rx_promo_other\mgdcare;
OPTIONS MPRINT MLOGIC SYMBOLGEN COMPRESS=YES;

* 1. Import Nasonex Managed care data by zip code;
PROC IMPORT 
  DATAFILE="&PATH.\NAS DUL PDT Nation 8-26-11 VER5.txt" 
  OUT=WORK.IN_MC DBMS=TAB REPLACE; 
  GETNAMES=NO; *DELIMITER=',';
  DATAROWS=2;
RUN;
data in_mc_2;
  set in_mc;
  length zip_code $5. 
    rp_rx nrp_rx offp_rx  nas_cq_mo nas_ytd_mo ins_cq_mo ins_ytd_mo row_num 8;
  zip_code = put(var1*1, z5.);
  rp_rx = var2; nrp_rx = var3; offp_rx = var4; nas_cq_mo = var5; nas_ytd_mo = var6;
  ins_cq_mo = var7; ins_ytd_mo = var8; row_num = var9;
  drop var1 - var9;
run;

* merge and aggregate by DMA;
proc sql;
create table mc_dma_1 as
select b.dma, count(distinct a.zip_code) as num_zips,
       sum(rp_rx)/sum(ins_cq_mo) as rp, 
       sum(nrp_rx)/sum(ins_cq_mo) as nrp,
       sum(offp_rx)/sum(ins_cq_mo) as offp,
       sum(nas_cq_mo) as nas_cq_rx, sum(nas_ytd_mo) as nas_ytd_rx, 
	   sum(ins_cq_mo) as ins_cq_rx, sum(ins_ytd_mo) as ins_ytd_rx 
from in_mc_2 a, dma.zip_to_dma_2011zips_deduped b
where a.zip_code = b.zip_code
group by b.dma;
quit;
data rx.mgdcare_dma; set mc_dma_1; run;


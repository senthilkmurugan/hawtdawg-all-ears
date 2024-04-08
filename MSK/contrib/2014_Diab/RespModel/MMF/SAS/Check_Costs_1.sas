* Explore the 2012 costs;

OPTIONS NOCENTER MPRINT;
LIBNAME MMF "Y:\Marketing Mix PI\InvOpt\P2 2014 AB\Promo\Diabetes Deep Dive\RespModel\MMF\Data"; 
LIBNAME GRAIL "\\usuguscads1\data\grail\&PRODUCT";
LIBNAME ATT '\\wpushh01\dinfopln\Marketing Mix PI\MMF 2013\MMF'; * mfatnd_dec11nov12.sas7bdat;
LIBNAME TARG 'Y:\Marketing Mix PI\MMF 2013\Targets & Spec'; 
LIBNAME COST "\\wpushh01\dinfopln\Marketing Mix PI\MMF 2013\MMF"; *rawexp_dec11nov12.sas7bdat;
RUN;

* dataset MMF.HEL_SUBSET has attendee data for DIAB MMFs;
proc sort data=mmf.hel_subset out=attnd nodupkey; by pgmid; run;
proc sort data=cost.rawexp_dec11nov12 out=cost; by pgmid; run;
data pgm_cost;
  merge attnd(in=a) cost(in=b);
  by pgmid;
  inset=10*a+b;
  if a;
run;
proc freq data=pgm_cost; tables inset; run;

proc sql;
select sum(speaker) as spk_cost, sum(field) as oth_cost from pgm_cost;
quit;
*speaker: $2,085,382. field: $1,392,691. total: $3,478,073. ; 


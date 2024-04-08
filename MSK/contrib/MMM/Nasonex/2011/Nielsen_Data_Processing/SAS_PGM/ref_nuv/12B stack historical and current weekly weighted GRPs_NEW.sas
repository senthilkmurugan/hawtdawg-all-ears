PROC PRINTTO LOG="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\12B stack historical and current weekly weighted GRPs.LOG" NEW
			PRINT="\\wpushh01\dinfopln\PRA\DTC\NuvaRing\2011 profit plan\SAS Logs and Lists\12B stack historical and current weekly weighted GRPs.LST" NEW;
LIBNAME PDTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2010 profit plan\SAS datasets";
LIBNAME DTC "\\WPUSHH01\DINFOPLN\PRA\DTC\NuvaRing\2011 profit plan\SAS datasets";

data temp;
  set PDTC.WEEKLY_LOCAL_WEIGHTED_GRPS_V2;
  if week=155 then delete; * delete "28DEC09" data from historic data, as it will be replaced from the current data;
run;

DATA DTC.WEEKLY_LOCAL_WEIGHTED_GRPS_JUN10;
	*SET PDTC.WEEKLY_LOCAL_WEIGHTED_GRPS DTC.WEEKLY_LOCAL_WEIGHTED_GRPS;
    SET temp DTC.WEEKLY_LOCAL_WEIGHTED_GRPS;
    ARRAY NUMS(*) _NUMERIC_; 
      DO K=1 TO DIM(NUMS); IF NUMS(K)=. THEN NUMS(K)=0; 
    END; 
    drop k;
RUN;

PROC SORT DATA=DTC.WEEKLY_LOCAL_WEIGHTED_GRPS_JUN10;
	BY MARKET;
RUN;

PROC PRINTTO;
QUIT;

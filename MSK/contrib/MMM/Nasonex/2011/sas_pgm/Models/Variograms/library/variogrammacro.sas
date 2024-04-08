%macro variogram (data=,resvar=,clsvar=,expvars=,id=,time=,maxtime=,);

ods listing close;

proc mixed data=&data;
   class &clsvar;
   model &resvar=&expvars / outpm=residuals;
/*
   model &resvar=&expvars / outp=residuals;
   RANDOM intercept / subject=market;
   REPEATED rtime/ TYPE=AR(1) SUBJECT=MARKET;
*/
run;

ods listing;

data residuals1;
   set residuals;
   by &id;
   if first.&id then timegrp=1;
   else timegrp+1;
run;

proc transpose data=residuals1 out=subject prefix=time;
   var resid &time;
   by &id;
   id timegrp;
run;

data variogram_table(keep=variogram) time_interval_table(keep=time_interval);
   set subject;
   array time(*) time1-time&maxtime;
   array diff(%eval(&maxtime-1),%eval(&maxtime-1));
   array timei(%eval(&maxtime-1),%eval(&maxtime-1));
   if _name_='Resid' then
      do i = 1 to %eval(&maxtime-1);
         do k = i+1 to &maxtime;
            if time(i) ne . and time(k) ne . then
              do;
                diff(i,k-1)=((time(i)-time(k))**2)/2;
              end;
          end;
      end;
   else
     do i = 1 to %eval(&maxtime-1);
        do k = i+1 to &maxtime;
           if time(i) ne . and time(k) ne . then
             do;
               timei(i,k-1)=abs(time(i)-time(k));
             end;
         end;
     end;

  do i=1 to %eval(&maxtime-1);
     do k=i to %eval(&maxtime-1);
          if diff(i,k) ne . then
              do;
                variogram=diff(i,k);
                  output variogram_table;
              end;
        else
          if timei(i,k) ne . then
                do;
              time_interval=timei(i,k);
                    output time_interval_table;
                  end;
      end;
  end;
run;

data varioplot;
  merge variogram_table time_interval_table;
run;

%mend variogram;

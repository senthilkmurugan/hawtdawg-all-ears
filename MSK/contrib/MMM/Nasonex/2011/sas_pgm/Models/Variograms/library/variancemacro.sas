%macro variance(data=,id=,resvar=,clsvar=,expvars=,subjects=,maxtime=,);

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

proc transpose data=residuals1 out=varsubject prefix=time;
   var resid;
   by &id;
   id timegrp;
run;

data variance1(keep=diff1-diff%eval(&maxtime*&subjects));
  retain timepts1-timepts%eval(&maxtime*(&subjects+1)) diff1-diff%eval(&maxtime*&subjects);
  set varsubject end=lastone;
  array time{&maxtime};
  array timepts{%eval(&subjects+1),&maxtime};
  array diff(&subjects,&maxtime);

  do i=1 to &maxtime;
    timepts(_n_,i)=time(i);
  end;

  if lastone=1 then
    do;
        do i=1 to &subjects;
           do j=1 to &maxtime;
              do k=1 to %eval(&subjects+1)-i;
                 do l=1 to &maxtime;
                    diff(k,l)=((timepts(i,j) - timepts(k+i,l))**2)*1/2;
                 end;
              end;
              output;
                 do k=1 to &subjects;
                   do l=1 to &maxtime;
                      diff(k,l)=.;
                   end;
                 end;
           end;
       end;
   end;
run;

data average_variance(keep=average total nonmissing);
  array diff{%eval(&maxtime*&subjects)};
  set variance1 end=lastone;
  nonmissing+n(of diff1-diff%eval(&maxtime*&subjects));
  total+sum(of diff1-diff%eval(&maxtime*&subjects));
  if lastone=1 then
    do;
      average=total/nonmissing;
      output;
    end;
run;

proc print data=average_variance;
run;

%mend variance;

clear
import mlreportgen.report.*
import mlreportgen.dom.* 
colDate=[11,8,2023];

R=Report('MEOLUT Performance Statistics','docx');
open(R)
tp = TitlePage();
tp.Title = 'MEOLUT Performance Report';
tp.Author = 'ISTRAC';

ch0=Chapter('Summary');
s00=Section('At a glance');
cc(1,[1 2 12])={'Requirement';'Pass criteria';'ref C/S T.19'};
cc(2,[1 2 12])={'Probability of detection';num2str(0.99,'%0.2f');'5.3.1'};
cc(3,[1 2 12])={'Probability of Location Estimation (Single Burst)';num2str(0.90,'%0.2f');'5.4.1.1'};
cc(4,[1 2 12])={'Probability of Location Estimation (10 min window)';num2str(0.98,'%0.2f');'5.4.2.1'};
cc(5,[1 2 12])={'Location Accuracy-90% radius (Single burst)';5;'5.6.1'};
cc(6,[1 2 12])={'Location Accuracy-95% radius (10 min window) in km';5;'5.6.1'};
cc(7,[1 2 12])={'Location Accuracy-98% radius (10 min window) in km';10;'5.6.1'};
cc(8,[1 2 12])={'Probability of actual location being within EHE circle';'between 0.93 and 0.97';'5.10'};
cc(9,[1 2 12])={'Probability of EHE underestimation';'<0.01';'5.10'};
cc(10,[1 2 12])={'Probability of EHE overestimation';'<0.15';'5.10'};
cc(11,[1 2 12])={'Processing anomaly rate';'<0.0001';'5.11'};



for ii=1
    multp=1;    
    switch ii
        case 1
            cname='India';
%             bID='3476759F3F81FE0';%India
            bID='347C000000FFBFF';%India
            refLoc=[13.0342,77.5125, 1e3];BRT=50;            
        case 2
            cname='UAE';
            bID = '3ADE22223F81FE0';%uae
            refLoc=[24.431,54.448,5];BRT=50;
        case 3
            cname='Reunion-Cal-2';
            bID = '9C62EE2962AF260';%Reunion-Cal-2
            refLoc=[-20.9088888,55.513616,95];BRT=150;
        case 4
            cname='Singapore';
            bID = '467C000002FFBFF';%singapore
            refLoc=[1.3771,103.9881,10];BRT=50;
        case 5
            cname='Japan';
            bID = 'B5FE18FED639240';%Futtsu
            refLoc=[35.238833,139.9195,5]; BRT=50;
        case 6
            cname='Australia';
            bID = '3EFC000002FFBFF';%Australia
            refLoc=[-29.0465,115.3425,281]; BRT=50;
        case 7
            cname='Cyprus';
            bID = '9A22BE29630F010';%cyprus
            refLoc=[34.865390123,33.383751325,322.845]; BRT=50;multp=3;
        case 8
            cname='France';
            bID = '9C62BE29630F1D0';%France
            refLoc=[43.560535214,1.480896128,209.358]; BRT=50;multp=3;
        case 9
            cname='Kerguelen';
            bID='9C7FEC2AACD3590';%always on  Kerguelen
            refLoc=[-49.3515,70.256,80];BRT=30;
    end
    loc_est2
    if nodata
        cc(1,2+ii)={cname};
        continue;
    end
    if ii==1
        tp.Subtitle = ['Based on data collected on ',char(datetime(flip(colDate))),' ','from ',char(extractBetween(toa(1),9,16)),' to ',char(extractBetween(toa(end),9,16)),' UTC'];
        add(R,tp)
        toc=TableOfContents;
        add(R,toc)
    end
    
    ch=Chapter(cname);
    s0=Section('Beacon Parameters');
    ln1=['ID = ',bID];
    ln2=['Location : latitude = ',num2str(refLoc(1)),' longitude = ',num2str(refLoc(2))];    
    ln3=['Burst Repetion Time : ',num2str(BRT),'s'];
    add(s0,ln1)
    add(s0,ln2)
    add(s0,ln3)
    
    s1=Section('Summary');
    c(1,:)={'Requirement';'Pass criteria';'Result';'ref C/S T.19'};    
    c(2,:)={'Probability of detection';num2str(0.99,'%0.2f');num2str(multp*LErate10min(1),'%0.2f');'5.3.1'};
    c(3,:)={'Probability of Location Estimation (Single Burst)';num2str(0.90,'%0.2f');num2str(multp*LErate_s,'%0.2f');'5.4.1.1'};
    c(4,:)={'Probability of Location Estimation (10 min window)';num2str(0.98,'%0.2f');num2str(multp*LErate_s1,'%0.2f');'5.4.2.1'};
    c(5,:)={'Location Accuracy-90% radius (Single burst)';5;rad90;'5.6.1'};
    c(6,:)={'Location Accuracy-95% radius (10 min window) in km';5;rad95;'5.6.1'};
    c(7,:)={'Location Accuracy-98% radius (10 min window) in km';10;rad98;'5.6.1'};
    c(8,:)={'Probability of actual location being within EHE circle';'between 0.93 and 0.97';acc100;'5.10'};
    c(9,:)={'Probability of EHE underestimation';'<0.01';acc200;'5.10'};
    c(10,:)={'Probability of EHE overestimation';'<0.15';acc10;'5.10'};
    c(11,:)={'Processing anomaly rate';'<0.0001';'to be included';'5.11'};
    
    tb1=BaseTable(c);
    add(s1,tb1)
    %
    cc(1,2+ii)={cname};
    cc(2,2+ii)={num2str(multp*LErate10min(1),'%0.2f')};
    cc(3,2+ii)={num2str(multp*LErate_s,'%0.2f')};
    cc(4,2+ii)={num2str(multp*LErate_s1,'%0.2f')};
    cc(5,2+ii)={rad90};
    cc(6,2+ii)={rad95};
    cc(7,2+ii)={rad98};
    cc(8,2+ii)={acc100};
    cc(9,2+ii)={acc200};
    cc(10,2+ii)={acc10};
    cc(11,2+ii)={'to be included'};
    %
    
    s2=Section('Supporting Figures');
    s21=Section('Probability of Detection');
    s22=Section('Probability of Location Estimation(Single Burst)');
    s23=Section('Probability of Location Estimation(10 min window)');
    s24=Section('Location Estimation Accuracy(Single Burst)');
    s25=Section('Location Estimation Accuracy(10 min window)');
    s26=Section('Error Prediction Accuracy(Single Burst)');
    
    add(s21,Figure(h6))
    add(s2,s21)
    add(s22,Figure(h3))
    add(s2,s22)
    if NoOfInvalidLocs>0
        txt1=strcat(num2str(NoOfInvalidLocs),' location estimates have been discarded due to inconsistency. The adjusted value has been reported in the summary table');
        add(s2,txt1)
    end
    add(s23,Figure(h4))
    add(s23,Figure(h5))
    add(s2,s23)
    add(s24,Figure(h7))
    add(s2,s24)
    add(s25,Figure(h8))    
    add(s2,s25)
    add(s26,Figure(h12))
    add(s2,s26)
    
    
    s3=Section('Extra Information');
    s31=Section('Individual channel detection stats');
    s32=Section('Individual channel detection stats(10 min window)');
    s33=Section('scatter plot of estimated location(single burst)');
    s34=Section('scatter plot of estimated location(10 min window)');
    add(s31,Figure(h1))
    add(s3,s31);
    
    add(s32,Figure(h2))
    add(s3,s32);
    
    add(s33,Figure(h9))
    add(s3,s33);
    
    add(s34,Figure(h11))
    add(s3,s34);  
    
    add(ch,s0)
    add(ch,s1)
    add(ch,s2)
    add(ch,s3)
    add(R,ch)
    
end
tb0=BaseTable(cc);
add(s00,tb0)
add(ch0,s00)
add(R,ch0)

close(R)
rptview(R)
%% Import data from text file.

% clear
close all
%%
% colDate=[12,8,2023];
% bID='3476759F3F81FE0';%India
% refLoc=[13.036,77.511, 1e3];BRT=50;

% bID='9C6000000000001';%France
% refLoc=[43.5605,1.4808];BRT=30;

% bID ='9C62BE29630F1C0';%Reunion QMS
% refLoc=[-20.9088888,55.51361,95];BRT=50;

% bID='9C7FEC2AACD3590';%always on  Kerguelen
% refLoc=[-49.3515,70.256,80];BRT=30;

% bID='9C62BE29630F1D0';%France
% refLoc=[43.5605,1.4808];

% bID='CF62BE29630F0C0';%not always on Kerguelen
% refLoc=[-49.3515,70.256,80];BRT=150;

% bID = '9C62EE2962AC3C0';%Reunion-Cal-1
% refLoc=[-20.9088888,55.513616,95];BRT=150;

% bID = '9C62EE2962AF260';%Reunion-Cal-2
% refLoc=[-20.9088888,55.513616,95];BRT=150;

% bID = '3ADE22223F81FE0';%uae
% refLoc=[24.431,54.448,5];BRT=50;

% bID = '467C000002FFBFF';%singapore
% refLoc=[1.3771,103.9881,10];BRT=50;

% bID = '2DC843E88EFFBFF';
% refLoc=[15.6481,32.5769]; BRT=50;

refXYZ=lla2ecef(refLoc);
%% Initialize variables.
% path='C:\Users\Istrac\Documents\endurance_test\';
path='';
datestr=strcat(num2str(colDate(3)),'_',num2str(colDate(2),"%02u"),'_',num2str(colDate(1),"%02u"));
filename = strcat(path,'beacondata_DRX_',datestr,'.txt');
delimiter = ',';
% 
% outfolder=strcat(path,'beacondata_DRX_',num2str(colDate(3)),'_',num2str(colDate(2),"%02u"),'_',num2str(colDate(1),"%02u"),'\',bID,'\');
% mkdir(outfolder);
infilename=strcat('gnss_',datestr,'.txt');
infile = fopen(infilename, 'r');
x=0;
while true
    x=x+1;
    if length(fgets(infile))<2
        break;
    end
end
global list;
fclose(infile);
list=cell(1,x);
infile = fopen(infilename, 'r');
for i=1:x
    list{i}=fgets(infile);
end
fclose(infile);
%% Format for each line of text:
%   column1: categorical (%C)
%	column2: double (%f)
%   column3: categorical (%C)
%	column4: categorical (%C)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: categorical (%C)
%   column9: categorical (%C)
%	column10: double (%f)
%   column11: double (%f)
%	column12: text (%s)
%   column13: categorical (%C)
%	column14: categorical (%C)
%   column15: double (%f)
%	column16: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%C%f%C%s%C%f%f%C%C%f%f%s%C%C%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
chns=dataArray{2};
satnames=dataArray{4};
pdf1s=dataArray{6};
pdf2s=dataArray{7};
datas=dataArray{9};
CNRs=dataArray{10};
FOAs=dataArray{11};
TOAs=dataArray{12};
countrys=dataArray{13};
IDs=dataArray{14};
lats=dataArray{15};
lons=dataArray{16};
S=dataArray{17};
azs=dataArray{18};
els=dataArray{19};



%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;
%%


selection=IDs==bID & satnames~='DEFAULT' & contains(satnames,'GSAT');

data = datas(selection);
chn = chns(selection);
satname = satnames(selection);
CNR = CNRs(selection);
FOA = FOAs(selection);
toa = TOAs(selection);
az = azs(selection);
el = els(selection);
%%
if isempty(toa)
    nodata=true;
    return;
else
    nodata=false;
end
TOA=zeros(size(toa));
%ToaCoarse=zeros(size(toa));
mult=[3600 60 1 1e-3 1e-6 1e-9];
for i=1:length(toa)
    str=(strsplit(toa(i),[" ",":"]));
    tt=str2double(str(2:end));
    temp=char(str(1));
    d=str2double(temp(4:end));
    %TOA(i)=mult*tt';
    TOA(i)=[3600 60 1 1e-3 1e-6 1e-9]*tt';
end
i=1;
while(abs(TOA(i))>23*3600)
 i=i+1;   
end
i=i-1;

wiperange=1:i;
% wiperange=1:7;
% TOA(1:i+1)=[];
TOA(wiperange)=[];
toa(wiperange) =[];
data(wiperange) =[];
chn(wiperange)=[];
satname(wiperange) =[];
CNR(wiperange) =[];
FOA(wiperange) =[];
az(wiperange) =[];
el(wiperange) =[];
% TOA0=TOA(1)-1200;
% TOA=TOA-d*24*3600;
%%
%scan for jump in TOA
%count the jumps
count=1;
for i=1:length(TOA)-1
    diff=TOA(i+1)-TOA(i);
   if abs(diff)>1
       count=count+round(diff/BRT);
   end
end
tgroups=zeros(7,count);
fgroups=zeros(7,count);
tgroups1=cell(7,count);
satgroups=cell(7,count);
CNRgroups=zeros(7,count);
azgroups=zeros(7,count);
elgroups=zeros(7,count);
count=1;
for i=1:length(TOA)-1    
    tgroups(chn(i),count)=TOA(i)/3600;
    fgroups(chn(i),count)=FOA(i);
    tgroups1{chn(i),count}=toa(i);
    satgroups{chn(i),count}=char(satname(i));
    CNRgroups(chn(i),count)=CNR(i);
    azgroups(chn(i),count)=az(i);
    elgroups(chn(i),count)=el(i);    
    diff=TOA(i+1)-TOA(i);
    if abs(diff)>1
        count=count+round(diff/BRT);
    end
end
th1=TOA/3600;
%%
det=sum(tgroups~=0);
% disterror=zeros(1,length(det));
% lat=zeros(1,length(det));
% lon=zeros(1,length(det));
% h=zeros(1,length(det));
% k=1;
count=zeros(1,7);
t_err=zeros(7,7,length(det));
f_err=zeros(7,7,length(det));
az_err=zeros(7,length(det));
el_err=zeros(7,length(det));
ind1=zeros(7,length(det),'logical');
ind2=zeros(7,length(det),'logical');
ind3=zeros(7,length(det),'logical');
ft_err=zeros(length(det),7);
for i=1:length(det)
    noOfsimdet=det(i);
    if noOfsimdet >=2
        [t_err(:,:,i),f_err(:,:,i),az_err(:,i),el_err(:,i),flag1,flag2,flag3,ft_err(i,:)]=checkErrors(tgroups1(:,i),fgroups(:,i),azgroups(:,i),elgroups(:,i),satgroups(:,i),refXYZ);
        flag=flag1|flag2|flag3;
        if any(flag1)
            count(flag)=count(flag)+1;
            ind1(flag1,i)=true;
            ind2(flag2,i)=true;
            ind3(flag3,i)=true;
        end
    end        
end

ind=ind1 | ind2 | ind3;
det7a=tgroups~=0;
det7=det7a & ~ind;

detrate_single = (sum(tgroups~=0,2)/size(tgroups,2))';

h1=figure;
for i=1:7
    subplot(7,1,i)
    sel = det7(i,:);
    tt0=tgroups(i,sel);
    if ~isempty(tt0)
        stem(tt0,ones(1,length(tt0)),'b','Marker','none')        
    end 
    hold on
    sel12=ind1(i,:) | ind2(i,:) ;
    tt1=tgroups(i,sel12);
    if ~isempty(tt1)
        stem(tt1,ones(1,length(tt1)),'r','Marker','none')        
    end
    sel2=sel12 & ind3(i,:) ;
    tt2=tgroups(i,sel2);
    if ~isempty(tt2)
        stem(tt2,ones(1,length(tt2)),'xr');       
    end  
     sel3=~sel12 & ind3(i,:) ;
    tt3=tgroups(i,sel3);
    if ~isempty(tt3)
        stem(tt3,ones(1,length(tt3)),'xb');       
    end 
    
    title(strcat('Antenna',num2str(i)))
    text(th1(end),1,strcat('err=',num2str(sum(ind(i,:)))));
    text(th1(end),0,strcat(num2str(100*detrate_single(i),'%2.2f'),'%'));
    xlim([th1(1) th1(end)])
    ylim([0 1.2]) 
    yticks([0 1])
    %eliminate the problematic elements 
%     sel=sel12|ind3(i,:);
%     tgroups(i,sel)=0;
%     for k=1:length(sel)
%         if sel(k)
%             tgroups1{i,k}=[];
%         end
%     end
end
xlabel('UTC')
%%
detrate_10min=zeros(1,7);
%10 min time window detection rate
h2=figure;
edges = (TOA(1):600:TOA(end))/3600;

for i=1:7
subplot(7,1,i)    
h=histogram(tgroups(i,:),edges);
xlim([TOA(1) TOA(end)]/3600)
detrate_10min(i)=sum(h.Values>0)/h.NumBins;
text(th1(end),0,strcat(num2str(100*detrate_10min(i),'%2.2f'),'%'));
end
detrate_10min;

%%
%group information(for Location estimation purpose)
%single burst
h3=figure;
det=sum(tgroups~=0);
tt=sum(tgroups);
valid=tt~=0;
detvalid=det(valid);
ttvalid=tt(valid)./detvalid;
stem(ttvalid,detvalid,'Marker','none')
xlim([TOA(1) TOA(end)]/3600)
ylim([0 7])
valid=det>=3;
LErate_single(1)=sum(valid)/length(det);
valid=det>=4;
LErate_single(2)=sum(valid)/length(det);
valid=det>=5;
LErate_single(3)=sum(valid)/length(det);
valid=det>=6;
LErate_single(4)=sum(valid)/length(det);
valid=det>=7;
LErate_single(5)=sum(valid)/length(det);
valid=det>=1;
LErate_single(6)=sum(valid)/length(det);

text(TOA(end)/3600,1,strcat(num2str(100*LErate_single(6),'%2.2f'),'%'))
text(TOA(end)/3600,3,strcat(num2str(100*LErate_single(1),'%2.2f'),'%'))
text(TOA(end)/3600,4,strcat(num2str(100*LErate_single(2),'%2.2f'),'%'))
text(TOA(end)/3600,5,strcat(num2str(100*LErate_single(3),'%2.2f'),'%'))
text(TOA(end)/3600,6,strcat(num2str(100*LErate_single(4),'%2.2f'),'%'))
text(TOA(end)/3600,7,strcat(num2str(100*LErate_single(5),'%2.2f'),'%'))
hold on 
plot([TOA(1) TOA(end)]/3600,[3 3],'r')
plot([TOA(1) TOA(end)]/3600,[4 4],'r')
ylabel('no of channels detected simultaneously')
xlabel('UTC')
title('Probability of FDOA/TDOA Location(single burst)')
%%
%10 min time window location estimation
h4=figure;
edges = (TOA(1):600:TOA(end))/3600;
valid=det>=3;
detvalid=det(valid);
ttvalid=tt(valid)./detvalid; 
h=histogram(ttvalid,edges);
xlim([TOA(1) TOA(end)]/3600)
hold on 
plot([TOA(1) TOA(end)]/3600,[1 1],'r')
LErate10min(3)=sum(h.Values>0)/h.NumBins;
text(TOA(end)/3600,1,strcat(num2str(100*LErate10min(3),'%2.2f'),'%'))
ylabel('no of atleast-3-chn simultaneous det(10 min wnd)')
xlabel('UTC')
title('Probability of FDOA/TDOA Location(10 min window)')
%%
%10 min time window location estimation
h5=figure;
edges = (TOA(1):600:TOA(end))/3600;
valid=det>=4;
detvalid=det(valid);
ttvalid=tt(valid)./detvalid; 
h=histogram(ttvalid,edges);
xlim([TOA(1) TOA(end)]/3600)
hold on 
plot([TOA(1) TOA(end)]/3600,[1 1],'r')
LErate10min(4)=sum(h.Values>0)/h.NumBins;
text(TOA(end)/3600,1,strcat(num2str(100*LErate10min(4),'%2.2f'),'%'))
ylabel('no of atleast-4-chn simultaneous det(10 min wnd)')
xlabel('UTC')
title('Probability of FDOA/TDOA Location(10 min window)')
%% detection probability in 10 min
h6=figure;
valid=det>=1;
detvalid=det(valid);
ttvalid=tt(valid)./detvalid; 
h=histogram(ttvalid,edges);
xlim([TOA(1) TOA(end)]/3600)
hold on 
plot([TOA(1) TOA(end)]/3600,[1 1],'r')
LErate10min(1)=sum(h.Values>1)/h.NumBins;
text(TOA(end)/3600,1,strcat(num2str(100*LErate10min(1),'%2.2f'),'%'))
ylabel('detections in 10 min window(at least 1 channel)')
xlabel('UTC')
title('Probability of Detection')
%%
det=sum(tgroups~=0);
disterror=zeros(1,length(det));
lat=zeros(1,length(det));
lon=zeros(1,length(det));
ht=zeros(1,length(det));
ehe=zeros(1,length(det));
k=1;
tic
for i=1:length(det)
    noOfsimdet=det(i);i
    if i==15
        hgh=0;
    end
    switch noOfsimdet        
%         case 2
%             [lat(i),lon(i),h(i)]=tdoa1fdoa1(tgroups1(:,i),fgroups(:,1),satgroups(:,i));
        case 3
            [lat(i),lon(i),ht(i),ehe(i)]=tdoa3(tgroups1(:,i), fgroups(:,i), CNRgroups(:,i), satgroups(:,i));
        case 4
            [lat(i),lon(i),ht(i),ehe(i)]=tdoa3(tgroups1(:,i), fgroups(:,i), CNRgroups(:,i), satgroups(:,i));
        case 5
            [lat(i),lon(i),ht(i),ehe(i)]=tdoa3(tgroups1(:,i), fgroups(:,i), CNRgroups(:,i), satgroups(:,i));
        case 6            
            [lat(i),lon(i),ht(i),ehe(i)]=tdoa3(tgroups1(:,i), fgroups(:,i), CNRgroups(:,i), satgroups(:,i));
        case 7
            [lat(i),lon(i),ht(i),ehe(i)]=tdoa3(tgroups1(:,i), fgroups(:,i), CNRgroups(:,i), satgroups(:,i));
        otherwise
            lat(i) = NaN;
    end
    if ~isnan(lat(i))
        disterror(i) = distance(lat(i),lon(i),refLoc(1),refLoc(2),referenceEllipsoid('WGS84'))*1e-3;
    else
        disterror(i)=NaN;
    end
end
toc
LErate_s=sum(~isnan(lat))/length(det);
NoOfInvalidLocs=sum(det>=3)-sum(~isnan(lat));
h7=figure;
edges=0:0.2:20;
derr=edges(1:end-1)+0.1;
h=histogram(disterror(~isnan(disterror)),[edges Inf],'Normalization','cdf');
pvals=h.Values;
dd=100*h.Values;
plot(derr,dd(1:end-1))
hold on
plot(derr,90*ones(size(derr)))
ylim([0 100])
xlim([0 20]);
grid on
text(20,dd(end-1),num2str(dd(end-1)))
xlabel('error(km)')
ylabel('cumulative percentage')
title(strcat('single burst location accuracy (',num2str(sum(~isnan(lat))),' locations)'))
for kk=1:length(pvals)-1
    if pvals(kk)>0.90
        break;
    end    
end
if pvals(kk)>0.90
    %interpolate between kk and kk-1
    val=edges(kk-1)+(0.9-pvals(kk-1))*((edges(kk)-edges(kk-1))/(pvals(kk)-pvals(kk-1)));
    rad90=num2str(val,'%2.1f');
else
    rad90='>20';
end
lat1=zeros(1,length(det)-12);
lon1=zeros(size(lat1));
disterror1=NaN(size(lat1));
noOfwnd=floor(length(det)/12);
cnt=0;
for i=1:12:noOfwnd*12
    arr=i:i+11;
    arr1=arr(~isnan(lat(arr)));
    if ~isempty(arr1)
        cnt=cnt+1;
    end
end
LErate_s1=cnt/noOfwnd;
for i=1:length(det)-12
    noOfsimdet=det(i);
    if noOfsimdet >=4
        arr=i:i+11;
        arr1=arr(~isnan(lat(arr)));
        latcut=lat(arr1);
        loncut=lon(arr1);
        lat1(i)=median(latcut);
        lon1(i)=median(loncut);
        disterror1(i) = distance(lat1(i),lon1(i),refLoc(1),refLoc(2),referenceEllipsoid('WGS84'))*1e-3;
    else
        lat1(i)=NaN;
        lon1(i)=NaN;
    end
end

h8=figure;
h=histogram(disterror1(~isnan(disterror1)),[edges Inf],'Normalization','cdf');
pvals=h.Values;
dd=100*h.Values;
plot(derr,dd(1:end-1))
hold on
plot(derr,95*ones(size(derr)))
plot(derr,98*ones(size(derr)))
ylim([0 100])
xlim([0 20]);
grid on
text(20,dd(end-1),num2str(dd(end-1)))
xlabel('error(km)')
ylabel('cumulative percentage')
title(strcat('Multi burst location accuracy (10 min window)'))
for kk=1:length(pvals)-1
    if pvals(kk)>0.95
        break;
    end    
end
if pvals(kk)>0.95
    %interpolate between kk and kk-1
    val=edges(kk-1)+(0.95-pvals(kk-1))*((edges(kk)-edges(kk-1))/(pvals(kk)-pvals(kk-1)));
    rad95=num2str(val,'%2.1f');
else
    rad95='>20';
end
for kk=1:length(pvals)-1
    if pvals(kk)>0.98
        break;
    end    
end
if pvals(kk)>0.98
    %interpolate between kk and kk-1
    val=edges(kk-1)+(0.98-pvals(kk-1))*((edges(kk)-edges(kk-1))/(pvals(kk)-pvals(kk-1)));
    rad98=num2str(val,'%2.1f');
else
    rad98='>20';
end
%%
% scatter plots
h9=figure;
scatter(lat,lon,5)
xlabel('latitiude')
ylabel('longitude')
hold on
scatter(refLoc(1),refLoc(2),'*')
axis equal
%draw contours
xscale=pi*6400*cos(refLoc(1)*pi/180)/180;
yscale=pi*6400/180;

r=5;
x=zeros(1,360/5+1);
y=zeros(1,360/5+1);
for a=0:5:360
    xcomp=r*cos(a*pi/180);
    ycomp=r*sin(a*pi/180);
    latd=xcomp/xscale;
    lond=ycomp/yscale;
    x(a/5+1)=refLoc(1)+latd;
    y(a/5+1)=refLoc(2)+lond;
end
p5=plot(x,y);
x5=x;
y5=y;
r=10;
x=zeros(1,360/5+1);
y=zeros(1,360/5+1);
for a=0:5:360
    xcomp=r*cos(a*pi/180);
    ycomp=r*sin(a*pi/180);
    latd=xcomp/xscale;
    lond=ycomp/yscale;
    x(a/5+1)=refLoc(1)+latd;
    y(a/5+1)=refLoc(2)+lond;
end
p10=plot(x,y);
x10=x;
y10=y;

r=20;
x=zeros(1,360/5+1);
y=zeros(1,360/5+1);
for a=0:5:360
    xcomp=r*cos(a*pi/180);
    ycomp=r*sin(a*pi/180);
    latd=xcomp/xscale;
    lond=ycomp/yscale;
    x(a/5+1)=refLoc(1)+latd;
    y(a/5+1)=refLoc(2)+lond;
end
p20=plot(x,y);
x20=x;
y20=y;
legend([p5 p10 p20],{'5 km','10 km','20 km'})

h11=figure;
scatter(lat1,lon1,5)
xlabel('latitiude')
ylabel('longitude')
hold on
scatter(refLoc(1),refLoc(2),'*')
axis equal
p5=plot(x5,y5);
p10=plot(x10,y10);
p20=plot(x20,y20);
legend([p5 p10 p20],{'5 km','10 km','20 km'})

%%
h12=figure;
edges=0:0.05:3;
derr=edges(1:end-1)+0.05;
ndisterror=disterror./ehe;
h=histogram(ndisterror(~isnan(ndisterror)),[edges Inf],'Normalization','cdf');
pvals=h.Values;
dd=100*h.Values;
plot(derr,dd(1:end-1))
hold on
plot(derr,15*ones(size(derr)))
plot(derr,93*ones(size(derr)))
plot(derr,97*ones(size(derr)))
plot(derr,99*ones(size(derr)))
plot([0.1 0.1],[0 100])
plot([1 1],[0 100])
plot([2 2],[0 100])
ylim([0 100])
xlim([0 3]);
grid on
text(3,dd(end-1),num2str(dd(end-1)))
xlabel('actual error normalized by predicted error')
ylabel('cumulative percentage')
title(strcat('error prediction accuracy (',num2str(sum(~isnan(lat))),' locations)'))

indx=round((0.1)/0.05);
if indx<=length(pvals)
    acc10=num2str(pvals(indx),'%1.2f');
else
    acc10='1';
end
indx=round(1/0.05);
if indx<=length(pvals)
    acc100=num2str(pvals(indx),'%1.2f');
else
    acc100='1';
end
indx=round(2/0.05);
if indx<=length(pvals)
    acc200=num2str(1-pvals(indx),'%1.2f');
else
    acc200='0';
end
%%
% str='UAE\';
% saveas(h1,strcat(str,'det.png'),'png') 
% saveas(h2,strcat(str,'1burst_acc.png'),'png') 
% saveas(h3,strcat(str,'10min_acc_median.png'),'png') 
% offdist=distance(lat,lon,43.5605,1.4808,referenceEllipsoid('WGS84'))/1e3
% actualxyz=lla2ecef([8.52,76.89,0]);
% dr=sqrt(sum((xyz-repmat(actualxyz,4,1)).^2,2));
% extoa=tau+dr/3e8;
% et=extoa-t;
% et=1e6*(et-mean(et));


    
    
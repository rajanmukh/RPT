function [tdoa_err,fdoa_err,az_err,el_err,flag1,flag2,flag3,ft_err] = checkErrors(datetoa,foa,azs,els,sats,loc)
%EXPTDOA Summary of this function goes here
%   Detailed explanation goes here
global list;
%constant
f_list=[1544.1e6,1544.21e6,1544.9e6];
%station location
% xyzb=[1344034.83853675, 6068764.64905454, 1429435.659147];
xyzb=1e6*[1.344164600515364   6.068648167092199   1.429495327500622];
%
date2000=datetime('1-Jan-2000 12:00:00');
jd2000=juliandate(date2000);
%inputs
opsmode='a';
typerun='m';
typeinput='m';
whichconst=84;
rad = 180.0 / pi;
UT1_UTC=-0.06;
TT_UTC=69.2;
toa=zeros(7,1);
type=zeros(1,7);
j=0;
for i=1:7
    if ~isempty(datetoa{i})
        j=j+1;
        validindices(j) = i;
    end
end

freq_dn_ctr=zeros(1,7);
xyzECEF=zeros(3,7);
voECEF=zeros(3,7);
xyzTEME=zeros(7,3);
voTEME=zeros(7,3);
fd=zeros(1,7);
fd1=zeros(1,7);
tsince = zeros(7,1);
jd = zeros(7,1);
jd_UT1 = zeros(7,1);
jd_TT = zeros(7,1);
ttt = zeros(7,1);
jd_a = zeros(7,1);
jd_UT1_a = zeros(7,1);
jd_TT_a = zeros(7,1);
ttt_a = zeros(7,1);
for i=validindices
    %toa
    datestr=split(datetoa{i},' ');
    dt=char(datestr(1));
    yy=dt(1:2);
    DDD=dt(4:end);
    yyyy=num2str(str2double(yy)+2000);
    date=datetime([yyyy,'-',DDD,'-','00','-','00','-','00'],'InputFormat','uuuu-DDD-HH-mm-ss');
    d=str2double(DDD);
    tme=split(datestr(3),':');
    toa(i)=[3600 60 1 1e-3 1e-6 1e-9]*str2double(tme)+0.19;
    % find satellite positions at respective toas from tle info
    jd(i)=(toa(i)/86400)+juliandate(date);
    jd_UT1(i) = jd(i) + UT1_UTC/86400;
    jd_TT(i)  = jd(i) + TT_UTC/86400;
    ttt(i) = (jd_TT(i)-jd2000)/36525;
    %find the satellite tle
    ln=1;
    
    while(true)
        cflag=1;
        longstr = list{ln};ln=ln+1;
        if length(longstr)<50 && length(longstr)>5
            longstr0=longstr(1:length(sats{i}));
            if strcmp(longstr0(1:6),'BEIDOU')
                longstr0(9)='-';
                cflag=2;
            end
            if strcmp(longstr0(1:6),'COSMOS')
                longstr0(7)='-';
                cflag=3;
            end
            if strcmp(longstr0,sats{i})
                longstr1 = list{ln};ln=ln+1;
                longstr2 = list{ln};ln=ln+1;
                % sgp4fix additional parameters to store from the TLE
                rec.classification = 'U';
                rec.intldesg = '        ';
                rec.ephtype = 0;
                rec.elnum   = 0;
                rec.revnum  = 0;
                
                [~,~,~, rec] = twoline2rv( ...
                    longstr1, longstr2, typerun, typeinput, opsmode, whichconst);
                
                satrec(i)=rec;
                freq_dn_ctr(i)=f_list(cflag);
                break;
            else
                ln=ln+2;
            end
        end
    end
end

for i=validindices
    epochDay=satrec(i).epochdays;
    tsince(i)=(toa(i)-(epochDay-floor(epochDay))*86400)/60 +(d-floor(epochDay))*1440;
    [satrec(i), xyzTEME(i,:), voTEME(i,:)] = sgp4 (satrec(i),  tsince(i));
    [xyzECEF(:,i),voECEF(:,i),~]=teme2ecef(xyzTEME(i,:)',voTEME(i,:)',[0,0,0]',ttt(i),jd_UT1(i),0,0,0,2);
end

xyz=xyzECEF'*1e3;


%calculate the retarderd toas when the satellites received the beacon
%messages
dxyz=xyz-repmat(xyzb,7,1);
dr=sqrt(sum(dxyz.^2,2));
dt=dr/physconst('LightSpeed');%amount of delay
t=toa-dt;%toa at the satellite
dr_a=zeros(1,7);
xyzTEME_a = zeros(7,3);
voTEME_a = zeros(7,3);
xyzECEF_a=zeros(3,7);
voECEF_a=zeros(3,7);
dxyz_a=zeros(7,3);
%(for higher accuracy) refine the stallite position information for these
%modified instants
foa_RF_dn=zeros(1,7);
for i=validindices
    [satrec(i), xyzTEME(i,:), voTEME(i,:)] = sgp4 (satrec(i),  tsince(i)-(dt(i)/60));
    %
    jd(i)=((toa(i)-dt(i))/86400)+juliandate(date);
    jd_UT1(i) = jd(i) + UT1_UTC/86400;
    jd_TT(i)  = jd(i) + TT_UTC/86400;
    ttt(i) = (jd_TT(i)-jd2000)/36525;
    %
    [xyzECEF(:,i),voECEF(:,i),~]=teme2ecef(xyzTEME(i,:)',voTEME(i,:)',[0,0,0]',ttt(i),jd_UT1(i),0,0,0,2);
    vxyz=voECEF(:,i)'*1e3;
    f0= foa(i)+53.1311e3+freq_dn_ctr(i)-1e5;
    wvnum = f0/physconst('LightSpeed');
    dxyz(i,:)=xyz(i,:)-xyzb;
    dr(i)=sqrt(sum(dxyz(i,:).^2,2));
    dt(i)=dr(i)/physconst('LightSpeed');%amount of delay
    [satrec(i), xyzTEME_a(i,:), voTEME_a(i,:)] = sgp4 (satrec(i),  tsince(i)-((dt(i)+0.16)/60));
    %
    jd_a(i)=((toa(i)-(dt(i)+0.16))/86400)+juliandate(date);
    jd_UT1_a(i) = jd(i) + UT1_UTC/86400;
    jd_TT_a(i)  = jd(i) + TT_UTC/86400;
    ttt_a(i) = (jd_TT(i)-jd2000)/36525;
    %
    [xyzECEF_a(:,i),voECEF_a(:,i),~]=teme2ecef(xyzTEME_a(i,:)',voTEME_a(i,:)',[0,0,0]',ttt_a(i),jd_UT1_a(i),0,0,0,2);
    vxyz_a=voECEF_a(:,i)'*1e3;
    xyz_a=xyzECEF_a'*1e3;
    dxyz_a(i,:)=xyz_a(i,:)-xyzb;
    dr_a(i)=sqrt(sum(dxyz_a(i,:).^2,2));
    vcomp=0.5*(sum(((dxyz(i,:)/dr(i)).*vxyz))+sum(((dxyz_a(i,:)/dr_a(i)).*vxyz_a)));
    fd(i)=-vcomp*wvnum; 
%     fd(i) = (dr_a(i)-dr(i))/(physconst('LightSpeed')*0.16)*f0;
    foa_RF_dn(i)=f0-fd(i);
end
xyz=xyzECEF'*1e3;
dxyz1=xyz-repmat(loc,7,1);
dr1=sqrt(sum(dxyz1.^2,2));
dt1=dr1/physconst('LightSpeed');%amount of delay
foa_RF_up=foa_RF_dn-(freq_dn_ctr-406.05e6);
for i=validindices
    vxyz1=voECEF(:,i)'*1e3;
    wvnum = foa_RF_up(i)/physconst('LightSpeed');
    fd1(i)=-sum(((dxyz1(i,:)/dr1(i)).*vxyz1))*wvnum;
end
ft_err = (foa_RF_up-fd1-406.02799e6);
for hh=1:7
    if isempty(datetoa{hh})
        ft_err(hh)=0;
    end
end
fd_tot=fd+fd1;
tot_del=dt+dt1;
tdoa_err=zeros(7,7);
fdoa_err=zeros(7,7);
for i = validindices
    for j = validindices
        tdoa_actual = toa(i) - toa(j);
        tdoa_expected = tot_del(i)-tot_del(j);
        tdoa_err(i,j) = 1e6*(tdoa_actual - tdoa_expected);
        fdoa_actual = foa(i) - foa(j);
        fdoa_expected=fd_tot(i)-fd_tot(j);
        fdoa_err(i,j) = fdoa_actual - fdoa_expected;
    end
end
% fdoa_err(1,:)
% sats'
[az_exp,el_exp,~]=ecef2aer(xyz(:,1),xyz(:,2),xyz(:,3),13.035,77.512,1e3,referenceEllipsoid('WGS84'));
az_err=azs-az_exp;
el_err=els - el_exp;

flag1=sum(abs(tdoa_err(validindices,:))>100)==length(validindices)-1;
flag2=sum(abs(fdoa_err(validindices,:))>5)==length(validindices)-1;
flag3=zeros(1,7,'logical');
flag3(validindices)=abs(az_err(validindices))>5 | abs(el_err(validindices))>5;
end


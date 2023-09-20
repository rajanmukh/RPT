function [lat, lon, height,EHE,elp,resd] = tdoa3_rpt(datetoa,foa,cnr,sats)
global LIGHTSPEED;
LIGHTSPEED = physconst('LightSpeed')*1e-3;
global jd2000;
%constant
%station location
BANGALORE=1e3*[1.344164600515364   6.068648167092199   1.429495327500622]';
STATIONARY=[0,0,0]';
date2000=datetime('1-Jan-2000 12:00:00');
jd2000=juliandate(date2000);
dtDn = zeros(1,7);
dtUp = zeros(1,7);

[toa,d,date,satrec,fc,freq_trns,chn]=readSatParamsSGP(datetoa,foa,sats);

[posS,velS,dt]=actualtof(satrec,toa,d,date,BANGALORE,'downlink');
t=toa - dt;%onboard transmit/receive time

[posS1,velS1,~]=actualtof(satrec,toa-0.08,d,date,BANGALORE,'downlink');%for doppler calculation
fd=getDoppler(posS1,velS1,BANGALORE,fc);
stdtoa = 1.5;
stdfoa=0.7e-3;
[stdtoa,stdfoa]=estimateMeasError(cnr(chn));

fc1=fc-fd-freq_trns;
G=firstGuess(posS,t);
G(5)=mean(fc1);
for i=1:15
%     [posS1,dt2]=actualtof2(posS,G(1:3));
    [F,D]=FDcreator2(posS,t,posS1,velS1,fc1,G,stdtoa,stdfoa);
%     [F,D]=FDcreator3(posS1,velS1,fc1,G);
%     [F,D]=FDcreator(posS,t,G);
    [del,~,resd]= lscov(D,F);
    del(4)=del(4)*1e-3;
    G=G-del;
end
largeresd=resd>100;
location_est=G(1:3);
% t(:)=G(4);
[posS2,velS2,~]=actualtof(satrec,t-0.08,d,date,location_est,'uplink');
fd1 = getDoppler(posS2,velS2,location_est,fc1);
% % fdt=fd+fd1;
% % fdt(1:end-1)-fdt(2:end)-(fc(1:end-1)-fc(2:end))
ft=fc1-fd1;
% ft=G(4);
ttx=t-tof(posS,location_est);
% ttx=G(4);
% ft=G(5);
lla=ecef2lla(1e3*G(1:3)');
lat=lla(1);
lon=lla(2);
height=lla(3)*1e-3; %in km
erroneous_channel1=abs(ft-mean(ft(~isoutlier(ft))))>10;
erroneous_channel2=abs(ttx-mean(ttx(~isoutlier(ttx))))>10e-5;
erroneous_channel=erroneous_channel1|erroneous_channel2;
if any(erroneous_channel) || largeresd
    lat=NaN;
    lon=NaN;
    if(length(ft)-sum(erroneous_channel)>=3)
%         'possible impossible'
    else
%         'Absolutely impossible'
    end
    EHE=NaN;
    elp=[];
else
    [jdop,elp]=computeDOP(D,lat*pi/180,lon*pi/180); 
    EHE=2.5*jdop;
end
end

function [toa,d,date,satrec,fc,freq_trns,chnls]=readSatParamsSGP(datetoa,foa,sats)
global list;
%constant
f_list=[1544.1e6,1544.21e6,1544.9e6];

opsmode='a';
typerun='m';
typeinput='m';
whichconst=84;
rad = 180.0 / pi;
type=zeros(1,7);
% freq_dn_ctr=zeros(1,7);
j=1;
for i=1:7
    if ~isempty(datetoa{i})
        %toa
        datestr=split(datetoa{i},' ');
        dt=char(datestr(1));
        yy=dt(1:2);
        DDD=dt(4:end);
        yyyy=num2str(str2double(yy)+2000);
        date=datetime([yyyy,'-',DDD,'-','00','-','00','-','00'],'InputFormat','uuuu-DDD-HH-mm-ss');
        d=str2double(DDD);
        tme=split(datestr(3),':');
        toa(j)=[3600 60 1 1e-3 1e-6 1e-9]*str2double(tme)+0.16;
        % find satellite positions at respective toas from tle info
        
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
                    
                    satrec(j)=rec;
                    freq_trns(j)=f_list(cflag)-406.05e6;
                    fc(j)= foa(i)+53.1311e3+f_list(cflag)-1e5;
                    chnls(j)=i;
                    j=j+1;
                    break;
                else
                    ln=ln+2;
                end
            end
        end
    end
end
end

function [pos,vel]=getSatPosVel(satrec,t,d,date)
global jd2000;
UT1_UTC=-0.06;
TT_UTC=69.2;
noOfSats = length(satrec);
pos = zeros(3,noOfSats);
vel = zeros(3,noOfSats);
for i=1:noOfSats
    epochDay=satrec(i).epochdays;
    tsince=(t(i)-(epochDay-floor(epochDay))*86400)/60 +(d-floor(epochDay))*1440;
    [~, pos1, vel1] = sgp4 (satrec(i),  tsince);
    jd=(t(i)/86400)+juliandate(date);
    jd_UT1 = jd + UT1_UTC/86400;
    jd_TT  = jd + TT_UTC/86400;
    ttt = (jd_TT-jd2000)/36525;
    [pos(:,i),vel(:,i),~]=teme2ecef(pos1',vel1',[0,0,0]',ttt,jd_UT1,0,0,0,2);
end
end

function [pos]=adjustRotation(xyz,dt)
omega_dot_earth = 7.2921151467e-5; %(rad/sec)
ths=omega_dot_earth*dt;
pos=zeros(size(xyz));
for i=1:length(dt)
    th=ths(i);
    R=[cos(th) sin(th) 0; -sin(th) cos(th) 0;0 0 1];
    pos(:,i)=R*xyz(:,i);
end
end

function dt=tof(pos1,pos2)
global LIGHTSPEED;
d=sqrt(sum((pos1-pos2).^2));
dt=d/LIGHTSPEED;
end


function [F,D] = FDcreator(posS,t,G)
global LIGHTSPEED;
xyz=G(1:3);
tg=G(4);
R=sqrt(sum((xyz-posS).^2));
F=(R-LIGHTSPEED*(t-tg))';
D=zeros(length(t),4);
D(:,1:3)=((1./R).*(xyz-posS))';
D(:,4)=1e-3*LIGHTSPEED;
end

function [F,D] = FDcreator1(posS,t,G)
global LIGHTSPEED;
xyz=G(1:3);
tg=G(4);
R=sqrt(sum((xyz-posS).^2));
R(end+1)=sqrt(sum(xyz.^2));
obs_range=[LIGHTSPEED*(t-tg) 6375];
F=(R-obs_range)';
D=zeros(length(t)+1,4);
D(1:length(t),1:3)=((1./R(1:length(t))).*(xyz-posS))';
D(1+length(t),1:3)=((1./R(1+length(t))).*xyz)';
D(1:length(t),4)=1e-3*LIGHTSPEED;
end

function [F,D] = FDcreator2(posS,t,posS1,velS1,freq,G,stdtoa,stdfoa)
noOfSat = length(t);
if noOfSat == 3
    [F1,D1]=FDcreator1(posS,t,G(1:4));
    stdtoa=[stdtoa;2];
else
    [F1,D1]=FDcreator(posS,t,G(1:4));
end
[F2,D2]=FDcreator3(posS1,velS1,freq,G([1,2,3,5]));
F=[F1./stdtoa;F2./stdfoa];
D=zeros(length(F),5);
D(1:length(F1),1:4)=D1./stdtoa;
D(length(F1)+1:length(F),[1:3,5])=D2./stdfoa;
end

function [F,D] = FDcreator3(posS,velS,freq,G)
global LIGHTSPEED;
noOfSat=length(freq);
F=zeros(noOfSat,1);
xyz=G(1:3);
fg=G(4);
dxyz=posS-xyz;
dr=sqrt(sum(dxyz.^2));
uvw=dxyz./dr;
vcomp=sum(uvw.*velS);
wvlen = LIGHTSPEED./freq;
fd=freq-fg;
F(1:noOfSat)=(vcomp+wvlen.*fd)';

D=zeros(noOfSat,4);
D(:,1:3) = ((1./dr).*(-velS+uvw.*vcomp))';
D(:,4) = -wvlen';
end

function [G] = firstGuess(pos,t)
%FIRSTGUESS Summary of this function goes here
%   Detailed explanation goes here
EARTHCENTER=[1000;6000;1000];
dt=tof(pos,EARTHCENTER);
G=[EARTHCENTER;mean(t-dt)];
end

function[posS,velS,dt]= actualtof(satrec,t,d,date,place,journey)
dt=0;
 for i=1:3
     if strcmp(journey,'downlink')
        [posS,velS]=getSatPosVel(satrec,t-dt,d,date);
     else
         [posS,velS]=getSatPosVel(satrec,t+dt,d,date);
     end
    dt=tof(posS,place);    
end
end

function [posS,dt]=actualtof2(posS,place)
for j=1:3
    dt=tof(posS,place);
    [posS] = adjustRotation(posS,-dt);
end
end

function fd=getDoppler(posS,velS,place,freq)
global LIGHTSPEED;
wvnum = freq/LIGHTSPEED;
dxyz=posS-place;
dr=sqrt(sum(dxyz.^2));
uvw=dxyz./dr;
vcomp=sum(uvw.*velS);
fd=-vcomp.*wvnum; 
end

function [JDOP,elpse] = computeDOP(D,lat,lon)
R=[-sin(lon) cos(lon) 0;-sin(lat)*cos(lon) -sin(lat)*sin(lon) cos(lat);cos(lat)*cos(lon) cos(lat)*sin(lon) sin(lat)];
P = inv(D'*D);
Q=R*P(1:3,1:3)*R';
varN=abs(Q(1,1));
varE = abs(Q(2,2));
varNE=Q(1,2);
JDOP=sqrt(varN+varE);
K=sqrt((varN-varE)^2+4*abs(varNE)^2);
varU=(varN+varE+K)/2;
varV=(varN+varE-K)/2;
offset = 0;
if sign(real(varNE))<0
   offset=180; 
elseif sign(real(varN) - real(varE))<0 
   offset=360;
end   
A=90*atan(2*real(varNE)/(real(varN) - real(varE)))/pi + offset;
elpse=[1.4*sqrt(varU),1.4*sqrt(varV),A];
end

function [terrstd,ferrstd] = estimateMeasError(cbn0)
  terrstd=0.3*(15*2.^((-cbn0+35)/6));
  ferrstd=0.7*(0.2*2.^((-cbn0+35)/6)+1);
end



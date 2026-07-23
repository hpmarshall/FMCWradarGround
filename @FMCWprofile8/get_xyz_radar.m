function obj=get_xyz_radar(obj)
% HPM 08/03/10
% this function interpolates the GPS data to get an x,y,z for each radar
% trace, removing bad GPS and locations near sky calibrations first
% Updated 05/17/12 to interpolate based on time
% Updated 07/31/12 to fix some errors
disp('filtering GPS and interpolating for each trace')
% first get the good GPS measurements and those during sky calibrations
if ~isempty(obj.G.xyz)
    XYZ=zeros(length(obj.G.xyz(:,1)),3)*NaN; % initialize GPS position vector
    RT=zeros(length(obj.G.xyz(:,1)),1)*NaN; % initialize radar time for GPS positions
    for n=1:length(obj.G.xyz) % loop over all the GPS locations
        if ~isempty(obj.S.SkycalTraces) % if sky cal traces have been stored
            dt=abs(obj.G.time(n)-obj.CPUtime(obj.S.SkycalTraces)); % get time difference to all sky cal traces
            dt=min(dt)*24*60*60; % minimum time difference in seconds
        else
            dt=999; % no sky cal traces defined, set dt large
        end
        % get gps far from sky cal, with low HDOP and xyz positions
        if (dt>obj.G.dtSkyCal & obj.G.HDOP(n)<obj.G.maxHDOP & isfinite(sum(obj.G.xyz(n,:))))  % if good GPS
            XYZ(n,:)=obj.G.xyz(n,:); % store XYZ
            DF=obj.G.daqfile(n);  % store radar daq file
            I3= obj.filenumber==DF; % find all the radar traces with this filenumber
            if ~isempty(find(I3))
                RT(n)=min(obj.CPUtime(I3)); % get the time of the first radar trace in this file
            end
        end
    end
    I2=find(isfinite(sum(XYZ,2)) & isfinite(RT)); % get the good GPS with a good radar time
    XYZ=XYZ(I2,:); RT=RT(I2);
    if ~isempty(obj.S.ProfileTraces)
        RT2=obj.CPUtime(obj.S.ProfileTraces); % get CPU time for all profile traces
    else
        RT2=obj.CPUtime;
    end
    % remove profiles not bounded by good GPS
    if (~isempty(RT) & ~isempty(RT2))
        I2=find(RT2<min(RT) | RT2>max(RT));
        RT2(I2)=NaN;
        I3=isfinite(RT2);
        % use the good GPS to get coordinates for all radar traces
        Rx=ones(length(RT2),1)*NaN;
        Ry=ones(length(RT2),1)*NaN;
        Rz=ones(length(RT2),1)*NaN;
        % here we use CPU time of GPS measurement (RT) and CPU time of radar trace (RT2) 
        % and "pchip" to interpolate between GPS locations for each trace
        Rx2=pchip(RT,XYZ(:,1),RT2(I3));
        Ry2=pchip(RT,XYZ(:,2),RT2(I3));
        Rz2=pchip(RT,XYZ(:,3),RT2(I3));
        Rx(I3)=Rx2; Ry(I3)=Ry2; Rz(I3)=Rz2;
        obj.xyz=[Rx(:) Ry(:) Rz(:)]; % store in the FMCWprofile object
    else
        disp('No good GPS coincident with good radar, skipping this directory...')
        obj.xyz=[];
    end
else
    disp('No good GPS recorded, skipping this directory...')
    obj.xyz=[];
end
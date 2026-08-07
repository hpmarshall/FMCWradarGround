function obj=get_GPS(obj)
% HPM 07/28/10
% this function gets the GPS coordinates associated with a given object
% Reads a GPSdata.txt-style file containing GGA sentences, one per line,
% either prefixed with "<filenumber>," (onboard acquisition GPS logger) or
% bare (standalone GPS logger, e.g. a Geode) - both are auto-detected.
if isempty(obj.G.xyz)
    GPSfile=dir([obj.data_dir 'G*.txt']);
    fid=fopen([obj.data_dir GPSfile.name]);
    S=textscan(fid,'%s');
    if ~isempty(S{1})
        m=1;
        M=zeros(length(S{1}),9); % initialize
        for n=1:length(S{1})
            S2=S{1}{n}; % current line
            % locate a GGA sentence within the line: either prefixed with
            % "<filenumber>," by the onboard acquisition GPS logger (e.g.
            % GPSdata.txt, tying each fix to a specific radar file), or bare
            % (e.g. from a standalone GPS logger not tied to the radar's
            % internal file counter - see get_xyz_radar for how these are
            % matched to radar traces without a filenumber)
            k=regexp(S2,'\$G[PN]GGA','once');
            if (~isempty(k) && length(S2)>50 && length(S2)<90)
                if k>1 % prefixed with "<filenumber>,"
                    d=textscan(S2,'%f,%6c,%f,%f,%1c,%f,%1c,%f,%f,%f,%f,%1c,%f,%1c');
                else % bare GGA sentence, no filenumber prefix
                    d0=textscan(S2,'%6c,%f,%f,%1c,%f,%1c,%f,%f,%f,%f,%1c,%f,%1c');
                    d=[{NaN} d0]; % pad so field indices line up with the prefixed case
                end
                % next put NaNs in fields that didn't convert correctly
                for p=1:length(d);
                    if isempty(d{p})
                        d{p}=NaN;
                    end
                end
                M(m,:)=[d{1} d{3} d{4} d{6} d{11} d{13} d{9} d{10} d{8}];
                m=m+1;
            end
        end
        
        M=M(1:m-1,:); % remove trailing zeros
        
        %% get latitude and longitude
        Lat=zeros(length(M),1)*NaN;
        Lon=zeros(length(M),1)*NaN;
        [Mr,~]=size(M);
        for n=1:Mr
            L1=strtrim(num2str(M(n,3))); % change latitude to a string and remove white spaces
            L1b=num2str(round(M(n,3)));
            if length(L1b)>4 % if over 100
                Lat(n)=str2double(L1(1:3))+str2double(L1(4:end))/60;
            else
                Lat(n)=str2double(L1(1:2))+str2double(L1(3:end))/60;
            end
            L1=num2str(M(n,4)); % change longitude to a string
            L1b=num2str(round(M(n,4)));
            if length(L1b)>4 % if over 100
                Lon(n)=str2double(L1(1:3))+str2double(L1(4:end))/60;
            else
                Lon(n)=str2double(L1(1:2))+str2double(L1(3:end))/60;
            end
        end
        
        %% now convert to UTM
        ind=find(Lat>0 & Lon>0 & Lat<180 & Lon<180);
        Lon=-Lon(ind); % make negative
        Lat=Lat(ind);
        [x,y] = ll2utm(Lat, Lon);
        C=[x(:) y(:) M(ind,5)];
        
        %% now get GPStime for each position
        GPSstr=num2str(M(:,2),'%6.1f'); % get GPS time, but needs to be converted.
        I7=isspace(GPSstr); % find empty spaces caused by hour, minute=00
        GPSstr(I7)='0'; % set them equal to zero
        GPStime=[str2num(GPSstr(:,1:2)) str2num(GPSstr(:,3:4)) str2num(GPSstr(:,5:end))];
        disp(GPStime);
        GPStime=datenum([ones(length(M(:,2)),1)*obj.date GPStime]); % GPStime in day.dec
        
        %% now get tracenumber for each position
        daqfile=M(ind,1); % get the radar file number for each GPS
        NumSat=M(ind,7);
        HDOP=M(:,8);
        Fix=M(:,9);
        %%
    else
        C=[];
        GPStime=[];
        daqfile=[];
        Fix=[];
        NumSat=[];
        HDOP=[];
    end
    fclose(fid);
    G=GPS;
    G.xyz=C;
    G.time=GPStime;
    G.daqfile=daqfile;
    G.NumSat=NumSat;
    G.HDOP=HDOP;
    G.Fix=Fix;
    obj.G=G;
end
if length(G.xyz)>9 % if there are at least 10 GPS locations, make a plot
    figure(1);clf
    dx=min(G.xyz(:,1));
    dy=min(G.xyz(:,2));
    plot(G.xyz(:,1)-dx,G.xyz(:,2)-dy,'o')
    hold on
    I9=find(ismember(G.daqfile,obj.P.files)); % GPS data associated with the files of interest
    plot(G.xyz(I9,1)-dx,G.xyz(I9,2)-dy,'rx')
    obj.FEFN=[dx dy]; % False Easting and Northing
end


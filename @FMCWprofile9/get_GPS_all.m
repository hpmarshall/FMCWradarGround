function obj=get_GPS_all(obj)
% HPM 07/16/12
% this function gets the GPS coordinates in all subdirectories
% NOTE: this currently only works with the newest GPS files (GPSdata.txt)

if isempty(dir([obj.proc_dir 'GPS_all.mat'])) % if GPS data has not been processed
    G=GPS; % create GPS object
    for n=1:length(obj.subdir)
        n
        disp(obj.subdir{n})
        flag=dir([obj.data_dir obj.subdir{n} '/' 'G*.txt']); % check for GPS file
        if ~isempty(flag)
            rd=FMCWprofile9;
            rd.data_dir=[obj.data_dir obj.subdir{n} '/'];
            rd=get_GPS(rd);
            if ~isempty(rd.G.xyz)
                G(n)=rd.G; % store the GPS data
            end
            rd.G=[]; % remove the GPS field for the next directory
        end
    end
    save([obj.proc_dir 'GPS_all'],'G')
    obj.G=G; % store in the stucture array
else
    disp('GPS already processed, loading from PROC')
    load([obj.proc_dir 'GPS_all'])
    obj.G=G; % store the GPS data that was loaded
end


c='rgbykm';
m='ox+s^*dv><ph';
M=[];
for n=1:length(G)
    M=[M;G(n).xyz];
end
obj.FEFN=[median(M(:,1)) median(M(:,2))];
h=zeros(1,length(G));
plotmap=0;
if plotmap
    figure(1);clf
    for n=1:length(G)
        n
        q=ceil(n/5);
        if ~isempty(G(n).xyz)
            h(n)=plot(G(n).xyz(:,1)-obj.FEFN(1),G(n).xyz(:,2)-obj.FEFN(2),[c(rem(n,5)+1) m(q)]);
        else
            h(n)=plot(0,0,'kx')
        end
        hold on
    end
    legend(h,obj.subdir)
    set(gca,'FontSize',14,'FontWeight','bold','LineWidth',2)
    xlabel('False Easting [m]')
    ylabel('False Northing [m]')
    title(['Origin: N= ' num2str(obj.FEFN(1)) ', E= ' num2str(obj.FEFN(2))])
end


% figure(1);clf
% dx=min(obj.xyz_GPS(:,1));
% dy=min(obj.xyz_GPS(:,2));
% plot(obj.xyz_GPS(:,1)-dx,obj.xyz_GPS(:,2)-dy,'o')
% hold on
% I9=find(ismember(obj.GPSrtrace,obj.files)); % GPS data associated with the files of interest
% plot(obj.xyz_GPS(I9,1)-dx,obj.xyz_GPS(I9,2)-dy,'rx')
% obj.FEFN=[dx dy]; % False Easting and Northing


function obj=plot_image(obj)
% HPM 07/28/10
% this function plots a FMCWprofile object


% first check to see if processed yet
pdir=obj.pdir; % processed directory
if ~exist(pdir) % if directory exists, entire profile has been processed in 100 file increments
    disp('New profile, creating directory to store processed results:')
    mkdir(pdir)
    pdir
end

%% lets grab sets of 25 for processed files
nb=25; % number of files in a batch
minF=min(obj.files); maxF=max(obj.files); % get min and max file number to look at
disp(['processing files: ' num2str(minF) ' to ' num2str(maxF)])
s1=(floor(minF/nb))*nb+1; % start file
s2=(ceil(maxF/nb))*nb; % stop file
nbatch=floor((s2-s1)/nb)+1 % number of batches
for n=1:nbatch
    n
    s3=s1+(n-1)*nb;
    s4=min([s3+nb-1 maxF]); 
    pfile=[pdir 'PRD' num2str(s3) '-' num2str(s4)] % processed file
    if exist([pfile '.mat']) % if its been processed
        disp(['file: ' pfile ' already processed, loading'])
        load([pdir 'PRD' num2str(s3) '-' num2str(s4)]); % load the first one
    else % if not processed
        disp(['file: ' pfile ' not processed - please wait for crunch'])
        rd=obj;
        rd.files=s3:s4; % set the files to process
        rd = process_tdata(rd) % process those files
    end
    [n3,m3]=size(rd.PDATA); % get the size
    [n4,m4]=size(rd.TDATA); % get the size
    if n==1 % if first file
        nw=floor(n3/2); % keep upper half
        obj.PDATA=zeros(nw,m3*nbatch); % preallocate
        obj.TDATA=zeros(n4+10,m4*nbatch); % preallocate, account for traces with a few extra
    end
    t1=(n-1)*m3+1; % starting trace
    t2=t1+m3-1;    % ending trace
    obj.PDATA(:,t1:t2)=rd.PDATA(1:nw,:); % grab upper half of result
    obj.TDATA(1:n4,t1:t2)=rd.TDATA; % grab all the TDATA
    obj.CPUtime(t1:t2,1)=rd.CPUtime; % store CPUtime
    s5=s3-s1+1; % file index for CPUtime for each radar daq file
    s6=s5+length(rd.CPUtime_GPS)-1; % end file for CPUtime
    obj.CPUtime_GPS(s5:s6,1)=rd.CPUtime_GPS;
end
obj.w=rd.w(1:nw);
obj.TWT=rd.TWT(1:nw);
obj.Fs=rd.Fs;
% now get a position for each and every trace
Rx=pchip(obj.CPUtime_GPS,obj.xyz_radar(:,1),obj.CPUtime);
Ry=pchip(obj.CPUtime_GPS,obj.xyz_radar(:,2),obj.CPUtime);
Rz=pchip(obj.CPUtime_GPS,obj.xyz_radar(:,3),obj.CPUtime);
obj.xyz_radar_trace=[Rx Ry Rz];
figure(2);clf
[n5,m5]=size(obj.PDATA);
h=imagesc((1:m5),obj.w,obj.PDATA,[-100 -65]);
axis([1 m5 1 max(obj.w)])
xlabel('trace #')
ylabel('frequency difference [Hz]')
colorbar 
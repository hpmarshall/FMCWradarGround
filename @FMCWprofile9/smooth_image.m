function obj=smooth_image(obj)
% this FMCW method evaluates the image at specified points and
% smooths over the specified window

xm=obj.smooth_x; ym=obj.smooth_y; % locations to estimate at
xyR=obj.xyz_radar_trace; % radar trace coordinates
[n5,m5]=size(obj.PDATA);
P2=zeros(n5,length(xm)); % estimates at all points xm
P3=10.^(obj.PDATA/10); % convert back from dB
for n=1:length(xm)
    if ~rem(n,100)
        n
    end
    dist=sqrt((xyR(:,1)-xm(n)).^2+(xyR(:,2)-ym(n)).^2); % distance to all traces
    ival=find(dist<obj.smooth_window); % use only the points within winsize of xmod 
%     if isempty(ival) % if no points, double the window size for just this trace
%         ival=find(dist<2*obj.smooth_window); % use only the points within 2*winsize of xmod 
%         obj.smooth_window=obj.smooth_window*2;
%     end
%     if isempty(ival)
%         ival=find(dist<4*obj.smooth_window);
%         obj.smooth_window=obj.smooth_window*2;
%     end
%     if isempty(ival)
%         ival=find(dist<8*obj.smooth_window);
%         obj.smooth_window=obj.smooth_window*2;
%     end
    if isempty(ival)
        P2(:,n)=NaN*ones(n5,1); % give a NaN if xmod has no data within winsize
    else
        weights=15/16*(1-(dist(ival)/obj.smooth_window).^2).^2; % bi-square kernal of weights
        W=ones(n5,1)*weights(:)'; % weight matrix
        P2(:,n)=sum(W.*P3(:,ival),2)./sum(W,2); % non-param estimate
    end
end
obj.PDATA=10*log10(P2); % convert back to dB
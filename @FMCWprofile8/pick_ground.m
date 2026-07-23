function obj = pick_ground(obj)
% HPM 11/2/11
% this method picks the ground reflection

% first apply a 10x10 convolution

hw=10
cI=-hw:hw;
wc=15/16*(1-(cI/hw).^2).^2;
hr=10
rI=-hr:hr;
wr=15/16*(1-(rI/hr).^2).^2;
P3=conv2(wc,wr,10.^(obj.PDATA/10),'same');
P3=10*log10(P3);

%P3=obj.PDATA;
[~,m6]=size(P3);
Isurf2=ones(1,m6); % surface 
I2=1:obj.Gmin; % set range for depth search
for n=1:m6
    if isfinite(sum(P3(I2,n)))
        I3=find(imregionalmax(P3(I2,n),[0 1 0;0 1 0;0 1 0])); % get all the peaks
        I4=find(P3(I3,n)>obj.Gthresh); % find peaks above the threshold
    else
        I4=[];
    end
    if ~isempty(I4)
        peaks=I3(I4); % all the peaks within range above the threshold
        Iground(n)=peaks(end); % index to first peak above threshold
    else
        Iground(n)=NaN;
    end
end
obj.Iground=Iground;
%obj.PDATA=P3;
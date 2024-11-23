% pick_freqrange2 - this is for TEST_FMCW4
% HPM  02/02/04
% this function picks the requested frequency range out of the 
%  aquired data, by searching for the indicies to the points taken within a
%  given voltage (frequency) range
% INPUT: fullBW = full-scale (max) bandwidth of oscillator [GHz]
%        minfreq = minimum frequency of oscillator [GHz]
%        startfreq = start frequency [GHz]
%        stopfreq = stop frequency [GHz]
%        ramp_sample = sample of recorded ramp [nst,1]
% OUPUT: trace_index = start,stop index for each trace [nramps,2] 
% SNTX: [trace_index] = pick_freqrange(fullBW,minfreq,startfreq,stopfreq,ramp_sample)

function [trace_index] = pick_freqrange2(fullBW,minfreq,startfreq,stopfreq,ramp_sample)

voltrange=([startfreq stopfreq]-minfreq)*10/fullBW; % calculate voltage range
trace_index=find(ramp_sample>min(voltrange) & ramp_sample<max(voltrange)); % find points within range
ind_end=find(diff(trace_index)>1);
ind2=find(ind_end>50);
if ind2
  trace_index=trace_index(1:ind_end(ind2(1))); % pick out points within range, not on downsweep
end
% trans=find(diff(index)>50); % find transition points of ramps
% nramps=length(trans)+1; % number of ramps
% start=1;
% j=1;
% for i=1:length(trans)
%     if index(start) ~= index(trans(i))
%        trace_index(j,:)=[index(start) index(trans(i))];
%        start=trans(i)+1;
%        j=j+1;
%     end
% end
% if index(start) ~= max(index)
%     trace_index(j,:)=[index(start) max(index)];
% end
% check it!
%figure(1); clf
%x=1:length(ramp_sample);
%plot(x,ramp_sample);
%hold on; plot(x(trace_index),ramp_sample(trace_index),'rx')
%ramp_sample(trace_index);




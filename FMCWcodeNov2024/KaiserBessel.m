% KaiserBessel.m
% HPM  02/03/04
% this function gives a Kaiser-Bessel window (Harris,1978)
% INPUT: N= number of samples
%    alpha = parameter, where pi*alpha=1/2(time-bandwidth product)
%         increasing alpha decreases side-lobe level at expense of
%         increasing the time-bandwidth product
%      THEREFORE: small alpha gives better resolution, but more effect to
%      nearby frequencies...so use small alpha for determining location of
%      strong signals, but will need larger alpha to resolve weak signals..
% OUTPUT: w = window weights
% SNTX: w = KaiserBessel(N,alpha)


function w = KaiserBessel(N,alpha)

I0=besseli(0,pi*alpha); % zero-order modified bessel function of the first kind

n=-N/2:N/2; % sample points
X=pi*alpha*sqrt(1.0-(n/(N/2)).^2); % input to modified bessel function

w=besseli(0,X)./I0; % weights
w=w(1:length(w)-1)'; % make it a column vector
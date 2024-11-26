% plot Utqiagvik radar transect

figure(6);clf; subplot(1,5,1:4)
imagesc(rmod2,depth,10*log10(PDATA3),[-85 -65]); colorbar;
set(gca,'FontSize',14,'FontWeight','bold','LineWidth',2)
xlabel('distance from shore [m]')
ylabel('depth in snow [cm]')
axis([0 500 -50 90])
text(160,-15,'snow surface','FontSize',16,'FontWeight','bold','Color','w')
text(175,45,'snow-ice interface','FontSize',16,'FontWeight','bold','Color','w')
text(300,-40,'instrumentation noise','FontSize',16,'FontWeight','bold','Color','w')
hold on
plot([100 100],[-40 100],'r-','linewidth',2)
title('6-18 GHz FMCW radar [dB]')
subplot(1,5,5)
h(1)=plot(PDATA3(:,1001),depth,'r-','linewidth',3)
set(gca,'FontSize',14,'FontWeight','bold','LineWidth',2,'ydir','reverse')
axis([0 3e-7 -50 90])
text(1e-8,-2,'snow surface','FontSize',16,'FontWeight','bold','Color','k')
text(1.8e-7,15,'snow-ice','FontSize',16,'FontWeight','bold','Color','k')
hold on
h(2)=plot([0 3e-7],[0 0],'k-.','linewidth',2)
h(3)=plot([0 3e-7],[13 13],'b-','linewidth',2)
h2=legend(h,'radar trace @ 100m','snow surface','probe depth')
set(h2,'FontSize',16,'FontWeight','bold','Location','SouthWest')
ylabel('depth in snow [cm]')
xlabel('amplitude')

figure(11);clf
subplot(2,3,[1 2 4 5])
h(1)=plot(rmod,MPdepth,'bo-','LineWidth',2)
hold on
h(2)=plot(rmod,RadarDepth,'ro-','LineWidth',2)
set(gca,'FontSize',14,'FontWeight','bold','LineWidth',2)
xlabel('distance from shore [m]')
ylabel('snow depth [cm]')
h2=legend('MagnaProbe depth','FMCW radar depth')
set(h2,'FontSize',16,'FontWeight','bold','Location','NorthEast')
text(600,40,'R=0.74','FontSize',16,'FontWeight','bold','Color','k')
text(600,38,'RMSE=5.08 cm','FontSize',16,'FontWeight','bold','Color','k')
subplot(2,3,[3 6])
L={'MagnaProbe','Radar'};
hB=boxplot([MPdepth(:) RadarDepth],'notch','on','labels',L)
set(gca,'FontSize',14,'FontWeight','bold','LineWidth',2)
set(hB,{'linew'},{2})
ylabel('snow depth [cm]')
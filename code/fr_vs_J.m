J=-2:.1:7;
dt=1/60;
FR=(1-exp(-exp(J)*dt))/dt;

figure(1), clf
plot(J,FR,'k','linewidth',2)
fs=12;
ylab=ylabel([{'Expected Firing Rate'}],'FontSize',fs); % %,'Interpreter','latex');
% set(ylab,'Rotation',0,'HorizontalAlignment','right','verticalalignment','middle')
xlabel('$J$','Interpreter','latex')
axis('tight')

wh = [7 4];
set(gcf,'PaperSize',wh,'PaperPosition',[0 0 wh],'Color','w');
FigName = ['~/Research/oopsi/pop-oopsi/figs/fr_vs_J'];
print('-depsc',FigName)
print('-dpdf',FigName)
% Plot Advection Tests using plot_2dadv.m
% By: Devin Light
% ------

clear all;
close all;
clc;
%%
cd('/Users/Devin/Desktop/R/ModalDG/2d_adv/terminatorTest');

tests = {
         'def_cosinebell', ... % 1, LeVeque deformation test cosinebell                          
         'def_cyl',... % 2, Deformation flow applied to slotted cylinder
         'consistency',... %3 uniform field deformation flow
         };
res = {'1','2','3','4'};
methods = { 'modal',...
            'modalPD'
          };

whichTest = tests(1);
whichRes = res(2);

ncfilename = strcat('spltMod2d_' ,whichTest{1}, '.nc');
%% Read in data
ntest = 1;
meqn = 1;
whichRes = res(2);
whichTest = tests{ntest};

subDir = '';
whichMethods = [1 2];
ncfilename = strcat('spltMod2d_' ,whichTest, '.nc');

for imethod=1:length(whichMethods)
    nmethod = whichMethods(imethod);
    methName = methods{nmethod};
    error = [];
    einf = [];
    if(nmethod == 1)
        methname = 'Modal Unlimited';
        nc = ['_modal/' subDir ncfilename];
        out = plot_2dadv(methname,whichTest,nc,whichRes);
        out.figLabel = 'a';
    elseif(nmethod == 2)
        methname = 'Modal PD';
        nc = ['_pdModal/' subDir ncfilename];
        out = plot_2dadv(methname,whichTest,nc,whichRes);
        out.figLabel = 'b';
    end
    meth.(methName) = out;
    ic = squeeze(out.data(1,:,:));
    final = squeeze(out.data(end,:,:));
    disp(min(final(:)));
            
    % Compute error            
    nError = sqrt(mean( (ic(:)-final(:)).^2 ));
    error = [error nError];
    meth.(methName).error = error;
            
    nError = max(abs(ic(:)-final(:)));
    einf = [einf nError];
    meth.(methName).einf = einf;

end
%% Make Comparison Figure for this resolution
FS = 'FontSize';
cd('/Users/Devin/Desktop/R/ModalDG/2d_adv/terminatorTest/');
close all

print_errors    = 1;
print_label     = 1;
plotICs         = 1;
numRows         = 1;
figsPerRow      = 1;
saveFigure      = 0;

outDir = ['_figs/_' whichTest];

for imethod=1:length(whichMethods)
    nmethod = whichMethods(imethod);
    if(ntest == 1)
        xloc1 = 0.1; xloc2 = 0.50;
        yloc1 = 0.65; yloc2 = 0.75;
        excontours = [.05 .75]; clvls = 0.1:0.1:1.0;
    end

    xwidth = 400; ywidth = 400;
    fig = figure();
    set(gcf, 'PaperUnits', 'points');
    set(gcf,'PaperPositionMode','auto','PaperSize',[xwidth ywidth]);
    set(fig, 'Position', [0 0 xwidth ywidth])

    methName = methods{nmethod};
    currMeth = meth.(methName);
    disp(['Plotting: ' methName]);
    
    ics = squeeze(currMeth.data(1,:,:));
    final = squeeze(currMeth.data(end,:,:));
    
    final(final < 0) = final(final<0)+10^(-15);
    
    x = currMeth.x;
    y = currMeth.y;
    
    err2 = sprintf('%#.3g',currMeth.error);
    einf = sprintf('%#.3g',currMeth.einf);
    
    hold on
    [C,h] = contour(x,y,final,clvls);
    set (h, 'LineWidth', 1,'LineColor','k');
    
    clvls = -1*[1 1]*10^(-14);
    [C,h] = contour(x,y,final,clvls,'LineWidth',0.5,'LineColor',[0.75 0.75 0.75]);
    %set(h,'LineWidth', 0.2,'LineColor',[0.95 0.95 0.95]);

    if(plotICs)
        [C,h] = contour(x,y,ics,excontours);
        set (h, 'LineWidth', 2,'LineColor','k');        
        axis square
    end
    hold off
    
    xlabel('x',FS,18); ylabel('y',FS,18);
    set(gca,'XTick',[0:.2:1],'YTick',[0:0.2:1]);

    if(print_errors == 1)
        text(xloc1,yloc1,['E_2= ' err2],FS,18 );
        text(xloc1,yloc2,['E_{\infty}= ' einf],FS,18 );
        text(xloc2,yloc1,sprintf('Max_ = %4.3f', max(final(:))),FS,18 );
        text(xloc2,yloc2,sprintf('Min_ = %4.3f', min(final(:))),FS,18 );
    end
    
    if(print_label)
        if(ntest == 1)
            hLu = text(0.05,0.95,[currMeth.figLabel ') ' currMeth.method],FS,18); 
            axis([-0.005 1.005 -0.005 1.005]);
        end
    end
    
    opos = get(gca,'OuterPosition');
    pos = get(gca,'Position');
    
    currLabel = currMeth.figLabel;
    if( (figsPerRow*numRows-(currLabel-'a')) > 2)
        xtl = '';
        set(gca,'XTickLabel',xtl,FS,8);
        xlabel('');
    end
    if( mod(currLabel-'a',figsPerRow) ~= 0)
        ytl = ''; yaxlab = '';
        set(gca,'YTickLabel',ytl,FS,8);
        ylabel('');
    end

    set(gca,FS,16,'Position',pos,'OuterPosition',opos);
    box on;

    pow = str2double(whichRes);
    nelem = length(squeeze(currMeth.data(1,:,:)))/(currMeth.N+1);
    name = [methName '/' subDir methName '_2d', num2str(nelem),'e','.pdf'];
    name = [outDir name];
    
    if(saveFigure == 1)
        print(fig,'-dpdf',name);
    end
end
%%
close all;
x = out.x; y = out.y; t = out.t;
%{
ics = squeeze(out.data(1,:,:));
fig = figure();
contourf(x,y,ics);
title(['t=' num2str(t(1))]);

fig = figure();
final = squeeze(out.data(2,:,:));
contourf(x,y,final);
title(['t=' num2str(t(2))]);

fig = figure();
final = squeeze(out.data(end,:,:));
contourf(x,y,final);
title(['t=' num2str(t(end))]);
%}

fig = figure();
for n=1:length(t)
    plt = squeeze(out.data(n,:,:));
    contourf(x,y,plt);
    title(['t=' num2str(t(n))]);
    pause(1.0);
end
pause(0.5);close all;

%% Theta_K comparison: 3 deg vs 6 deg
clearvars; close all; clc

%% Load results
load('Statistics_Thetha_K_DLC1p2_8MW.mat','Statistics');

%% Wind speeds used in the screening simulations
WindSpeedBins = [12 16 20 24];
% WindSpeedBins = [24];
%% Optimization variables
ThetaK_deg = [7 8];

nWind = length(WindSpeedBins);
nThetaK = length(ThetaK_deg);
nSeed = 3;

%% Pre-allocate result matrices
% Rows = wind speeds
% Columns = Theta_K values

TowerDEL    = zeros(nWind,nThetaK);
ShaftDEL    = zeros(nWind,nThetaK);
BladeDEL    = zeros(nWind,nThetaK);
Power       = zeros(nWind,nThetaK);
Overspeed   = zeros(nWind,nThetaK);
PitchTravel = zeros(nWind,nThetaK);
MaxGenTq    = zeros(nWind,nThetaK);

%% Calculate mean/max over seeds

for iWind = 1:nWind

    for iTheta = 1:nThetaK

        % Original data ordering:
        % Wind speed -> Seed -> ThetaK
        rows = (iWind-1)*nSeed*nThetaK + (0:nSeed-1)*nThetaK + iTheta;

        % DELs: mean over seeds
        TowerDEL(iWind,iTheta) = mean(Statistics.DEL_4_TwrBsMyt(rows));

        ShaftDEL(iWind,iTheta) = mean(Statistics.DEL_4_RotTorq(rows));

        BladeDEL(iWind,iTheta) = mean(Statistics.DEL_10_RootMyb1(rows));

        % Electrical power: mean over seeds
        Power(iWind,iTheta) = mean(Statistics.mean_GenPwr(rows));

        % Overspeed: maximum over seeds
        Overspeed(iWind,iTheta) = max(Statistics.Overshoot_GenSpeed(rows));

        % Pitch travel: mean over seeds
        PitchTravel(iWind,iTheta) = mean(Statistics.Travel_BldPitch1(rows));

        % Maximum generator torque: maximum over seeds
        MaxGenTq(iWind,iTheta) = max(Statistics.max_GenTq(rows));

    end
end


%% Plot settings

% Generate legend labels automatically
LegendLabels = arrayfun(@(x) sprintf('\\theta_K = %g deg',x), ...
    ThetaK_deg,'UniformOutput',false);

%% PLOT 1: TOWER DEL

figure('Name','Tower DEL');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,TowerDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Tower DEL [kNm]');
title('Tower DEL: \theta_K comparison');
legend(LegendLabels,'Location','best');


%% PLOT 2: SHAFT DEL

figure('Name','Shaft DEL');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,ShaftDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Shaft DEL [kNm]');
title('Shaft DEL: \theta_K comparison');
legend(LegendLabels,'Location','best');


%% PLOT 3: BLADE DEL

figure('Name','Blade DEL');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,BladeDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Blade DEL [kNm]');
title('Blade DEL: \theta_K comparison');
legend(LegendLabels,'Location','best');


%% PLOT 4: ELECTRICAL POWER

figure('Name','Electrical Power');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,Power(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Electrical power [MW]');
title('Electrical Power: \theta_K comparison');
legend(LegendLabels,'Location','best');


%% PLOT 5: GENERATOR OVERSPEED

figure('Name','Generator Overspeed');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,Overspeed(:,iTheta)*100,'o-', ...
        'LineWidth',1.5);
end

yline(10,'k--','20% limit','LineWidth',1.2);

xlabel('Wind speed [m/s]');
ylabel('Generator overspeed [%]');
title('Generator Overspeed: \theta_K comparison');
legend([LegendLabels,{'20% limit'}],'Location','best');


%% PLOT 6: PITCH TRAVEL

figure('Name','Pitch Travel');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,PitchTravel(:,iTheta),'DisplayName', 'after Notch filter','LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Pitch travel');
title('Pitch Travel: At thetha_K=8 degree');
legend('After Notch filter','Location','best');
hold on
plot(WindSpeedBins,[180 278 300 301],'DisplayName', 'Before Notch filter','LineWidth',1.5);
%% PLOT 7: MAXIMUM GENERATOR TORQUE

figure('Name','Maximum Generator Torque');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,MaxGenTq(:,iTheta),'o-', ...
        'LineWidth',1.5);
end

% Maximum torque limit: convert Nm to kNm
VS_MaxTq = 15600000;

yline(VS_MaxTq/1e3,'k--','Maximum torque', ...
    'LineWidth',1.2);

xlabel('Wind speed [m/s]');
ylabel('Generator torque [kNm]');
title('Maximum Generator Torque: \theta_K comparison');
legend([LegendLabels,{'Maximum torque'}],'Location','best');


%% PLOT 8: OVERSPEED FOCUS

figure('Name','Theta_K Optimization');
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,Overspeed(:,iTheta)*100,'o-', ...
        'LineWidth',2);
end

yline(20,'k--','20% target','LineWidth',1.2);

xlabel('Wind speed [m/s]');
ylabel('Generator overspeed [%]');
title('\theta_K optimization: Generator overspeed');
legend([LegendLabels,{'20% target'}],'Location','best');


%% Results tables

ThetaNames = arrayfun(@(x) sprintf('ThetaK_%gdeg',x),ThetaK_deg,'UniformOutput',false);

Results_Overspeed = array2table(Overspeed*100,'VariableNames',ThetaNames,'RowNames',compose('%g_mps',WindSpeedBins));

Results_TowerDEL = array2table(TowerDEL,'VariableNames',ThetaNames,'RowNames',compose('%g_mps',WindSpeedBins));

Results_ShaftDEL = array2table(ShaftDEL,'VariableNames',ThetaNames,'RowNames',compose('%g_mps',WindSpeedBins));

Results_BladeDEL = array2table(BladeDEL,'VariableNames',ThetaNames,'RowNames',compose('%g_mps',WindSpeedBins));

disp('===== GENERATOR OVERSPEED [%] =====');
disp(Results_Overspeed);

disp('===== TOWER DEL =====');
disp(Results_TowerDEL);

disp('===== SHAFT DEL =====');
disp(Results_ShaftDEL);

disp('===== BLADE DEL =====');
disp(Results_BladeDEL);

%% COMBINED FIGURE: THETA_K OPTIMIZATION

figure('Name','Theta_K Optimization - Combined Results', ...
    'Position',[100 100 1200 750]);

tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

%% 1. Tower DEL
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,TowerDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Tower DEL [kNm]');
title('Tower DEL');

%% 2. Shaft DEL
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,ShaftDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Shaft DEL [kNm]');
title('Shaft DEL');

%% 3. Blade DEL
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,BladeDEL(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Blade DEL [kNm]');
title('Blade DEL');

%% 4. Electrical Power
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,Power(:,iTheta)/1e3,'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Electrical power [MW]');
title('Electrical Power');

%% 5. Generator Overspeed
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,Overspeed(:,iTheta)*100,'o-', ...
        'LineWidth',1.5);
end

% Updated objective: 10%
yline(10,'k--','10% objective','LineWidth',1.5);

xlabel('Wind speed [m/s]');
ylabel('Generator overspeed [%]');
title('Generator Overspeed');

%% 6. Pitch Travel
nexttile;
hold on; grid on; box on;

for iTheta = 1:nThetaK
    plot(WindSpeedBins,PitchTravel(:,iTheta),'o-', ...
        'LineWidth',1.5);
end

xlabel('Wind speed [m/s]');
ylabel('Pitch travel');
title('Pitch Travel');

%% Common legend
lgd = legend(LegendLabels,'Orientation','horizontal');
lgd.Layout.Tile = 'south';

sgtitle('\theta_K Optimization: Comparison of Performance Metrics');

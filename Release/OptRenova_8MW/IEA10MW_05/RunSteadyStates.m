clearvars;
close all;
clc;
StartTime = 60;
%% Setup

addpath(genpath('..\WetiMatlabFunctions'));

%% Simulation mode

SimulationMode = 'FeedbackOnlySS';

%% Get configuration

[PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersSS_10MW(SimulationMode);

%% Simulation folder

ExeFile = 'openfast_x64_v4.exe';

SimulationFolder = ['SimulationResults_Steadystates10MW_version2_PS_Mode=0_',SimulationMode];

TemplateFolder = '../IEA10-198-RWT';

%% Create simulation folder

if ~exist(SimulationFolder,'dir')
    mkdir(SimulationFolder)
end

%% Copy turbine template

copyfile(TemplateFolder,SimulationFolder);

%% Copy OpenFAST executable

copyfile(['..\OpenFAST\',ExeFile],fullfile(SimulationFolder,ExeFile));

%% Generate simulations

[SimulationNames,DataFiles] = PreProcessingSimulations(SimulationFolder,PreProcessingVariation,InputFiles,Modifications);

%% Run OpenFAST

[status,result] = ProcessingSimulations(SimulationFolder,SimulationNames,ExeFile);

%% Time results

TimeResults = CollectTimeResults(DataFiles,PostProcessingConfig);

PlotTimeResults(TimeResults,PostProcessingConfig);

%% Statistics

Statistics = CalculateStatistics(TimeResults,PostProcessingConfig);
% mean over an integer number of rotor revolutions at the end of each simulation
Channels = {'Wind1VelX','BldPitch1','RotSpeed','GenSpeed','GenTq','GenPwr','RotThrust','TwrBsMyt'};
N_rot    = NaN(length(TimeResults),1);
for iF = 1:length(TimeResults)
    t        = TimeResults{iF}.Time;
    T_rot    = 60/mean(TimeResults{iF}.RotSpeed.Data(t>=StartTime));   % [s] rotor period (RotSpeed in rpm)
    N_rot(iF)= floor((t(end)-StartTime)/T_rot);                        % full rotations that fit
    IsUsed   = t > t(end)-N_rot(iF)*T_rot;
    for iC = 1:length(Channels)
        Statistics.(['mean_',Channels{iC}])(iF) = mean(TimeResults{iF}.(Channels{iC}).Data(IsUsed));
    end
end
PlotStatistics(Statistics,PostProcessingConfig);
% %% Frequency results
% 
% FrequencyResults = CalculateFrequencyResults( TimeResults,PostProcessingConfig);
% 
% PlotFrequencyResults(FrequencyResults,PostProcessingConfig);
% reference values from the pdf (Table 17 of the 10 MW report)
Ref.Wind  = [4 5 6 7 8 9 9.5 10 10.5 11 11.5 12 13 14 15 16 18 20 25];                                                 % [m/s]
Ref.Pitch = [2.589 1.355 0 0 0 0 0 0 0 2.633 4.537 5.975 8.250 10.121 11.771 13.280 16.018 18.513 24.110];            % [deg]
Ref.RPM   = [6.000 6.000 6.123 7.144 8.165 8.684*ones(1,14)];                                                          % [rpm]

% comparison plot: '.-' simulation, 'o-' pdf
figure('Name','Steady states: simulation vs pdf')

subplot(211)
hold on; box on; grid on
plot(Statistics.mean_Wind1VelX,Statistics.mean_RotSpeed,'.-')
plot(Ref.Wind,Ref.RPM,'o-')
ylabel('rotor speed [rpm]')
legend('simulation','pdf (Table 17)','Location','best')

subplot(212)
hold on; box on; grid on
plot(Statistics.mean_Wind1VelX,Statistics.mean_BldPitch1,'.-')
plot(Ref.Wind,Ref.Pitch,'o-')
ylabel('pitch [deg]')
xlabel('wind speed [m/s]')
%% Save results

save(['Statistics_SS_',SimulationMode],'Statistics');

disp(' ');
disp('==============================================');
disp(' simulations completed');
disp('==============================================');
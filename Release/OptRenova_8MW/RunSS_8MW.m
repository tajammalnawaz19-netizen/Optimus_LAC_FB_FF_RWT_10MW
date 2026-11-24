% Script to run steady states for the Optimus Renova 8 MW.

clearvars;close all;clc;
addpath(genpath('..\WetiMatlabFunctions'))

[PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersSS_8MW;

SimulationMode              = 'SteadyStates_8MW';
ExeFile                     = 'openfast_x64_v4.exe';
SimulationFolder            = ['SimulationResults_',SimulationMode];
TemplateFolder   = pwd;     % folder of this script, which now contains the model files (MATLAB must be in Release\OptRenova_8MW)

if ~exist(SimulationFolder,'dir')
    mkdir(SimulationFolder)
end

% copy only the model files (not the scripts and not the SimulationResults folders)
Files   = {'*.fst','*.dat','*.IN','*.txt','*.dll'};
Folders = {'Airfoils','StrucData','ServoData','Wind'};
for iF = 1:length(Files)
    if ~isempty(dir(fullfile(TemplateFolder,Files{iF})))
        copyfile(fullfile(TemplateFolder,Files{iF}),SimulationFolder)
    end
end
for iF = 1:length(Folders)
    if isfolder(fullfile(TemplateFolder,Folders{iF}))
        mkdir(fullfile(SimulationFolder,Folders{iF}))
        copyfile(fullfile(TemplateFolder,Folders{iF}),fullfile(SimulationFolder,Folders{iF}))
    end
end

copyfile(['..\OpenFAST\',ExeFile],fullfile(SimulationFolder,ExeFile))   % unchanged

[SimulationNames,DataFiles] = PreProcessingSimulations(SimulationFolder,PreProcessingVariation,InputFiles,Modifications);
[status,result]             = ProcessingSimulations(SimulationFolder,SimulationNames,ExeFile);

TimeResults                 = CollectTimeResults(DataFiles,PostProcessingConfig);
PlotTimeResults(TimeResults,PostProcessingConfig);
Statistics                  = CalculateStatistics(TimeResults,PostProcessingConfig);

% mean over an integer number of rotor revolutions at the end of each simulation
StartTime = 150;                                     % same as in GetParametersSS_8MW
Channels  = {'Wind1VelX','BldPitch1','RotSpeed','GenSpeed','GenTq','GenPwr','LSShftFxa','TwrBsMyt'};
N_rot     = NaN(length(TimeResults),1);
for iF = 1:length(TimeResults)
    t         = TimeResults{iF}.Time;
    T_rot     = 60/mean(TimeResults{iF}.RotSpeed.Data(t>=StartTime));
    N_rot(iF) = floor((t(end)-StartTime)/T_rot);
    IsUsed    = t > t(end)-N_rot(iF)*T_rot;
    for iC = 1:length(Channels)
        Statistics.(['mean_',Channels{iC}])(iF) = mean(TimeResults{iF}.(Channels{iC}).Data(IsUsed));
    end
end

% steady-state curves ('.-')
U = Statistics.mean_Wind1VelX;
figure('Name','8 MW steady states')
Vars   = {'mean_RotSpeed','mean_BldPitch1','mean_GenPwr','mean_GenTq','mean_LSShftFxa'};
Labels = {'rotor speed [rpm]','pitch [deg]','power [kW]','generator torque [kNm]','thrust [kN]'};
for iV = 1:length(Vars)
    subplot(length(Vars),1,iV); hold on; box on; grid on
    plot(U,Statistics.(Vars{iV}),'.-'); ylabel(Labels{iV})
end
xlabel('wind speed [m/s]')

% checks: TSR in region 2 and effective K (compare with VS_Rgn2K = 0.69434)
R = 85; K_file = 0.69434;
TSR   = Statistics.mean_RotSpeed*2*pi/60*R./U;
K_eff = Statistics.mean_GenTq*1e3./(Statistics.mean_GenSpeed*2*pi/60).^2;
figure('Name','TSR and K_eff')
subplot(211); plot(U,TSR,'.-'); grid on; ylabel('TSR [-]')
subplot(212); hold on; grid on; plot(U,K_eff,'.-'); yline(K_file,'k--'); ylabel('K_{eff} [Nm/(rad/s)^2]'); xlabel('wind speed [m/s]')
fprintf('Maximum mean power: %.0f kW (rated 8000 kW), revolutions used: %d to %d\n',max(Statistics.mean_GenPwr),min(N_rot),max(N_rot))

save(['Statistics_',SimulationMode],'Statistics')
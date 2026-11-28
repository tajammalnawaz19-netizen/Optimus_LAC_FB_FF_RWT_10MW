% Script to run DLC 1.2 for "FeedbackOnly".

% setup
clearvars;close all;clc;
addpath(genpath('..\WetiMatlabFunctions'))

% get configuration for DLC 1.2
[PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersForBruteForceOptimizationRegion3_8MW;

SimulationMode              = 'Thetha_K_DLC1p2_8MW';
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

% get SimulationNames and DataFiles
[SimulationNames,DataFiles] = PreProcessingSimulations(SimulationFolder,PreProcessingVariation,InputFiles,Modifications);

% run simulations
[status,result]             = ProcessingSimulations(SimulationFolder,SimulationNames,ExeFile);

% TimeResults
TimeResults                 = CollectTimeResults(DataFiles,PostProcessingConfig);
PlotTimeResults(TimeResults,PostProcessingConfig);

% Statistics
Statistics                  = CalculateStatistics(TimeResults,PostProcessingConfig);

% FrequencyResults
% FrequencyResults            = CalculateFrequencyResults(TimeResults,PostProcessingConfig);
% PlotFrequencyResults(FrequencyResults,PostProcessingConfig)

% Evaluate only, if you want to overwrite the results: 
save(['Statistics_',SimulationMode],'Statistics')
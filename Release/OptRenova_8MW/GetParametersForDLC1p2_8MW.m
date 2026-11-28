function [PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersForDLC1p2_8MW


% Process parameters
StartTime               = 60;       % [s]
WoehlerExponentSteel    = 4;        % [-]
WoehlerExponentComposite= 10;       % [-]
PC_RefSpd               = 187.20657;% [rad/s] rated generator speed (HSS side) from the 8 MW DISCON.IN

% files
StatisticsFile          = 'Statistics_SteadyStates_8MW.mat';   
R               = 85;       % [m] rotor radius (ElastoDyn TipRad), adjust after point 9
GB              = 191.4;    % [-] gearbox ratio
N_min_rpm       = 7;        % [rpm] minimum ROTOR speed  % ASSUMPTION
HubHeight       = 118.4;    % [m] hub height             

% Variation
PreProcessingVariation  = { 'URef',[4:2:24],'%02d';
                            'Seed',[1:6]   ,'%02d'};


% template files
InputFiles{1,1} = 'OptRenova_8MW.fst';
InputFiles{2,1} = 'OptRenova_8MW_ElastoDyn.dat';
InputFiles{3,1} = 'OptRenova_8MW_InflowFile.dat';
InputFiles{4,1} = 'OptRenova_8MW_ServoDyn.dat';
InputFiles{5,1} = 'OptRenova_8MW_DISCON.IN';

% new files to be modified
InputFiles{1,2} = '<SimulationName>.fst';
InputFiles{2,2} = '<SimulationName>_ElastoDyn.dat';
InputFiles{3,2} = '<SimulationName>_InflowWind.dat';
InputFiles{4,2} = '<SimulationName>_ServoDyn.dat';
InputFiles{5,2} = '<SimulationName>_DISCON.IN';


% TEMPORARY scaling of the 10 MW gains to the high-speed side (gearbox 191.4), proper tuning comes later
KP10        = [-1.869680 -1.591830 -1.373352 -1.197053 -1.051794 -0.930040 -0.826513 -0.737405 -0.659900 -0.591871 -0.531679 -0.478044 -0.429949 -0.386580 -0.347271 -0.311478 -0.278750 -0.248709 -0.221037 -0.195465 -0.171762 -0.149731 -0.129200 -0.110022 -0.092067 -0.075222 -0.059386 -0.044473 -0.030403 -0.017107];
KI10        = [-0.187947 -0.165464 -0.147785 -0.133520 -0.121766 -0.111914 -0.103537 -0.096327 -0.090055 -0.084551 -0.079680 -0.075340 -0.071448 -0.067939 -0.064758 -0.061862 -0.059214 -0.056783 -0.054544 -0.052475 -0.050557 -0.048774 -0.047113 -0.045561 -0.044108 -0.042745 -0.041464 -0.040257 -0.039118 -0.038043];
J10         = 215112465;    % [kg m^2] WE_Jtot of the 10 MW
J8          = 140000000;    % [kg m^2] WE_Jtot in the 8 MW DISCON.IN
VS_KP10     = -74749827.64378;  VS_KI10 = -8604498.60847;  VS_MaxRat10 = 1500000;  VS_RtTq10 = 12226587.80858;
VS_RtTq8    = 43357.9;
PC_GS_KP    = strjoin(arrayfun(@(x)num2str(x,'%.6f'),KP10/GB,'UniformOutput',false),' ');   % error in HSS speed: divide by GB
PC_GS_KI    = strjoin(arrayfun(@(x)num2str(x,'%.6f'),KI10/GB,'UniformOutput',false),' ');


% modifications in new files 
Modifications = {
    % OpenFAST
    '1','I','TMax',                 num2str(600+StartTime)
    '1','I','DT',                   '0.01'
    '1','I','DT_Out',               'default'
    '1','I','OutFileFmt',           '2'
    '1','I','EDFile',               InputFiles{2,2}
    '1','I','InflowFile',           InputFiles{3,2}
    '1','I','ServoFile',            InputFiles{4,2}
    % ElastoDyn: initial conditions
    '2','I','BlPitch\((1|2|3)\)',   @(VariationValues)num2str(GetStatistics(StatisticsFile,'mean_BldPitch1',VariationValues(1)),'%5.2f')
    '2','I','RotSpeed',             @(VariationValues)num2str(GetStatistics(StatisticsFile,'mean_RotSpeed' ,VariationValues(1)),'%5.2f')
    
    % InflowWind: steady wind, shear 0.2
    '3','I','WindType  ',           '4'
    '3','I','FilenameRoot',         @(VariationValues)strcat('../TurbulentWind/URef_',num2str(VariationValues(1),'%02d'),'_Seed_',num2str(VariationValues(2),'%02d'))
    '3','I','WindVziList',          num2str(HubHeight)
    % ServoDyn: link to new DISCON.IN
    '4','I','DLL_InFile',           InputFiles{5,2}
    % DISCON.IN
    '5','I','! VS_ControlMode',     '0'
    '5','I','! PS_Mode',            '0'
    '5','I','! VS_MinOMSpd',        num2str(rpm2radPs(N_min_rpm)*GB,'%.5f')
    '5','I','! PerfFileName',       '"OptRenova_8MW_Cp_Ct_Cq.txt"'
    '5','I','! VS_KP',              num2str(VS_KP10*(J8/J10)/GB^2,'%.4f')
    '5','I','! VS_KI',              num2str(VS_KI10*(J8/J10)/GB^2,'%.4f')
    '5','I','! VS_MaxRat',          num2str(VS_MaxRat10*VS_RtTq8/VS_RtTq10,'%.1f')
    '5','I','! PC_GS_KP',           PC_GS_KP
    '5','I','! PC_GS_KI',           PC_GS_KI
    };

% time plots for selected wind speeds
nURef       = length(PreProcessingVariation{1,2});
nSeed       = length(PreProcessingVariation{2,2});
for iURef = 1:nURef
    ID = iURef;
    PostProcessingConfig.Plots.BasicTimePlot{ID}.Enable     = 1;
    PostProcessingConfig.Plots.BasicTimePlot{ID}.Channels   = {'Wind1VelX';'BldPitch1';'RotSpeed';'TwrBsMyt'};
    PostProcessingConfig.Plots.BasicTimePlot{ID}.gca.xlim   = [0 600]+StartTime;
    PostProcessingConfig.Plots.BasicTimePlot{ID}.IndicesConsideredDataFiles = [1:nSeed]+(iURef-1)*nSeed;
end

% CalculateStatistics
PostProcessingConfig.CalculateStatistics = {
    'mean'          @(Data,Time)mean(Data(Time>=StartTime)) {'Wind1VelX';'GenPwr'}
    'DEL_4'         @(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentSteel)      {'TwrBsMyt';'RotTorq'}
    'DEL_10'        @(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentComposite)  {'RootMyb1'}
    'Overshoot'     @(Data,Time)max(max(rpm2radPs(Data(Time>=StartTime))-PC_RefSpd)/PC_RefSpd,0) {'GenSpeed'}
    'Travel'        @(Data,Time)CalculatePitchTravel(Data,Time,StartTime) {'BldPitch1'}
    'max'           @(Data,Time)max(Data(Time>=StartTime)) {'GenTq'}
    };

PostProcessingConfig.DataChannels = {'Wind1VelX','BldPitch1','RotSpeed','GenSpeed','GenTq','GenPwr','TwrBsMyt','RotTorq','RootMyb1'};
% PlotFrequencyResults
% CalculateFrequencyResults
Step                    = 50;
nData                   = 600*100/Step;   % 100 Hz (DT = 0.01, DT_Out default) and 10 min
nBlocks                 = 4;
window                  = nData/nBlocks;
AutoSpectrumChannels    = {'TwrBsMyt';'GenSpeed'};
PostProcessingConfig.CalculateFrequencyResults = {
    'AutoSpectrum'      @(Data,Time)EstimateAutoSpectrum(Data,Time,Step,StartTime=StartTime,window=window)  AutoSpectrumChannels;
    };
for iURef = 1:nURef
    ID = iURef;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Enable     = 1;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Channels   = {'AutoSpectrum_TwrBsMyt'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.x          = 'f';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.yCell      = {'S'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.ylabelCell = {'[(kNm)^2/Hz]'};  
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.xlabel     = 'frequency [Hz]';  
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.xScale = 'log';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.yScale = 'log';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.IndicesConsideredDataFiles        = [1:nSeed]+(iURef-1)*nSeed;   
end

for iURef = 1:nURef
    ID = nURef + iURef;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Enable     = 1;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Channels   = {'AutoSpectrum_GenSpeed'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.x          = 'f';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.yCell      = {'S'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.ylabelCell = {'[(rpm)^2/Hz]'};  
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.xlabel     = 'frequency [Hz]';  
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.xScale = 'log';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.yScale = 'log';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.IndicesConsideredDataFiles        = [1:nSeed]+(iURef-1)*nSeed;   
end
end
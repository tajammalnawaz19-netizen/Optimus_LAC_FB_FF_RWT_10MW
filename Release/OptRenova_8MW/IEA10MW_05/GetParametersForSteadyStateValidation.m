function [PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersForSteadyStateValidation % SS: no SimulationMode input needed

% Process parameters
StartTime               = 300;      % SS: [s] evaluate only the last 300 s, after transients have settled
TMax                    = 600;      % SS: [s] total simulation time
PC_RefSpd               = 0.90767;  % [rad/s]       rated generator speed from ROSCO version 2.7.0
VS_MinOMSpd             = 0.73304;  % SS: [rad/s] minimum generator speed, from DISCON.IN (only for initial guess)
TSR_opt                 = 9;        % SS: [-] VS_TSRopt from DISCON.IN (only for initial guess)
R                       = 99.155;   % SS: [m] rotor radius (only for initial guess)
StaticWind              = [0 10 12 14 16 18 20 22 24 25];                                       % SS: [m/s] from FFP_v0.IN (only for initial guess)
StaticPitch             = [0 0 0.1085 0.1749 0.2250 0.2682 0.3072 0.3432 0.3769 0.3930];        % SS: [rad] from FFP_v0.IN (only for initial guess)

% Variation
PreProcessingVariation  = { 'URef',[4:1:25],'%02d'};    % SS: steady wind, 1 m/s steps, no seeds

% template files
InputFiles{1,1} = 'IEA-10.0-198-RWT.fst';
InputFiles{2,1} = 'IEA-10.0-198-RWT_ElastoDyn.dat';
InputFiles{3,1} = 'IEA-10.0-198-RWT_InflowFile.dat';
InputFiles{4,1} = 'IEA-10.0-198-RWT_SeaState.dat';      % SS: to switch off waves
InputFiles{5,1} = 'IEA-10.0-198-RWT_ServoDyn.dat';      % SS: to link to new DISCON.IN
InputFiles{6,1} = 'IEA-10.0-198-RWT_DISCON.IN';         % SS: to disable TSR tracking

% new files to be modified
InputFiles{1,2}         = '<SimulationName>.fst';
InputFiles{2,2}         = '<SimulationName>_ElastoDyn.dat';
InputFiles{3,2}         = '<SimulationName>_InflowWind.dat';
InputFiles{4,2}         = '<SimulationName>_SeaState.dat';  % SS
InputFiles{5,2}         = '<SimulationName>_ServoDyn.dat';  % SS
InputFiles{6,2}         = '<SimulationName>_DISCON.IN';     % SS

% initial guesses to shorten the transient
InitialRotSpeed         = @(URef) radPs2rpm(min(max(TSR_opt*URef/R,VS_MinOMSpd),PC_RefSpd));    % SS: [rpm]
InitialPitch            = @(URef) rad2deg(interp1(StaticWind,StaticPitch,URef));                % SS: [deg]

% modifications in new files (for all Modes)
Modifications           = {
                        % OpenFAST: change time and link to new files
                        '1','I','TMax',                 num2str(TMax)                               % SS
                        '1','I','EDFile',               InputFiles{2,2}
                        '1','I','InflowFile',           InputFiles{3,2}
                        '1','I','SeaStFile',            InputFiles{4,2}                             % SS
                        '1','I','ServoFile',            InputFiles{5,2}                             % SS
                        % ElastoDyn: adjust initial conditions
                        '2','I','BlPitch\((1|2|3)\)',   @(VariationValues)num2str(InitialPitch(VariationValues(1)),'%5.2f')       % SS
                        '2','I','RotSpeed',             @(VariationValues)num2str(InitialRotSpeed(VariationValues(1)),'%5.2f')    % SS
                        % InflowWind: steady wind (WindType 1 is already in the template), no shear
                        '3','I','HWindSpeed',           @(VariationValues)num2str(VariationValues(1))   % SS
                        '3','I','PLexp',                '0.0'                                           % SS
                        % SeaState: still water
                        '4','I','WaveMod  ',            '0'                                             % SS
                        % ServoDyn: link to new DISCON.IN
                        '5','I','DLL_InFile',           InputFiles{6,2}                                 % SS
                        % DISCON.IN: disable TSR tracking
                        '6','I','! VS_ControlMode',     '0'                                             % SS
                        };

% PlotTimeResults
ID = 1;
PostProcessingConfig.Plots.BasicTimePlot{ID}.Enable     = 1;
PostProcessingConfig.Plots.BasicTimePlot{ID}.Channels   = {'Wind1VelX';'RotSpeed';'BldPitch1';'GenPwr'} ;     % SS
PostProcessingConfig.Plots.BasicTimePlot{ID}.gca.xlim   = [0 TMax];                                           % SS
PostProcessingConfig.Plots.BasicTimePlot{ID}.IndicesConsideredDataFiles = find(ismember(PreProcessingVariation{1,2},[8 12 20])); % SS: check settling at 8, 12, 20 m/s

% CalculateStatistics
PostProcessingConfig.CalculateStatistics = { 
    'mean'          @(Data,Time)mean(Data(Time>=StartTime)) {'Wind1VelX';'BldPitch1';'RotSpeed';'GenSpeed';'GenTq';'GenPwr';'RotThrust';'TwrBsMyt'}   % SS
    'std'           @(Data,Time)std(Data(Time>=StartTime))  {'RotSpeed';'BldPitch1'}                                                                   % SS: to check that it is settled
    }; 

% PlotStatistics
ID = 1;                                                                                                                         % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.Enable     = 1;                                                              % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.Variables  = {'mean_RotSpeed';'mean_BldPitch1';'mean_GenPwr';'mean_GenTq';'mean_RotThrust'}; % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.x          = PreProcessingVariation{1,2};                                    % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.ylabelCell = {'[rpm]';'[deg]';'[kW]';'[kNm]';'[kN]'};                        % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.xlabel     = 'wind speed [m/s]';                                             % SS

end
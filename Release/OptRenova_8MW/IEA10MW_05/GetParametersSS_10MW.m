
function [PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersSS_10MW(SimulationMode)

% ============================================================
% DLC 1.2 - Region 3 Brute Force Optimization
% Optimization variable: theta_K = 3 and 6 degrees
% Wind speeds: 12, 16, 20, 24 m/s
% Seeds: 1, 2, 3
% Improvements:
% 1) Minimum generator speed = 7 rpm
% 2) Low-pass corner frequency = 3 Hz
% 3) Gain scheduling using theta_K
% ============================================================

arguments
    SimulationMode char {mustBeMember(SimulationMode,{'FeedbackOnlySS'})}
end

%% General settings

StartTime = 60;
TMax = 180;
WoehlerExponentSteel = 4;
WoehlerExponentComposite = 10;
PC_RefSpd = 0.90767;
StatisticsFile = 'Statistics_SteadyStates.mat';

%% Optimization variables

ThetaK_deg = [8];
URef = (20:125)/5;     % 4.0:0.2:25.0
% Seeds = [1 2 3];
                                                                                                                
PreProcessingVariation = {'URef',URef,'%04.1f';'ThetaK',ThetaK_deg,'%02d'};

%% Template files and simulation-specific files

InputFiles{1,1} = 'IEA-10.0-198-RWT.fst';
InputFiles{2,1} = 'IEA-10.0-198-RWT_ElastoDyn.dat';
InputFiles{3,1} = 'IEA-10.0-198-RWT_InflowFile.dat';
InputFiles{4,1} = 'IEA-10.0-198-RWT_ServoDyn.dat';
InputFiles{5,1} = 'IEA-10.0-198-RWT_DISCON.IN';

InputFiles{1,2} = '<SimulationName>.fst';
InputFiles{2,2} = '<SimulationName>_ElastoDyn.dat';
InputFiles{3,2} = '<SimulationName>_InflowWind.dat';
InputFiles{4,2} = '<SimulationName>_ServoDyn.dat';
InputFiles{5,2} = '<SimulationName>_DISCON.IN';

%% Calculate integral time constant

OmegaRated = PC_RefSpd;
Ti = 2*pi/OmegaRated;

% Rated proportional gain from original ROSCO controller
KpRated = -1.869680;

%% Pitch gain-scheduling angles

ThetaAngles = [0.074715 0.104855 0.127756 0.147841 0.166006 0.182149 0.197673 0.211917 0.225671 0.238919 0.251384 0.263856 0.275558 0.287072 0.298597 0.309358 0.320134 0.330914 0.341068 0.351235 0.361422 0.371155 0.380809 0.390472 0.399908 0.409125 0.418341 0.427550 0.436381 0.445192];

% Gain-scheduling formula
MakeKP = @(ThetaKDeg) KpRated./(1 + ThetaAngles./deg2rad(ThetaKDeg));
MakeKI = @(ThetaKDeg) MakeKP(ThetaKDeg)./Ti;
Init.Wind  = 4:25;
Init.Pitch = [0 0 0 0 0 0.2964 3.3453 4.8072 6.1332 7.8304 10.272 12.0753 13.6897 15.1639 16.534 17.8174 19.0316 20.1939 21.31 22.3864 23.4336 24.4528];
Init.RPM   = [6.0001 5.9998 6.0002 6.0003 6.2836 7.0578 7.5403 8.0242 8.4394 8.6676*ones(1,13)];
%% Modifications

Modifications = {
    % OpenFAST: simulation time and file connections
    '1','I','TMax',num2str(TMax+StartTime)
    '1','I','EDFile',InputFiles{2,2}
    '1','I','InflowFile',InputFiles{3,2}
    '1','I','ServoFile',InputFiles{4,2}

    % ElastoDyn: initial conditions
    '2','I','BlPitch\((1|2|3)\)',@(VariationValues)num2str(interp1(Init.Wind,Init.Pitch,VariationValues(1)),'%5.2f')
    '2','I','RotSpeed',@(VariationValues)num2str(interp1(Init.Wind,Init.RPM,VariationValues(1)),'%5.2f')
    
    % InflowWind
    '3','I','WindType  ','1'
    '3','I','HWindSpeed',@(VariationValues)num2str(VariationValues(1),'%5.1f')

    % ServoDyn: connect to simulation-specific ROSCO input file
    '4','I','DLL_InFile',InputFiles{5,2}
    % ROSCO DISCON.IN
    
    '5','I','VS_MinOMSpd',num2str(rpm2radPs(6),'%.12f')% ROSCO DISCON.IN: minimum generator speed
    '5','I','F_LPFCornerFreq',num2str(2*pi*3,'%.6f')% ROSCO DISCON.IN: low-pass corner frequency = 3 Hz
    '5','I','PC_GS_KP',@(VariationValues)strjoin(arrayfun(@(x)num2str(x,'%.6f'),MakeKP(VariationValues(2)),'UniformOutput',false),' ') % ROSCO DISCON.IN: theta_K-dependent KP
    '5','I','PC_GS_KI',@(VariationValues)strjoin(arrayfun(@(x)num2str(x,'%.6f'),MakeKI(VariationValues(2)),'UniformOutput',false),' ')% ROSCO DISCON.IN: theta_K-dependent KI
    '5','I','F_NotchType','1'    % Enable ROSCO notch filter
    '5','I','F_NotchCornerFreq','7.85000'    % Set notch filter centre frequency (rad/s) detected peak is 1.25 Hz, so for DISCON use ω = 2π·1.25 ≈ 7.85 rad/s
    '5','I','F_NotchBetaNumDen','0.050000 0.200000'% Set notch filter numerator and denominator parameters
    % DISCON.IN: disable TSR tracking
    '5','I','! VS_ControlMode',     '0'
    '5','I','! PS_Mode','0'
    };

%% Time plots: separate figures for each theta_K and wind speed

nURef = length(URef);
for iURef = 1:nURef
    ID = iURef;
        PostProcessingConfig.Plots.BasicTimePlot{ID}.Enable = ismember(URef(iURef),[6 8 9 10 12 14 20]);   % CHANGED: only these wind speeds get a figure
        PostProcessingConfig.Plots.BasicTimePlot{ID}.Channels = {'Wind1VelX';'BldPitch1';'RotSpeed';'GenPwr'};
        PostProcessingConfig.Plots.BasicTimePlot{ID}.gca.xlim = [0 TMax]+StartTime;   % CHANGED: whole run, so you can see the settling part too
        PostProcessingConfig.Plots.BasicTimePlot{ID}.IndicesConsideredDataFiles = ID;
end

%% Statistics

PostProcessingConfig.CalculateStatistics = {
    'mean',@(Data,Time)mean(Data(Time>=StartTime)),{'Wind1VelX';'BldPitch1';'RotSpeed';'GenSpeed';'GenTq';'GenPwr';'RotThrust';'TwrBsMyt'}
    % 'DEL_4',@(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentSteel),{'TwrBsMyt';'RotTorq'}
    % 'DEL_10',@(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentComposite),{'RootMyb1'}
    % 'Overshoot',@(Data,Time)max(max(rpm2radPs(Data(Time>=StartTime))-PC_RefSpd)/PC_RefSpd,0),{'GenSpeed'}
    % 'Travel',@(Data,Time)CalculatePitchTravel(Data,Time,StartTime),{'BldPitch1'}
    % 'max',@(Data,Time)max(Data(Time>=StartTime)),{'GenTq'}
    };
% PlotStatistics
ID = 1;                                                                                                                         % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.Enable     = 1;                                                              % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.Variables  = {'mean_RotSpeed';'mean_BldPitch1';'mean_GenPwr';'mean_GenTq';'mean_RotThrust'}; % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.x          = PreProcessingVariation{1,2};                                    % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.ylabelCell = {'[rpm]';'[deg]';'[kW]';'[kNm]';'[kN]'};                        % SS
PostProcessingConfig.Plots.BasicStatisticsPlot{ID}.xlabel     = 'wind speed [m/s]';                                             % SS


% %% Frequency analysis
% 
% Step = 5;
% nData = 600*100/Step;
% nBlocks = 4;
% window = nData/nBlocks;
% AutoSpectrumChannels = {'GenSpeed'};
% 
% PostProcessingConfig.CalculateFrequencyResults = {
%     'AutoSpectrum',@(Data,Time)EstimateAutoSpectrum(Data,Time,Step,StartTime=StartTime,window=window),AutoSpectrumChannels
%     };
% 
% %% Frequency plots
% 
% for iURef = 1:nURef
%     ID = iURef;
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Enable = 1;
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Channels = {'AutoSpectrum_GenSpeed'};
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.x = 'f';
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.yCell = {'S'};
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.ylabelCell = {'[(rad/s)^2/Hz]'};
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.xlabel = 'frequency [Hz]';
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.xScale = 'log';
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.yScale = 'log';
%     nPerWind = nSeed*nThetaK;
%     PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.IndicesConsideredDataFiles = [1:nPerWind]+(iURef-1)*nPerWind;
% end
% % PostProcessingConfig.Plots.BasicFrequencyPlot{4}.IndicesConsideredDataFiles = 10;
 end
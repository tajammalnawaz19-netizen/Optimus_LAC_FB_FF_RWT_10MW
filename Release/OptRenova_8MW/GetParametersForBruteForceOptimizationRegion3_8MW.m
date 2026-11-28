
function [PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersForBruteForceOptimizationRegion3_8MW

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



%% General settings

StartTime = 60;
WoehlerExponentSteel = 4;
WoehlerExponentComposite = 10;
PC_RefSpd = 187.20657;% [rad/s] rated generator speed (HSS side) from the 8 MW DISCON.IN
StatisticsFile          = 'Statistics_SteadyStates_8MW.mat';
R               = 85;       % [m] rotor radius (ElastoDyn TipRad), adjust after point 9
GB              = 191.4;    % [-] gearbox ratio
N_min_rpm       = 7;        % [rpm] minimum ROTOR speed  % ASSUMPTION
HubHeight       = 118.4;    % [m] hub height 
%% Optimization variables

ThetaK_deg = [8];
URef = [12 16 20 24];
Seeds = [1 2 3];
                                                                                                                
PreProcessingVariation = {'URef',URef,'%02d';'Seed',Seeds,'%02d';'ThetaK',ThetaK_deg,'%02d'};

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


%% Calculate integral time constant

OmegaRated = PC_RefSpd/GB;      % [rad/s] rated ROTOR speed
Ti         = 2*pi/OmegaRated;

% Rated proportional gain from original ROSCO controller
KpRated = -1.869680/GB;
%%% TEMPORARY scaling of the 10 MW gains to the high-speed side (gearbox 191.4), proper tuning comes later
KP10        = [-1.869680 -1.591830 -1.373352 -1.197053 -1.051794 -0.930040 -0.826513 -0.737405 -0.659900 -0.591871 -0.531679 -0.478044 -0.429949 -0.386580 -0.347271 -0.311478 -0.278750 -0.248709 -0.221037 -0.195465 -0.171762 -0.149731 -0.129200 -0.110022 -0.092067 -0.075222 -0.059386 -0.044473 -0.030403 -0.017107];
KI10        = [-0.187947 -0.165464 -0.147785 -0.133520 -0.121766 -0.111914 -0.103537 -0.096327 -0.090055 -0.084551 -0.079680 -0.075340 -0.071448 -0.067939 -0.064758 -0.061862 -0.059214 -0.056783 -0.054544 -0.052475 -0.050557 -0.048774 -0.047113 -0.045561 -0.044108 -0.042745 -0.041464 -0.040257 -0.039118 -0.038043];
J10         = 215112465;    % [kg m^2] WE_Jtot of the 10 MW
J8          = 140000000;    % [kg m^2] WE_Jtot in the 8 MW DISCON.IN
VS_KP10     = -74749827.64378;  VS_KI10 = -8604498.60847;  VS_MaxRat10 = 1500000;  VS_RtTq10 = 12226587.80858;
VS_RtTq8    = 43357.9;


%% Pitch gain-scheduling angles from the 8 MW steady states
U_SS         = [11.4 11.6 11.8 12 12.5 13 14 15 16 17 18 19 20 21 22 23 24 25];                       % [m/s]
Pitch_SS     = [1.5 2.8 3.9 4.8 6.4 7.7 10.0 11.8 13.5 15.1 16.6 18.0 19.4 20.7 21.9 23.1 24.2 25.3]; % [deg]
ThetaAngles  = deg2rad(interp1(U_SS,Pitch_SS,linspace(11.4,25,30),'pchip'));                          % [rad], 30 values
PC_GS_angles = strjoin(arrayfun(@(x)num2str(x,'%.6f'),ThetaAngles,'UniformOutput',false),' ');

% Gain-scheduling formula
MakeKP = @(ThetaKDeg) KpRated./(1 + ThetaAngles./deg2rad(ThetaKDeg));
MakeKI = @(ThetaKDeg) MakeKP(ThetaKDeg)./Ti;

%% Modifications

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
    % pitch gain scheduling: 8 MW angles and theta_K-dependent gains
    '5','I','! PC_GS_angles',       PC_GS_angles
    '5','I','! PC_GS_KP',           @(VariationValues)strjoin(arrayfun(@(x)num2str(x,'%.6f'),MakeKP(VariationValues(3)),'UniformOutput',false),' ')
    '5','I','! PC_GS_KI',           @(VariationValues)strjoin(arrayfun(@(x)num2str(x,'%.6f'),MakeKI(VariationValues(3)),'UniformOutput',false),' ')

    % % ROSCO DISCON.IN: low-pass corner frequency = 3 Hz
    % '5','I','F_LPFCornerFreq',num2str(2*pi*3,'%.6f')
    % % Enable ROSCO notch filter
    % '5','I','F_NotchType','1'
    % % Set notch filter centre frequency (rad/s) detected peak is 1.25 Hz, so for DISCON use ω = 2π·1.25 ≈ 7.85 rad/s
    % '5','I','F_NotchCornerFreq','7.85000'
    % % Set notch filter numerator and denominator parameters
    % '5','I','F_NotchBetaNumDen','0.050000 0.200000'
    };

%% Time plots: separate figures for each theta_K and wind speed

nURef = length(URef);
nSeed = length(Seeds);
nThetaK = length(ThetaK_deg);

for iThetaK = 1:nThetaK
    for iURef = 1:nURef
        ID = (iThetaK-1)*nURef+iURef;
        PostProcessingConfig.Plots.BasicTimePlot{ID}.Enable = 1;
        PostProcessingConfig.Plots.BasicTimePlot{ID}.Channels = {'Wind1VelX';'BldPitch1';'RotSpeed';'TwrBsMyt'};
        PostProcessingConfig.Plots.BasicTimePlot{ID}.gca.xlim = [0 600]+StartTime;
        Indices = (iURef-1)*nSeed*nThetaK+iThetaK+(0:nSeed-1)*nThetaK;
        PostProcessingConfig.Plots.BasicTimePlot{ID}.IndicesConsideredDataFiles = Indices;
    end
end

%% Statistics

PostProcessingConfig.CalculateStatistics = {
    'mean',@(Data,Time)mean(Data(Time>=StartTime)),{'Wind1VelX';'GenPwr'}
    'DEL_4',@(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentSteel),{'TwrBsMyt';'RotTorq'}
    'DEL_10',@(Data,Time)CalculateDEL(Data(Time>=StartTime),Time(Time>=StartTime),WoehlerExponentComposite),{'RootMyb1'}
    'Overshoot',@(Data,Time)max(max(rpm2radPs(Data(Time>=StartTime))-PC_RefSpd)/PC_RefSpd,0),{'GenSpeed'}
    'Travel',@(Data,Time)CalculatePitchTravel(Data,Time,StartTime),{'BldPitch1'}
    'max',@(Data,Time)max(Data(Time>=StartTime)),{'GenTq'}
    };

%% Frequency analysis

Step = 5;
nData = 600*100/Step;
nBlocks = 4;
window = nData/nBlocks;
AutoSpectrumChannels = {'GenSpeed'};

PostProcessingConfig.CalculateFrequencyResults = {
    'AutoSpectrum',@(Data,Time)EstimateAutoSpectrum(Data,Time,Step,StartTime=StartTime,window=window),AutoSpectrumChannels
    };

%% Frequency plots

for iURef = 1:nURef
    ID = iURef;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Enable = 1;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.Channels = {'AutoSpectrum_GenSpeed'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.x = 'f';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.yCell = {'S'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.ylabelCell = {'[(rad/s)^2/Hz]'};
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.xlabel = 'frequency [Hz]';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.xScale = 'log';
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.gca.yScale = 'log';
    nPerWind = nSeed*nThetaK;
    PostProcessingConfig.Plots.BasicFrequencyPlot{ID}.IndicesConsideredDataFiles = [1:nPerWind]+(iURef-1)*nPerWind;
end
% PostProcessingConfig.Plots.BasicFrequencyPlot{4}.IndicesConsideredDataFiles = 10;
end
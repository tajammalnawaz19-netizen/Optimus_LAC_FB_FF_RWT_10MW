function [PostProcessingConfig,PreProcessingVariation,InputFiles,Modifications] = GetParametersSS_8MW

% Process parameters
StartTime       = 150;      % [s] longer settling for the first run, because the initial values are only guesses
TMax            = 300;      % [s]
R               = 85;       % [m] rotor radius (ElastoDyn TipRad), adjust after point 9
GB              = 191.4;    % [-] gearbox ratio
N_min_rpm       = 6;        % [rpm] minimum ROTOR speed  % ASSUMPTION
HubHeight       = 118.4;    % [m] hub height             % ASSUMPTION (from ElastoDyn, see point 11)
TSR_guess       = 9;        % [-] only for the initial guess
N_rated_rpm     = radPs2rpm(187.20657/GB);   % [rpm] rated rotor speed from PC_RefSpd

% Variation
URef                    = (20:125)/5;                       % 4.0:0.2:25.0 m/s
% URef = 8;
PreProcessingVariation  = {'URef',URef,'%04.1f'};

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

% initial guesses (first run only; replace by the results of the first run afterwards)
InitialRotSpeed = @(U) min(max(TSR_guess*U/R*60/(2*pi),N_min_rpm),N_rated_rpm);                  % [rpm]
InitialPitch    = @(U) interp1([0 10.5 11.5 14 18 25],[0 0 3 10 16.5 24],U,'linear','extrap');   % [deg] rough guess

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
    '1','I','TMax',                 num2str(TMax)
    '1','I','DT',                   '0.01'
    '1','I','DT_Out',               'default'
    '1','I','OutFileFmt',           '2'
    '1','I','EDFile',              InputFiles{2,2}
    '1','I','InflowFile',          InputFiles{3,2}
    '1','I','ServoFile',           InputFiles{4,2}
    % ElastoDyn: initial conditions
    '2','I','BlPitch\((1|2|3)\)',   @(VariationValues)num2str(InitialPitch(VariationValues(1)),'%5.2f')
    '2','I','RotSpeed',             @(VariationValues)num2str(InitialRotSpeed(VariationValues(1)),'%5.2f')
    % InflowWind: steady wind, shear 0.2
    '3','I','WindType  ',           '1'
    '3','I','HWindSpeed',           @(VariationValues)num2str(VariationValues(1),'%5.1f')
    '3','I','PLexp',                '0.2'
    '3','I','RefHt',                num2str(HubHeight)
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
PlotWind = [6 8 10 11 12 14 20];
IdxPlot  = find(ismember(round(URef*10),PlotWind*10));
for iPlot = 1:length(IdxPlot)
    PostProcessingConfig.Plots.BasicTimePlot{iPlot}.Enable   = 1;
    PostProcessingConfig.Plots.BasicTimePlot{iPlot}.Channels = {'Wind1VelX';'BldPitch1';'RotSpeed';'GenPwr'};
    PostProcessingConfig.Plots.BasicTimePlot{iPlot}.gca.xlim = [0 TMax];
    PostProcessingConfig.Plots.BasicTimePlot{iPlot}.IndicesConsideredDataFiles = IdxPlot(iPlot);
end

% CalculateStatistics
PostProcessingConfig.CalculateStatistics = {
    'mean'  @(Data,Time)mean(Data(Time>=StartTime)) {'Wind1VelX';'BldPitch1';'RotSpeed';'GenSpeed';'GenTq';'GenPwr';'LSShftFxa';'TwrBsMyt'}
    'std'   @(Data,Time)std(Data(Time>=StartTime))  {'RotSpeed';'BldPitch1'}
    };

% only read the needed channels (memory)
PostProcessingConfig.DataChannels = {'Wind1VelX','BldPitch1','RotSpeed','GenSpeed','GenTq','GenPwr','LSShftFxa','TwrBsMyt'};

end
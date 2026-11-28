%% WE_Jtot_simple.m
% Calculates WE_Jtot (total drivetrain inertia used by the ROSCO wind
% speed estimator) from the blade data and a few ElastoDyn values.
%
% EQUATIONS
%   (1) r_i      = HubRad + BlFract_i * (TipRad - HubRad)       [m]
%                  distance of blade station i from the rotor axis
%   (2) J_blade  = integral of  BMassDen(r) * r^2  dr           [kg m^2]
%                  (solved numerically with the trapezoid rule)
%   (3) J_rotor  = HubIner + NumBl * J_blade                    [kg m^2]
%   (4) J_gen    = GenIner                                      [kg m^2]
%                  (if GenIner is on the HIGH-speed shaft use
%                   J_gen = GenIner * GBRatio^2 instead, see below)
%   (5) WE_Jtot  = J_rotor + J_gen                              [kg m^2]
%
% Result goes into DISCON.IN, line "WE_Jtot".

clear; clc;

%% 1) Values from the ElastoDyn MAIN file: OptRenova_8MW_ElastoDyn.dat
NumBl   = 3;            % number of blades                 (line "NumBl")
TipRad  = 85;           % rotor apex to blade tip [m]      (line "TipRad")
HubRad  = 2.4;          % rotor apex to blade root [m]     (line "HubRad")
HubIner = 476512.0;     % HUB INERTIA about rotor axis     (line "HubIner")  [kg m^2]
GenIner = 3801700.0;    % GENERATOR INERTIA                (line "GenIner")  [kg m^2]
GBRatio = 179.4;        % gearbox ratio                    (line "GBRatio")
% (Project Hub says 191.436 - confirm with drivetrain team)

%% 2) Blade data from the ElastoDyn BLADE file:
%    OptRenova_8MW_ElastoDyn_blade.dat
%    Table "DISTRIBUTED BLADE PROPERTIES", columns:
%    BlFract  PitchAxis  StrcTwst  BMassDen  FlpStff  EdgStff
bladeFile = 'C:\Z_DRIVE D\github mothership\computation of total inertia\OptRenova_8MW_ElastoDyn_blade.dat';;

lines = splitlines(fileread(bladeFile));
table = [];
for k = 1:numel(lines)
    v = sscanf(lines{k}, '%f');     % try to read numbers from this line
    if numel(v) == 6                % only the table rows have exactly 6 numbers
        table = [table; v.'];       %#ok<AGROW>
    end
end

BlFract  = table(:,1);              % fraction of blade length [-]  (0 = root, 1 = tip)
BMassDen = table(:,4);              % blade mass per metre [kg/m]

%% 3) Blade inertia J_blade  (equations 1 and 2)
bladeLength = TipRad - HubRad;              % length of the blade [m]
span = BlFract * bladeLength;               % distance from blade root [m]
r    = HubRad + span;                       % distance from rotor axis [m]   (eq. 1)

massBlade = trapz(span, BMassDen);          % check: mass of one blade [kg]
J_blade   = trapz(span, BMassDen .* r.^2);  % eq. 2   [kg m^2]

%% 4) Rotor inertia (equation 3)
J_rotor = HubIner + NumBl * J_blade;

%% 5) Generator inertia (equation 4)
J_gen = GenIner;                    % use this if GenIner is already on the low-speed shaft
% J_gen = GenIner * GBRatio^2;      % use this if GenIner is on the high-speed shaft
% J_gen = 4 * 68 * 191.436^2;       % Project Hub: 4 generators x 68 kg m^2 (HSS) x ratio^2

%% 6) Total (equation 5)
WE_Jtot = J_rotor + J_gen;

%% 7) Show the results
fprintf('Blade mass (one blade)  : %10.1f kg\n',    massBlade);
fprintf('J_blade (one blade)     : %12.5e kg m^2\n', J_blade);
fprintf('Hub inertia             : %12.5e kg m^2\n', HubIner);
fprintf('J_rotor (hub + blades)  : %12.5e kg m^2\n', J_rotor);
fprintf('J_gen (generator)       : %12.5e kg m^2\n', J_gen);
fprintf('WE_Jtot                 : %12.5e kg m^2\n', WE_Jtot);
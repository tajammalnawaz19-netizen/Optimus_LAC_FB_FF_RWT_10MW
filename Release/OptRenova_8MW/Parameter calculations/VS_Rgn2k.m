%% VS_Rgn2K_small.m  -  region 2 torque constant for DISCON.IN
%
%   VS_Rgn2K = 0.5 * rho * pi * R^5 * Cp_max / (lambda_opt^3 * N^3)    [Nm/(rad/s)^2]
%
%   Torque law in region 2:  T_gen = VS_Rgn2K * omega_gen^2

rho     = 1.225;    % air density [kg/m^3]            (DISCON.IN WE_RhoAir, line 90)
R       = 84.8265;  % rotor radius [m]                (Project Hub, Summary sheet, K5)
lambda  = 9.5;     % optimal tip-speed ratio [-]     (VS_TSRopt)
Cp_max  = 0.49392;   % Cp at lambda_opt AND at the fine pitch PC_FinePit, read from the
% Cp table (value here: IEA table at TSR 9.5, pitch 0 deg - REPLACE
% with the value from your own Renova Cp table)
N       = 191.4;        % gearbox ratio [-]               (same as WE_GearboxRatio, line 88)

VS_Rgn2K = 0.5 * rho * pi * R^5 * Cp_max / (lambda^3 * N^3);

fprintf('VS_Rgn2K = %.5f Nm/(rad/s)^2\n', VS_Rgn2K);
%% Rated generator torque for DISCON.IN
% omega_gen = N * 2*pi*n_rotor/60          [rad/s]  -> VS_RefSpd, PC_RefSpd
% T_rated   = P_rated / (omega_gen*eta)    [Nm]     -> VS_RtTq, VS_ArSatTq
% T_max     = 1.1 * T_rated                [Nm]     -> VS_MaxTq

P_rated = 8e6;          % rated power [W]            (Project Hub, SI sheet, C17)
n_rotor = 9.34007882;   % rated rotor speed [rpm]    (Project Hub, Mechanical Drivetrain, C21)
N       = 191.4;            % gearbox ratio [-]          (same as WE_GearboxRatio)
eta_gen     = 0.9856;    % generator efficiency [-]   (PLACEHOLDER, fraction not %)

omega_gen = N * 2*pi * n_rotor / 60;
T_rated   = P_rated / (omega_gen * eta_gen);
T_max     = 1.1 * T_rated;

fprintf('VS_RefSpd = PC_RefSpd = %.5f rad/s\n', omega_gen);
fprintf('VS_RtTq   = VS_ArSatTq = %.1f Nm\n',   T_rated);
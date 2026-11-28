%% PC_RefSpd.m
% Calculates PC_RefSpd (and VS_RefSpd) for DISCON.IN
% generator speed it tries to hold above the rated wind speed
% EQUATIONS
%   (1) omega_rotor  = rpm_rotor * 2*pi / 60      [rad/s]   rated rotor speed
%   (2) PC_RefSpd    = omega_rotor * GBRatio       [rad/s]   rated speed on the
%                                                            generator (HSS) side
%   VS_RefSpd uses the same value.

clear; clc;

%% Inputs
rpm_rotor = 9.34007882;   % rated rotor speed [rpm]  Project Hub, sheet "Mechanical Drivetrain", cell C21
GBRatio   = 191.4;            % must match WE_GearboxRatio in DISCON.IN  ( L and D team said so)

%  Drivetrain", cell C20 says 191.436 for the geared design)

%% Calculation
omega_rotor = rpm_rotor * 2*pi / 60;    % eq. 1
PC_RefSpd   = omega_rotor * GBRatio;    % eq. 2

%% Result
fprintf('Rated rotor speed : %.5f rad/s\n', omega_rotor);
fprintf('PC_RefSpd         : %.5f rad/s\n', PC_RefSpd);
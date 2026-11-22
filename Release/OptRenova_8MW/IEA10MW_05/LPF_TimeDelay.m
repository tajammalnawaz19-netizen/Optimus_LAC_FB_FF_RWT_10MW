clear;
clc;
close all;

%% Filter cutoff frequencies
fc_old = 0.16;  % Original ROSCO filter [Hz]
fc_new = 3.00;  % New low-pass filter [Hz]

%% Frequency range for comparison
f = logspace(-2, 1, 1000);  % 0.01 Hz to 10 Hz

%% Convert frequency to angular frequency
omega_delay = 2*pi*f;

%% Convert cutoff frequencies to rad/s
omega_cutoff_old = 2*pi*fc_old;
omega_cutoff_new = 2*pi*fc_new;

%% Calculate normalized frequencies
omega_n_old = omega_delay ./ omega_cutoff_old;
omega_n_new = omega_delay ./ omega_cutoff_new;

%% Calculate filter delays using Equation 5.41
T_old = atan(omega_n_old) ./ omega_delay;
T_new = atan(omega_n_new) ./ omega_delay;

%% Plot comparison
figure;

semilogx(f, T_old, 'r--', 'LineWidth', 2);
hold on;
semilogx(f, T_new, 'b-', 'LineWidth', 2);

grid on;
xlabel('Frequency [Hz]');
ylabel('Filter delay (s)');
title('Low-pass Filter Delay Comparison');

legend('Original filter (0.16 Hz)', 'New filter (3 Hz)', 'Location', 'best');

xlim([0.01 10]);

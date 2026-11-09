% Select the first simulation
idx = 10;
StartTime = 60;
% Extract generator speed
GenSpeed_ts = TimeResults{idx}.GenSpeed;

Time = GenSpeed_ts.Time;
GenSpeed = GenSpeed_ts.Data;

% Calculate time step
DT = Time(2) - Time(1);

% Display basic information
fprintf('Wind speed: 24 m/s\n');
fprintf('Seed: 01\n');
fprintf('Time step: %.5f s\n', DT);
fprintf('Number of samples: %d\n', length(GenSpeed));
% Notch filter parameters
omega = 2*pi*0.44;
betaNum = 0.003;
betaDen = 0.3;
GenSpeed_Filtered = RoscoNotchFilter(GenSpeed, DT, omega, betaNum, betaDen);

figure;

plot(Time, GenSpeed, 'b');
hold on;
plot(Time, GenSpeed_Filtered, 'r');

xlabel('Time (s)');
ylabel('Generator Speed (rpm)');
title('Original vs Notch-Filtered Generator Speed');
legend('Original','Filtered');
grid on;

Difference = GenSpeed - GenSpeed_Filtered;

% fprintf('Original STD: %.6f rpm\n', std(GenSpeed));
% fprintf('Filtered STD: %.6f rpm\n', std(GenSpeed_Filtered));
% fprintf('Difference STD: %.6f rpm\n', std(Difference));
% fprintf('Maximum difference: %.6f rpm\n', max(abs(Difference)));
% figure;
% %plot(Time, Difference);
% xlabel('Time (s)');
% ylabel('Speed difference (rpm)');
% title('Difference Between Original and Filtered Signals');
% grid on;

% Frequency analysis setting
Step = 50;
nData = 600*100/Step;
nBlocks = 4;
window = nData/nBlocks;

% Original signal spectrum
OriginalSpectrum = EstimateAutoSpectrum(GenSpeed, Time, Step, StartTime=StartTime, window=window);

% Filtered signal spectrum
FilteredSpectrum = EstimateAutoSpectrum(GenSpeed_Filtered, Time, Step,StartTime=StartTime, window=window);

figure;

loglog(OriginalSpectrum.f, OriginalSpectrum.S, 'b', ...
    'LineWidth', 1.2);
hold on;

loglog(FilteredSpectrum.f, FilteredSpectrum.S, 'r--', ...
    'LineWidth', 1.2);

xline(0.44, 'k:', '3P = 0.44 Hz');

xlim([0.1 0.8]);

xlabel('Frequency (Hz)');
ylabel('PSD [(rpm)^2/Hz]');
title('Original vs Notch-Filtered Generator Speed Autospectrum');

legend('Original','Filtered','Estimated 3P');
grid on;
% [~, idx3P] = min(abs(OriginalSpectrum.f - 0.44));
% 
% S_original = OriginalSpectrum.S(idx3P);
% S_filtered = FilteredSpectrum.S(idx3P);
% 
% Attenuation_dB = 10*log10(S_filtered/S_original);
% 
% fprintf('Frequency: %.4f Hz\n', OriginalSpectrum.f(idx3P));
% fprintf('Original PSD: %.6e\n', S_original);
% fprintf('Filtered PSD: %.6e\n', S_filtered);
% fprintf('Attenuation: %.2f dB\n', Attenuation_dB);
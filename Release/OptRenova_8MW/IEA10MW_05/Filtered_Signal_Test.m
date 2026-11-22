%% Notch filter design on 24 m/s, seeds 1-3
idxList   = [10 11 12];
StartTime = 60;
Step      = 5;                         % fs = 20 Hz, resolves the 1.3 Hz peak
nData     = 600*100/Step;
window    = nData/4;
nSeeds    = numel(idxList);

% candidate notch settings: [f_notch (Hz), betaNum, betaDen]; f_notch = NaN -> detected peak
fPeakRange = [1.0 1.6];                % search range for the peak [Hz]

%% 1) original spectra and peak detection
S_org = []; 
for k = 1:nSeeds
    ts   = TimeResults{idxList(k)}.GenSpeed;
    Time = ts.Time;  u = ts.Data;  DT = Time(2)-Time(1);
    Sp   = EstimateAutoSpectrum(u,Time,Step,StartTime=StartTime,window=window);
    S_org(:,k) = Sp.S;  f = Sp.f;
end
S_org_mean = mean(S_org,2);
inRange    = f>=fPeakRange(1) & f<=fPeakRange(2);
[~,iPk]    = max(S_org_mean.*inRange);
f_peak     = f(iPk);
fprintf('Detected peak at %.3f Hz\n', f_peak);

%% 2) candidate parameters (betaNum/betaDen = 0.01, i.e. -40 dB at the centre)
betaDenList = [0.2 0.3 0.3];
betaNumList = [0.05 0.06 0.15];     % ratios 0.25, 0.2, 0.5
nCase       = numel(betaDenList);
omega       = 2*pi*f_peak;

%% 3) filter every seed for every case, average the spectra
S_flt = zeros(numel(f),nCase);
for c = 1:nCase
    Sc = zeros(numel(f),nSeeds);
    for k = 1:nSeeds
        ts   = TimeResults{idxList(k)}.GenSpeed;
        Time = ts.Time;  u = ts.Data;  DT = Time(2)-Time(1);
        y    = RoscoNotchFilter(u,DT,omega,betaNumList(c),betaDenList(c));
        Sp   = EstimateAutoSpectrum(y,Time,Step,StartTime=StartTime,window=window);
        Sc(:,k) = Sp.S;
    end
    S_flt(:,c) = mean(Sc,2);
end

%% 4) plot averaged spectra
figure; hold on; grid on; box on
loglog(f,S_org_mean,'k','LineWidth',1.5)
for c = 1:nCase
    loglog(f,S_flt(:,c),'LineWidth',1.2)
end
set(gca,'XScale','log','YScale','log'); xlim([1e-2 10])
xline(f_peak,'k:',sprintf('%.2f Hz',f_peak));
xlabel('frequency [Hz]'); ylabel('PSD [(rpm)^2/Hz]')
title('GenSpeed spectrum, 24 m/s, mean of seeds 1-3')
legend(['original'; compose('betaDen = %.2f',betaDenList')],'Location','southwest')

%% 5) numbers to choose the parameters
% notch delay at low frequency (what the controller feels) from the discrete filter
fprintf('\n betaDen | peak att. [dB] | delay @0.1 Hz [s]\n');
for c = 1:nCase
    att = 10*log10(S_flt(iPk,c)/S_org_mean(iPk));
    K   = 2/DT; 
    den = K^2 + 2*omega*betaDenList(c)*K + omega^2;
    b   = [K^2+2*omega*betaNumList(c)*K+omega^2, 2*omega^2-2*K^2, K^2-2*omega*betaNumList(c)*K+omega^2]/den;
    a   = [1, (2*omega^2-2*K^2)/den, (K^2-2*omega*betaDenList(c)*K+omega^2)/den];
    ph  = unwrap(angle(freqz(b,a,[0.1 0.1001],1/DT)));        % phase at 0.1 Hz
    dly = -(ph(2)-ph(1))/(2*pi*0.0001);                       % group delay
    fprintf('  %.2f   |   %7.1f      |   %.3f\n', ...
            betaDenList(c), att, dly);
end
% % Select the first simulation
% idx = 10;
% StartTime = 60;
% % Extract generator speed
% GenSpeed_ts = TimeResults{idx}.GenSpeed;
% 
% Time = GenSpeed_ts.Time;
% GenSpeed = GenSpeed_ts.Data;
% 
% % Calculate time step
% DT = Time(2) - Time(1);
% 
% % Display basic information
% fprintf('Wind speed: 24 m/s\n');
% fprintf('Seed: 01\n');
% fprintf('Time step: %.5f s\n', DT);
% fprintf('Number of samples: %d\n', length(GenSpeed));
% % Notch filter parameters
% omega = 2*pi*1.3;
% betaNum = 0.002;
% betaDen = 0.2;
% GenSpeed_Filtered = RoscoNotchFilter(GenSpeed, DT, omega, betaNum, betaDen);
% 
% figure;
% 
% plot(Time, GenSpeed, 'b');
% hold on;
% plot(Time, GenSpeed_Filtered, 'r');
% 
% xlabel('Time (s)');
% ylabel('Generator Speed (rpm)');
% title('Original vs Notch-Filtered Generator Speed');
% legend('Original','Filtered');
% grid on;
% 
% Difference = GenSpeed - GenSpeed_Filtered;
% 
% % fprintf('Original STD: %.6f rpm\n', std(GenSpeed));
% % fprintf('Filtered STD: %.6f rpm\n', std(GenSpeed_Filtered));
% % fprintf('Difference STD: %.6f rpm\n', std(Difference));
% % fprintf('Maximum difference: %.6f rpm\n', max(abs(Difference)));
% % figure;
% % %plot(Time, Difference);
% % xlabel('Time (s)');
% % ylabel('Speed difference (rpm)');
% % title('Difference Between Original and Filtered Signals');
% % grid on;
% 
% % Frequency analysis setting
% Step = 5;
% nData = 600*100/Step;
% nBlocks = 4;
% window = nData/nBlocks;
% 
% % Original signal spectrum
% OriginalSpectrum = EstimateAutoSpectrum(GenSpeed, Time, Step, StartTime=StartTime, window=window);
% 
% % Filtered signal spectrum
% FilteredSpectrum = EstimateAutoSpectrum(GenSpeed_Filtered, Time, Step,StartTime=StartTime, window=window);
% 
% figure;
% 
% loglog(OriginalSpectrum.f, OriginalSpectrum.S, 'b', ...
%     'LineWidth', 1.2);
% hold on;
% 
% loglog(FilteredSpectrum.f, FilteredSpectrum.S, 'r--', ...
%     'LineWidth', 1.2);
% 
% xline(1.3, 'k:', '3P = 1.3 Hz');
% 
% % xlim([0.1 0.8]);
% 
% xlabel('Frequency (Hz)');
% ylabel('PSD [(rpm)^2/Hz]');
% title('Original vs Notch-Filtered Generator Speed Autospectrum');
% 
% legend('Original','Filtered','Estimated 3P');
% grid on;
% % [~, idx3P] = min(abs(OriginalSpectrum.f - 0.44));
% % 
% % S_original = OriginalSpectrum.S(idx3P);
% % S_filtered = FilteredSpectrum.S(idx3P);
% % 
% % Attenuation_dB = 10*log10(S_filtered/S_original);
% % 
% % fprintf('Frequency: %.4f Hz\n', OriginalSpectrum.f(idx3P));
% % fprintf('Original PSD: %.6e\n', S_original);
% % fprintf('Filtered PSD: %.6e\n', S_filtered);
% % fprintf('Attenuation: %.2f dB\n', Attenuation_dB);
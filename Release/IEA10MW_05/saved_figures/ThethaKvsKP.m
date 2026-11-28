ThetaK_deg = [4 5 6 7 8 9];
ThetaAngles = [0.074715 0.104855 0.127756 0.147841 0.166006 0.182149 0.197673 0.211917 0.225671 0.238919 0.251384 0.263856 0.275558 0.287072 0.298597 0.309358 0.320134 0.330914 0.341068 0.351235 0.361422 0.371155 0.380809 0.390472 0.399908 0.409125 0.418341 0.427550 0.436381 0.445192];
% Convert blade pitch angles from radians to degrees
Theta_deg = rad2deg(ThetaAngles);
KpRated = 1.869680;
figure;
hold on;
grid on;

for i = 1:length(ThetaK_deg)

    Kp = KpRated ./ (1 + ThetaAngles ./ deg2rad(ThetaK_deg(i)));

    plot(Theta_deg, Kp, 'LineWidth', 1.5);

end

xlabel('Blade Pitch Angle, \theta (deg)');
ylabel('Proportional Gain, K_P');
title('Region 3 Proportional Gain Scheduling');

legend('\theta_K = 4°', '\theta_K = 5°', ...
    '\theta_K = 6°', '\theta_K = 7°', ...
    '\theta_K = 8°','\theta_K = 9°', 'Location', 'best');

hold off;
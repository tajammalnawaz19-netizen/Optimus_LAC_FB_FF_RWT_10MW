
function y = RoscoNotchFilter(u, DT, omega, betaNum, betaDen)

% 1. Calculate Tustin constant
K = 2 / DT;

% 2. Calculate filter coefficients
den = K^2 + 2*omega*betaDen*K + omega^2;

b2 = (K^2 + 2*omega*betaNum*K + omega^2) / den;
b1 = (2*omega^2 - 2*K^2) / den;
b0 = (K^2 - 2*omega*betaNum*K + omega^2) / den;

a1 = b1;
a0 = (K^2 - 2*omega*betaDen*K + omega^2) / den;

% 3. Prepare input and output
u = u(:);
n = length(u);
y = zeros(n,1);

% 4. Initialize output
if n >= 1
    y(1) = u(1);
end

if n >= 2
    y(2) = u(2);
end

% 5. Apply recursive notch filter
for i = 3:n
    y(i) = b2*u(i) + b1*u(i-1) + b0*u(i-2) - a1*y(i-1) - a0*y(i-2);
end

end

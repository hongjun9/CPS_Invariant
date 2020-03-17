% model_validation.m
%
% test the generated model with validation data.
% compare the model response and measured output.
% input: log file (set the log full path)
%        model being validated (to be read from ss_model.mat file)
% output: comparision graph b/w model response and measured output


validation_data = '10.csv';     % log file for model validation

Ts = 0.1;                          % log interval (sec)           
model = load('ss_model.mat');
ss = c2d(model.ss_model_c, Ts);
A = ss.A; B = ss.B; C = ss.C; D = ss.D;

data = csvread(validation_data, 3, 0);
input = data(:, 3);      %target roll
output = data(:, 4);     %measured roll      
N = length(input);

y = zeros(1,N); 
x = zeros(3,N);
y(1) = 0; 
x(:, 1) = [0; 0; 0];    
u = input;

%% model response
for n=2:N                     
    y(n) = C*x(:, n) + D*u(n);         % y = Cx + Du
    x(:, n+1) = A*x(:, n) + B*u(n);    % x' = Ax + Bu
end

%%Result
%comparision graph (output vs. invariant)
figure;
fontsize = 14;
plot(1:N, output, 'r', 1:N, y, 'b');
legend({'measured', 'invariant'}, 'FontSize', 14, 'Location', 'northwest');
xlabel('time (sec)', 'FontSize',fontsize); ylabel('angle (deg)', 'FontSize',fontsize);
set(gca, 'FontSize', fontsize);


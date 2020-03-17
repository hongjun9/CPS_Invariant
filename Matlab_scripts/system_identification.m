% system_identificaiton.m
%
% build mathematical model (state-space and transfer function model) 
% of dynamic systems using measurements 
% input: logs
% output: state-space model (A,B,C,D matrices)

pathname = 'logs/';     % log directory
Ts = 0.1;               % sample time in log
Ts2 = 0.0025;           % main loop rate
files = dir(strcat(pathname, '/*.csv'));
N = length(files);
data = cell(N);
u = cell(N);            %input
y = cell(N);            %output
for i = 1:N    
    file = fullfile(pathname, files(i).name)
    D = csvread(file, 3, 0);
    u{i} = D(:, 3);     %target roll
    y{i} = D(:, 4);     %measured roll       
    data{i} = iddata(y{i}, u{i}, Ts);
end
dataset = merge(data{1:N})

% system identification (estimates transfer function)
tic
Options = tfestOptions;                       
Options.Display = 'on';                       
Options.WeightingFilter = [];                 
Options.SearchOption.MaxIter = 30;      
tf = tfest(dataset, 3, 2, Options);  % transfer function estimation
toc
[num, den] = tfdata(tf);
num = cell2mat(num);
den = cell2mat(den);
[A,B,C,D] = tf2ss(num, den);
ss_model_c = ss(A,B,C,D);               % create state-space model object
ss_model_d = c2d(ss_model_c, Ts2);      % resample discrete-time model for instrumentation into main loop
save("ss_model", "ss_model_c", "ss_model_d");

disp(datestr(now, 'HH:MM:SS.FFF'))
disp(sprintf('===================================='));
disp(sprintf('======== State Space Model ========='));
disp(sprintf('===================================='));
disp(sprintf('A:')); disp(ss_model_d.A);
disp(sprintf('B:')); disp(ss_model_d.B);
disp(sprintf('C:')); disp(ss_model_d.C);
disp(sprintf('D:')); disp(ss_model_d.D);




% selectparams.m
%
% select parameters (window and threhsold)
% input: logs used for SI, marge values (alpha_w, alpha_th)
% output: windows and trehsolds

pathname = 'logs/';     % log directory
alpha_w = 1.1;           % window margin (1.1 adds 10%)
alpha_th = 1.1;           % threhsold margin (1.1 adds 10%)

Ts = 0.1;               % sample time in log
%Ts2 = 0.0025;           % main loop rate
files = dir(strcat(pathname, '/*.csv'));
F = length(files);

model = load('ss_model.mat');
ss = c2d(model.ss_model_c, Ts);
A = ss.A; B = ss.B; C = ss.C; D = ss.D;

measured = cell(F);
invariant = cell(F);
WindowSize = 0;
ErrorThreshold = 0;
for i = 1:F    
    file = fullfile(pathname, files(i).name);
    data = csvread(file, 3, 0);
    input = data(:, 3);         % target roll
    output = data(:, 4);        % measured roll    
    N = length(input);          % total length
    ts = 1:N;
        
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
    
    measured{i} = output;
    invariant{i} = y;
    
    %% Parameter Selection -------------------------------------------
    w = select_win(output, y, alpha_w);
    WindowSize = max(w, WindowSize);
end

for i = 1:F
    output = measured{i};
    y = invariant{i};
    threshold = select_threshold(output, y, WindowSize, alpha_th);
    ErrorThreshold = max(ErrorThreshold, threshold);
end

disp(sprintf('===================================='));
disp(sprintf('======= Parameter Selection========='));
disp(sprintf('===================================='));
disp(sprintf('WindowSize:')); disp(WindowSize);
disp(sprintf('ErrorThreshold:')); disp(ErrorThreshold);

function E = select_threshold(output, yi, W, alpha)
    SP = 1;     % starting point
    CP = 1;      % current point within window
    N = length(output);
    accumulError = zeros(1, N);
    for n=1:N
        if CP > W
            SP = n;
            CP = 1;
        end
        testSignal = output(SP:SP+CP-1)';  % measured (partial)
        referenceSignal = yi(SP:SP+CP-1);   % reference (partial)
        
        deltaSignal = abs(testSignal - referenceSignal);    % displacement (partial)
        if CP ~= 1;
            accumulError(n) = immse(testSignal,referenceSignal); % squared error within Window
        end
        CP = CP+1;  
    end;
    E = max(accumulError);
    E = E * alpha;
    fprintf('* Threshold: %d\n', E);
    
    %plot error graph
%     th = E *ones(1, N);
%     ts = 1:N;
%     fontsize = 14;
%     figure; hold on;
%     area(ts, accumulError, 'FaceColor', 'r', 'FaceAlpha', 1);
%     area(ts, th, 'FaceColor', 'g', 'FaceAlpha', 0.3);
%     legend({'error', 'threshold'}, 'FontSize', fontsize, 'Location', 'northwest');
%     xlabel('time (sec)', 'FontSize',fontsize); ylabel('error', 'FontSize',fontsize);
%     set(gca, 'FontSize', fontsize);
%     title('parameter selection');
%     grid on;
%     hold off;
end

function W = select_win(output, yi, alpha)

    binsize = 5000;
    binstart = 1; binend = binstart+binsize-1;
   
    data_length = length(yi);
    W = 0;
    while binstart <= data_length
        
        if binend > data_length
           binend = data_length;
           binsize = binend - binstart + 1;
        end
        x1 = output(binstart:binend, 1)';   % measured output
        x2 = yi(binstart:binend);           % invariant
        [e_dtw, ix, iy] = dtw(x1, x2);
        %linear_dist = linear_dist + sum(x1-x2);
        %linear_score = linear_dist / binsize;
        wpath_length = length(ix);
        
        binstart = binend + 1;
        binend = binstart+binsize-1;
        w = max(abs(ix-iy));
        
        W = max(W, w);
    end  
    W = W * alpha;
    fprintf('* Window: %d\n', W);
end   
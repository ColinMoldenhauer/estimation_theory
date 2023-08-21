%% TODOS

% validate if clauses in functions

%% MATLAB settings and initialization
close all
clc
clear variables

set(groot, "defaultLineLineWidth", 1)
set(groot,'defaultAxesFontSize', 14)

rng(123)    % set seed

%% Kalman

% time parameters
t0 = 0;                     % [s]       start time
T = 20;                     % [s]       final time
dt = 0.1;                   % [s]       time step
t = t0:dt:T;                % [s]    -> time vector


% state transition matrix M & measurement matrix K
M = [1 dt dt^2/2;                       % state transition matrix/kinematic model
     0 1  dt;                           % here: 3x3 position, velocity and acceleration
     0 0  1];

K = [1 0 0];                            % measurement matrix: y = K*x
                                        % here: 1x3 only position is measured
[n, m] = size(K);                       % m: number of state variables
                                        % n: number ofmeasured quantities

% noise parameters
mu_ww = zeros(m, 1);                    % process noise mean vector
mu_yy = zeros(n, 1);                    % measurement noise mean vector

C_ww = zeros(m);                        % prior/process noise covariance matrix
                                        % here: 3x3 because of three state variables: position, velocity, acceleration
                                        % here: zeros(3) because we assume no process noise

C_yy = 20*eye(n);                       % measurement noise covariance matrix
                                        % here: 1x1 since only one parameter is measured
                                        % here: eye(1) because of assumed white noise

% kinematic parameters
v_const = 5;                            % [m/s]     constant real velocity

p0 = 0;                                 % [m]       initial "guess" position
v0 = 0.25 * v_const;                    % [m/s]     initial "guess" velocity
a0 = 0;                                 % [m/s²]    initial "guess" acceleration

p_true = p0 + v_const*t;                % [m]       true position over time
v_true = v_const*ones(size(t));         % [m/s]     true velocity over time
a_true = zeros(size(t));                % [m/s²     true acceleration over time
x_true = [p_true; v_true; a_true];      %        -> true state over time



% initialize values for iterative estimation
x_prev = [p0; v0; a0];      % initial state for iteration
C_xx_prev = C_yy;           % initial state covariance
y_history = zeros(length(K*x_prev), length(t));         % collect measurements
x_history = zeros(length(x_prev), length(t));           % collect predictions
x_estim_history = zeros(length(x_prev), length(t));     % collect estimates

print_settings(mu_ww', C_ww, mu_yy', C_yy)
for i=1:length(t)-1
    % three steps: state prediction -> measurement -> Kalman correction
    [x_curr, C_xx_curr] = state_transition(x_prev, M, mu_ww, C_ww, C_xx_prev);

    y_curr = measurement(x_true(:, i), K, mu_yy, C_yy);

    [x_curr_estim, C_xx_estim] = kalman_correction(x_curr, y_curr, K, C_xx_curr, C_yy);

    % record new states and estimates for later plotting
    x_history(:, i+1) = x_curr;
    y_history(:, i+1) = y_curr;
    x_estim_history(:, i+1) = x_curr_estim;
    
    % update variables for next iteration
    x_prev = x_curr_estim;
    C_xx_prev = C_xx_estim;
end


%% plotting
figure
hold on
sgtitle("Kalman Filtering", fontsize=20, fontweight="bold")
subplot(1,2,1)
hold on
title("Position")
plot(t, p_true, "green", DisplayName="true position")
plot(t, x_history(1, :), Color="cyan", DisplayName="predicted")
plot(t, y_history, Color="#EEAA00", DisplayName="measured")
plot(t, x_estim_history(1,:), "blue", DisplayName="Kalman filtered")
xlabel("time [s]")
ylabel("position [m]")
leg1 = legend(Location="northwest");
set(leg1.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.6]));

subplot(1,2,2)
hold on
title("Velocity & Acceleration")
plot(t, v_true, "magenta", DisplayName="true velocity")
plot(t, x_estim_history(2, :), "black", DisplayName="velocity (Kalman)")
plot(t, a_true, "magenta", LineStyle="--", DisplayName="true acceleration")
plot(t, x_estim_history(3, :), "black", LineStyle="--", DisplayName="acceleration (Kalman)")
xlabel("time [s]")
ylabel("velocity [m/s]")
leg2 = legend(Location="northwest");
set(leg2.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.6]));

%% utility functions
function print_settings(mu_ww, cov_process_noise, mean_msmt_noise, cov_msmt_noise)
    front_pad = 4;
    if sum(cov_process_noise == 0, "all") == numel(cov_process_noise)
        fprintf("No process noise!\n")
    else
        fprintf("Process noise:\n")
        print_named_matrix(mu_ww, "µ", front_pad)
        fprintf("\n")
        print_named_matrix(cov_process_noise, "σ", front_pad)
    end
    if cov_msmt_noise <= 0
        fprintf("No measurement noise!\n")
    else
        fprintf("\nMeasurement noise:\n")
        print_named_matrix(mean_msmt_noise, "µ", front_pad)
        fprintf("\n")
        print_named_matrix(cov_msmt_noise, "σ", front_pad)
    end
end

function print_named_matrix(mat, name, front_pad, prec, form, connector)
    if nargin < 6
        connector = ' = '; % connects matrix name and matrix
    end
    if nargin < 5
        form = 'f';
    end
    if nargin < 4
        prec = '3';
    end
    if nargin < 3
        front_pad = 0;
    end
    if nargin < 2
        name = '';
        connector = '';
    end

    n_pad = front_pad + length(char(name))+length(connector)+1;     % total pad n front of matrix
    form_str = [char(string(prec)) char(form)];     % formatting string
    s = sprintf([repmat([[repmat(' ',1,n_pad)], repmat(['%1.' form_str ' '],1,size(mat, 2)) '\n'], 1, size(mat, 1))], mat');

    % replace leading and trailing spaces by brackets
    s = replaceBetween(s, n_pad, n_pad, '[');
    l = length(char(s));
    s = replaceBetween(s, l-1, l, "]");
    
    % add matrix name in front
    newlines = strfind(s, newline);
    if isempty(newlines)
        row_length = length(s);
    else
        row_length = newlines(1);
    end
    n_rows = length(newlines) + 1;
    target_row = round(n_rows/2);
    s = replaceBetween(s, front_pad+row_length*(target_row-1)+1, front_pad+row_length*(target_row-1)+length(char(name))+length(connector), [char(name) connector]);
    fprintf([s '\n'])
end

%% TODOs

% add CFAR & MiniMax

%% MATLAB settings and initialization
close all
clc
clear variables

set(groot, "defaultLineLineWidth", 1)
set(groot,'defaultAxesFontSize', 14)

rng(123)    % set seed

%% settings

% define detectors: [mean0, sigm0, mean1, sigm1]
experiments = {...
    [0 2 10 5],...
    [0 2 0 2],...
    [0 2 10 2],...
    [0 2 10 10]
};


% define thresholds for ROC curve
threshs = -10:1:30;

%% ROC

syms x mu sigma
syms f0 f2

% template Gaussian
gauss = symfun(1/(sqrt(2*pi)*sigma) * exp(-(x-mu)^2/(2*sigma^2)), [x, mu, sigma]);

% setup plots
n_exp = size(experiments, 2);
[rows, cols] = get_optimal_layout(n_exp, 2);

nsr = rows;
nsc = 2*cols;

figure
for i=1:length(experiments)
    % compute ROC curve
    tic
    vals = cell2mat(experiments(i));
    f0 = subs(gauss, [mu, sigma], [vals(1), vals(2)]);
    f1 = subs(gauss, [mu, sigma], [vals(3), vals(4)]);
    [P_Fs, P_Ds] = get_roc_curve(threshs, f0, f1);
    fprintf("ROC curve %3.i:\t", i); toc
    

    % subplot ROC
    tic
    inds_all = reshape(1:nsr*nsc, [nsc, nsr])';
    subplot(nsr, nsc, reshape(inds_all(:, 1:cols), 1, []));
    hold on
    axis equal
    title("ROC curves")
    subtitle(sprintf("\\tau = [%i:%.2f:%i]", threshs(1), threshs(2)-threshs(1), threshs(end)))
    roc_line = plot(P_Fs, P_Ds, Marker="o", DisplayName=sprintf("D_%i", i));

    xticks([0 .2 .4 .6 .8 1])
    yticks([0 .2 .4 .6 .8 1])
    axis([0 1 0 1])
    legend(Location="southeast")
    xlabel("P_F")
    ylabel("P_D")
    fprintf("Plotting  %3.i:\t", i); toc


    % subplot PDFs
    i_col = cols+mod(i-1, cols)+1;
    i_row = floor((i-1)/cols);
    i_sub = i_col + i_row*(2*cols);
    subplot(nsr, nsc, i_sub)
    hold on

    title(sprintf("PDFs of D_%i", i))
    plot(threshs, get_gauss_numeric(threshs, vals(1), vals(2)), Color=roc_line.Color, LineStyle="-", LineWidth=2, DisplayName=sprintf("H_0: µ = %i, σ = %i", vals(1), vals(2)))
    plot(threshs, get_gauss_numeric(threshs, vals(3), vals(4)), Color=roc_line.Color, LineStyle=":", LineWidth=2, DisplayName=sprintf("H_1: µ = %i, σ = %i", vals(3), vals(4)))
    leg = legend;
    set(leg.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.6]));
end

%% utility functions

function g = get_gauss_numeric(x, mu, sigma)
    g = 1/(sqrt(2*pi)*sigma) * exp(-(x-mu).^2/(2*sigma^2));
end

function [rows, cols] = get_optimal_layout(n, ratio)
    rows = ceil(sqrt(n/ratio));
    cols = floor(n/rows);
    if rows*cols < n
        cols = cols+1;
    end
end

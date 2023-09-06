close all
clc

set(groot, "defaultLineLineWidth", 2)
set(groot,'defaultAxesFontSize', 14)


%% experiments
exps = {
    [50; 40],...
    [90; 0],...
    [50; 40; -30],...
    [50; -30]
    };

% setup plots
n_exp = size(exps, 2);
[rows, cols] = get_optimal_layout(n_exp, 2);

nsr = rows;
nsc = 2*cols;

% single experiment
figure
hold on
axis equal
plot_measurement_arrangement([50, 40])
xl = xlim;
xlim([-3.5 xl(2)])


figure
hold on
axis equal
legend_entries = [];
for i=1:length(exps)
    phis = cell2mat(exps(i));
    K = [sind(phis), -cosd(phis)];
    C_d = inv(K'*K);
    
    % subplot error ellipse
    inds_all = reshape(1:nsr*nsc, [nsc, nsr])';
    subplot(nsr, nsc, reshape(inds_all(:, 1:cols), 1, []));
    hold on
    axis equal
    title("Error Ellipses")
%     subtitle(sprintf("\\tau = [%i:%.2f:%i]", threshs(1), threshs(2)-threshs(1), threshs(end)))
%     roc_line = plot(P_Fs, P_Ds, Marker="o", DisplayName=sprintf("D_%i", i));

    [a, b, theta] = plot_error_ellipse(C_d);
    lines = findall(gca, "Type", "Line");
    curr_line = lines(1);

    lim = 1.5;
    axis([-lim, lim, -lim, lim])
    legend_entries = [legend_entries, ...
%         sprintf("\nΦ = ["+ string(repmat('%1.0f ',1,numel(phis)))+"] \nθ = %.4f", phis, theta)];
            sprintf("θ = %.4f", theta)];


    fprintf([...
        'Φ = [' ...
            repmat('%1.0f ',1,numel(phis)) ']\n'...
        'covariance matrix: \n' ...
            repmat([repmat('\t%1.3f',1,size(C_d, 1)) '\n'], 1, size(C_d, 2)) ...
        'ellipse parameters:\n' ...
        '\ta\t%4.2f\n\tb\t%4.2f\n\tθ\t%4.2f\n\n'
        ], phis, C_d, a, b, theta)

    % subplot arrangements
    i_col = cols+mod(i-1, cols)+1;
    i_row = floor((i-1)/cols);
    i_sub = i_col + i_row*(2*cols);
    subplot(nsr, nsc, i_sub)
    hold on
%     axis equal
    plot_measurement_arrangement(phis)
    ax = gca;
    ax.XColor = curr_line.Color;
    ax.YColor = curr_line.Color;
    ax.LineWidth = 3;
    % handle individual legends for multiplot
    leg = legend();
    delete(leg);
end
subplot(nsr, nsc, reshape(inds_all(:, 1:cols), 1, []));
leg = legend(legend_entries, Location="southoutside", NumColumns=cols);
set(leg.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.6]));
% lim = 1.5;
% axis([-lim, lim, -lim, lim])


%% functions
function [a, b, theta] = plot_error_ellipse(covariance_matrix)
    eig_values = eig(covariance_matrix);
    a = eig_values(2);
    b = eig_values(1);

    std1 = sqrt(covariance_matrix(1, 1));
    std2 = sqrt(covariance_matrix(2, 2));
    theta = atan2(std2, std1);

    plot_ellipse(a, b, theta);
end

% TODO: make axis plotting optional
function plot_ellipse(a, b, theta, dx, dy)
    if nargin < 4
        dx = 0;
        dy = 0;
    elseif nargin < 5
        dy = 0;
    end

    alpha = 0:.01:2*pi;
    x = a*cos(alpha)*cos(theta) - b*sin(alpha)*sin(theta) + dx;
    y = a*cos(alpha)*sin(theta) + b*sin(alpha)*cos(theta) + dy;

    % plot ellipse and major axes
    ellips = plot(x,y);
    xl = xlim;
    yl = ylim;
    xmajor = xl(1):0.1:xl(2);
    ymajor = xmajor*tan(theta);
    ymajor(ymajor < yl(1)) = nan;
    ymajor(ymajor > yl(2)) = nan;
    plot(xmajor, ymajor, Color=ellips.Color, LineWidth=1, LineStyle="--", HandleVisibility="off")
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


function plot_measurement_arrangement(exps)
    R = 4;     % sensor distance

    % plot ref system
    x0 = -0.9*R*sind(max(exps));    % TODO: automatic placement depending on exps
    y0 = 0;
    l_CRS = 0.1*R;
    quiver([x0 x0], [y0 y0], [l_CRS 0], [0 l_CRS], "off", Color="black",...
        LineWidth=1.5, MaxHeadSize=10, HandleVisibility="off")
    offs = 0.03;
    text([x0+l_CRS+offs x0+offs], [y0+offs y0+l_CRS+offs], ["x", "z"], FontSize=5*R, VerticalAlignment="baseline")

    % plot movement direction
    V = 2;
    angle_movement = 30;            % [deg]
    dx = V*cosd(angle_movement);
    dz = V*sind(angle_movement);
    vel = [dx; dz];
    
    obj_other = [];
    for i=1:length(exps)
        theta = exps(i);
        % plot sensor
        size_sensor = 200;
        x_sens = -R*sind(theta);
        z_sens = R*cosd(theta);
        p = [x_sens; z_sens];
        sensor = scatter(x_sens, z_sens, size_sensor,...
            Marker="diamond", MarkerFaceColor="flat", DisplayName=sprintf("Sensor %i", i));

        % plot line of sight
        line_width_connector = 0.5;
        plot([x_sens, 0], [z_sens, 0], Color=sensor.CData, LineWidth=line_width_connector,...
            LineStyle="-.", HandleVisibility="off")

        % plot r
        r = ((vel'*p) / (p'*p)) * p;
        obj_r = draw_arrow(r(1), r(2), 0, 0, Color=sensor.CData, LineWidth=1, DisplayName=sprintf("projected velocity $\\vec{r}_%i$", i));
        obj_other = [obj_other sensor obj_r];
        
        % plot projection lines
        line_width_proj = 0.5;
        plot([r(1) vel(1)], [r(2) vel(2)], LineWidth=line_width_proj, Color="#DDDDDD", HandleVisibility="off")

        % plot angle
%         l_zeroline = 2*l_CRS;
        l_zeroline = 0.5*l_CRS;
        r_arc = 0.9*l_zeroline;
%         dist_fac = 1.3;
        dist_fac = 1.5;
        phi_fontsize = 14;

        angle1 = 270;
        angle2 = 270+theta;
        start_angle = min(angle1, angle2);
        end_angle = max(angle1, angle2);
        theta_arc = start_angle:end_angle;
        plot([x_sens x_sens], [z_sens, z_sens-l_zeroline], "black", LineWidth=1, HandleVisibility="off")
        plot(x_sens + r_arc*cosd(theta_arc), z_sens+r_arc*sind(theta_arc), "black", LineWidth=1, HandleVisibility="off")
        l_arc = length(theta_arc);
        if l_arc > 2
            theta_center = theta_arc(floor(l_arc/2));
        else
            theta_center = -75;
        end
        text(x_sens + dist_fac*r_arc*cosd(theta_center), z_sens + dist_fac*r_arc*sind(theta_center), sprintf("$\\Phi_%i$", i),...
            FontSize=phi_fontsize, VerticalAlignment="middle", HorizontalAlignment="center", Interpreter="latex")
    end
    
    % plot target objects last to avoid overlaps
    % plot target velocity
    obj_vel = quiver(0, 0, dx, dz, "off", Color="#7700DD", LineWidth=2, DisplayName="target velocity");
    text(0.5*V*cosd(angle_movement), 0.7*V*sind(angle_movement), "$\vec{v}$",...
        Color=obj_vel.Color, Interpreter="latex", FontSize=20)

    % plot target
    obj_target = scatter(0, 0, 300, MarkerFaceColor="#AADDFF", MarkerEdgeColor="#0022FF", DisplayName="target");

    leg = legend([obj_target, obj_vel, obj_other], Interpreter="latex");
    set(leg.BoxFace, 'ColorType','truecoloralpha', 'ColorData',uint8(255*[1;1;1;.6]));
end

% TODO: handle axis non-equal
function arrow = draw_arrow(x, y, x0, y0, varargin)
    dx = x - x0;
    dy = y - y0;
    theta = atan2d(dy, dx);

    arrowheadlength = 0.1 * sqrt(x^2 + y^2);
    arrowheadangle = 30;

    % plot arrow
    arrow = plot([x0 x NaN x x-arrowheadlength*cosd(theta+arrowheadangle) NaN x x-arrowheadlength*cosd(theta-arrowheadangle)],...
                 [y0 y NaN y y-arrowheadlength*sind(theta+arrowheadangle) NaN y y-arrowheadlength*sind(theta-arrowheadangle)],...
                  varargin{:});
end


function [rows, cols] = get_optimal_layout(n, ratio)
    rows = ceil(sqrt(n/ratio));
    cols = floor(n/rows);
    if rows*cols < n
        cols = cols+1;
    end
end
clear; clc; close all; config_scaling_reflector;

%% * Load batch data
indexSet = 1 : nBatches;
rateSet = zeros(nBatches, length(Variable.nReflectors));
currentLinearSet = zeros(nBatches, length(Variable.nReflectors));
currentNonlinearSet = zeros(nBatches, length(Variable.nReflectors));
for iBatch = 1 : nBatches
    try
        load(sprintf('../data/scaling_reflector/scaling_reflector_%d.mat', iBatch), 'rateInstance', 'currentLinearInstance', 'currentNonlinearInstance');
        rateSet(iBatch, :) = rateInstance;
        currentLinearSet(iBatch, :) = currentLinearInstance;
        currentNonlinearSet(iBatch, :) = currentNonlinearInstance;
    catch
		indexSet(indexSet == iBatch) = [];
        disp(iBatch);
    end
end

%% * Average over batches
rate = mean(rateSet(indexSet, :), 1);
currentLinear = mean(currentLinearSet(indexSet, :), 1);
currentNonlinear = mean(currentNonlinearSet(indexSet, :), 1);
snrDb = pow2db(2 .^ (rate / nSubbands));
save('../data/scaling_reflector.mat');

%% * Rate and current plots
figure('name', 'Per-subband rate and average output DC current vs number of reflectors');
pathlossPlot = tiledlayout(3, 1, 'tilespacing', 'compact');

% * SNR plot
nexttile;
plotHandle = plot(Variable.nReflectors, snrDb);
grid minor;
legend('WIT', 'location', 'nw');
xlabel('Number of reflectors');
ylabel('SNR [dB]');
xlim([1 inf]);
xticks(Variable.nReflectors(1 : 2 : end));

apply_style(plotHandle);

% * Rate plot
nexttile;
% plotHandle = plot(Variable.nReflectors, rate / nSubbands);
plotHandle = plot(Variable.nReflectors, snrDb);
grid minor;
legend('WIT', 'location', 'nw');
xlabel('Number of reflectors');
ylabel('Per-subband rate [bps/Hz]');
xlim([1 inf]);
xticks(Variable.nReflectors(1 : 2 : end));

apply_style(plotHandle);

% * Current plot
nexttile;
plotHandle = gobjects(1, 2);
hold all;
plotHandle(1) = plot(Variable.nReflectors, 1e6 * currentLinear);
plotHandle(2) = plot(Variable.nReflectors, 1e6 * currentNonlinear);
hold off;
grid minor;
legend('Linear WPT', 'Nonlinear WPT', 'location', 'nw');
xlabel('Number of reflectors');
ylabel('Average output DC current [$\mu$A]');
xlim([1 inf]);
xticks(Variable.nReflectors(1 : 2 : end));

apply_style(plotHandle);
savefig('../figures/scaling_reflector.fig');
matlab2tikz('../../assets/scaling_reflector.tex');
function [tapGain, tapDelay] = tap_tgn(corTx, corRx, propagationMode)
    % Function:
    %   - simulate tapped delay line based on IEEE TGn channel model D
    %
    % Input:
    %   - corTx (R_t) [nTxs * nTxs]: transmit correlation matrix
    %   - corRx (R_r) [nRxs * nRxs]: receive correlation matrix
    %   - propagationMode: propagration mode ('los', 'nlos')
    %
    % Output:
    %   - tapGain [nTaps * nTxs * nRxs]: complex tap gain
    %   - tapDelay [nTaps * 1]: tap delays
    %
    % Comment:
    %   - for single-user MIMO, consider spatial correlation
    %   - use power delay profile and path loss of IEEE TGn channel model D
    %   - for each tap, the LoS component is fixed while the NLoS component consists of spatially correlated variables
    %   - Ricean factor varies for  LoS and NLoS conditions
    %   - LoS matrix entries are unit-modulus
    %
    % Reference:
    %   - V. Erceg et al., "TGn channel models," in Version 4. IEEE 802.11–03/940r4, May 2004.
    %
    % Author & Date: Yang (i@snowztail.com) - 07 Mar 20


    % * Define parameters
    nTxs = size(corTx, 1);
    nRxs = size(corRx, 1);
    nClusters = 3;
    nTaps = 18;
    tapDelay = 1e-9 * [0 10 20 30 40 50 60 70 80 90 110 140 170 200 240 290 340 390]';
    tapPower = zeros(nClusters, nTaps);
    tapPower(1, :) = db2pow([0 -0.9 -1.7 -2.6 -3.5 -4.3 -5.2 -6.1 -6.9 -7.8 -9.0 -11.1 -13.7 -16.3 -19.3 -23.2 -inf -inf]);
    tapPower(2, :) = db2pow([-inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -6.6 -9.5 -12.1 -14.7 -17.4 -21.9 -25.5 -inf]);
    tapPower(3, :) = db2pow([-inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -inf -18.8 -23.2 -25.2 -26.7]);
	losRiceanFactor = [db2pow(3), db2pow(repmat(-inf, [1, nTaps - 1]))];
	nlosRiceanFactor = db2pow(repmat(-inf, [1, nTaps]));

    % * Generate LoS matrix
    losMatrix = exp(1i * 2 * pi * rand(nRxs, nTxs));

    % * Generate tap gains and sum over clusters
    losGain = zeros(nClusters, nTaps, nRxs, nTxs);
    nlosGain = zeros(nClusters, nTaps, nRxs, nTxs);
    tapGain = zeros(nClusters, nTaps, nRxs, nTxs);
    for iCluster = 1 : nClusters
		for iTap = 1 : nTaps
			if propagationMode == "los"
				riceanFactor = losRiceanFactor;
			elseif propagationMode == "nlos"
				riceanFactor = nlosRiceanFactor;
			end
			losGain(iCluster, iTap, :, :) = sqrt(riceanFactor(iTap) / (riceanFactor(iTap) + 1)) * losMatrix;
			nlosGain(iCluster, iTap, :, :) = sqrt(1 / (riceanFactor(iTap) + 1)) * (corRx ^ (1 / 2) * sqrt(1 / 2) * (randn(nRxs, nTxs) + 1i * randn(nRxs, nTxs)) * corTx ^ (1 / 2));
            tapGain(iCluster, iTap, :, :) = sqrt(tapPower(iCluster, iTap)) * (losGain(iCluster, iTap, :, :) + nlosGain(iCluster, iTap, :, :));
		end
    end

    % * Sum over clusters and reshape to [nTaps, nTxs, nRxs]
    tapGain = permute(sum(tapGain, 1), [2 4 3 1]);

end

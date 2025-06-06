function [fitness, avgSP, maxSP] = evaluateFitness(individual, G, Cmax, penaltyFactor)
% Evaluate fitness of an individual
% Inputs:
%   individual - vector of selected node indices
%   G - graph representing the network
%   Cmax - maximum allowed shortest path length between controllers
%   penaltyFactor - penalty factor for constraint violations (optional)
% Outputs:
%   fitness - fitness value (lower is better, but we'll convert for GA)
%   avgSP - average shortest path length
%   maxSP - maximum shortest path between controllers

    if nargin < 4
        penaltyFactor = 1000; % Default penalty factor
    end

    % Evaluate using PerfSNS function
    [avgSP, maxSP] = PerfSNS(G, individual);

    % Handle constraint violation
    if maxSP > Cmax
        % Apply penalty for constraint violation
        penalty = avgSP + penaltyFactor * (maxSP - Cmax);
    else
        penalty = avgSP;
    end

    % Convert to maximization problem (GA typically maximizes fitness)
    % Use negative of objective or inverse transformation
    fitness = 1 / (1 + penalty); % Higher fitness = better solution
end
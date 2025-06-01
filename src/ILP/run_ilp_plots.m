% Script to run all ILP plotting functions

fprintf('Generating ILP plots...\n\n');

% Plot the ILP solution network
fprintf('1. Plotting ILP solution network...\n');
plot_ilp_solution();

% Plot ILP analysis and comparison with GRASP
fprintf('\n2. Generating ILP analysis plots...\n');
plot_ilp_analysis();

% Plot simple comparison
fprintf('\n3. Generating simple comparison plot...\n');
plot_ilp_comparison();

fprintf('\nAll plots generated successfully!\n');
fprintf('Check the plots/ directory for the following files:\n');
fprintf('- ilp_solution_run_1.png (network visualization)\n');
fprintf('- ilp_analysis.png (detailed analysis)\n');
fprintf('- ilp_vs_grasp_solutions.png (side-by-side comparison)\n');
fprintf('- ilp_comparison_simple.png (bar chart comparison)\n');
%This runs the integer linear programming method
clear all
tic
filename = '500.1';
disp(filename)
discs = csvread(strcat(filename,'.csv'));
%Sort rows first by x and then y.
%intersection_candidates(discs, 0.4, 0.1, 0.05)
[B,index] = sortrows(discs,[-3 -2]);

%The cache file may need to be precomputed with
%generate_intersections_range_runpar.m if it isn't there.
cache = load(strcat('intersections/',filename,'.intersections.mat'));
intersection_cache = cache.A(:,index); %reorder the intersection matrix to match our sort!
max_time = 60
[area, ind_keep] = ILP_gurobi(B,intersection_cache,max_time);
plotdiscs(discs(index(ind_keep),:));
csvwrite(strcat('solutions/sol_for_',filename,'_',sprintf('%f',area),'.csv'),discs(index(ind_keep),:));
csvwrite(strcat('solutions/ind_sol_for_',filename,'_',sprintf('%f',area),'.csv'),index(ind_keep));
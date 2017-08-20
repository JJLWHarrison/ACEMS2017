% This runs the Iterated_ILP_intersection_cache method.
% 10000.1
clear all
addpath('/cm/software/apps/gurobi/7.5.1/matlab')
filename = '200.1'

%This is the time target.
% Much more than a few days doesn't tend to yield better solutions
% than a few weeks for the bigger problems.
max_time = 125*3600 

% Number of regions to divide the soltion region in to.
% Too low and the solver won't converge in each section.
% Too high and more voids seem to appear.
% 3 worked best for 10000.1
% 5 worked best for 50000.1 
number_of_iterations = 3
discs = csvread(strcat(filename,'.csv'));

%Sort rows first by x and then y.
% Iterated_ILP_intersection_cache() assumes this, it'd be better if this
% logic was in there, but I never got around to moving it. 
disp('Beginning sort...')
[B,index] = sortrows(discs,[-3 -2]);
disp('Done.')

disp('Loading intersection cache...')
cache = load(strcat('intersections/',filename,'.intersections.mat'));
disp('Done.')

disp('Reindexing intersection cache to match sort...')
intersection_cache = cache.A(:,index); %reorder the intersection matrix to match our sort!
disp('Done.')

disp('Beginning iterated ILP...')
[area, ind_keep] = Iterated_ILP_intersection_cache(B,intersection_cache,max_time,number_of_iterations);
disp('Done.')

%output the area
area 

%output indicies of discs to csv
csvwrite(strcat('solutions/ind_sol_for_',filename,'_',sprintf('%f',area),'.csv'),index(ind_keep));

%output discs to csv
csvwrite(strcat('solutions/sol_for_',filename,'_',sprintf('%f', area),'.csv'),discs(index(ind_keep),:));
% This script generates the intersection matrix needed by the iterated ILP
% and ILP scripts. Rather than use a smart algorithm brute force
% parallelism is used. It'll take about an hour for the 50000.1 case.
filename = '200.1'

discs = csvread(strcat(filename,'.csv'));
N = size(discs,1);


partitions = 1000;
A = sparse(0,N);
bounds = [];
for i = 0:(partitions)
    bounds = [bounds min(floor(i*N/partitions+1),N)];
end

parfor i = 1:partitions
    A = [A; generate_intersections_range(discs,bounds(i),bounds(i+1))];
end

save(strcat('intersections/',filename,'.intersections.mat'),'A','-v7.3');
%
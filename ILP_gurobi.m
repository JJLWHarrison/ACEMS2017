% Attempts to optimally pack the discs by phrasing the optimization problem
% as an integer linear program and then using gurobi. 
% discs contains the discs. 
% A is a matrix of pre-computed pairwise intersection enconding
% constraints. It must be sparse for bigger problems.
% time is an attempted time limit. 
% It performs well up to 1000 discs, finding the optimum solution.
% For more than 1000 discs Iterated_ILP_intersection_cache() will perform
% better with the right parameters.
function [area, ind_keep] = ILP_gurobi(discs, A, time)
    %Put the number of discs in N (i.e. the size of the first dimension.
    N = size(discs,1);
    

    % Our problem will have one design variable x_i for each circle.
    % f^T x gives us the minus the area area of the design variables 
    %x = (x_1, ..., x_N) equal. Since the solver minimizes we minimize the
    %negative area, i.e. maximize the area. The overlapping is dealt with in
    %the problem constraints
    f = zeros(N,1);
    for i=1:N
        f(i) = -pi*discs(i,3)^2;
    end 

    % intcon are the design variables which are integers. i.e. all of them.
    intcon = 1:1:N;
    % lb is the lower bounds of the design variables. 0 for each in our case.
    lb = zeros(N,1);
    % ub is the upper bounds of the design variables. 1 for each in our case.
    ub = ones(N,1);
   
    % The matrix A and vector b to
    % encode the constraint that x_i + x_j <= 1 whenever i != j. 

    toc
    disp('Done. Starting intlinprog solver...')

    b = ones(size(A,1),1);

    Aeq = []
    beq = []
    
    % Solve the ILP. Matlab's intlinprog is more or less a slot in 
    % replacement here. But it's much slower and can't find the optimal
    % solution for anything harder than the 500.1 case in a reasonable
    % period of time. 
    solution = gurobi_intlinprog_time(f, intcon, A, b, Aeq, beq, lb, ub,time );

    ind_keep = [];
    for i=1:N
        if solution(i) > 0.5
            ind_keep = [ind_keep, i];
        end
    end

    count = size(ind_keep,2);
    area = -transpose(f)*solution;
    sprintf('# of disks = %d,  area = %f \n',count,area)
end

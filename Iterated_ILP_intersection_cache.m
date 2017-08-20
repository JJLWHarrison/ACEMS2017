% Attempts to optimally pack the discs by phrasing the optimization problem
% as an integer linear program and then using gurobi. 
% discs contains the discs. 
% The region is then divided into number_of_iterations sections, and the 
% constraints are adjusted so that one section is 'packed' at a time, 
% whilst holding the other sections in their previous state
% (regarding empty as the initial state). 
% For all but the last section we use a modified objective function which
% attempts to pack the discs more closely to one axis, rather than just
% maximize the area.
%
% A is a matrix of pre-computed pairwise intersection enconding
% constraints. It must be sparse for bigger problems.
% time is an attempted time limit. 
% It performs well up to 1000 discs, finding the optimum solution.
% For more than 1000 discs Iterated_ILP_intersection_cache() will perform
% better with the right parameters.

function [area, ind_keep] = Iterated_ILP_intersection_cache( discs,intersection_matrix,max_time,number_of_iterations)

    N = size(discs,1);
    a = zeros(N,1);
	
	%We'll use this for occasional area updates whilst the program is running.
    for i=1:N
        a(i) = -pi*discs(i,3)^2; 
    end 
    
    % Our problem will have one design variable x_i for each circle.
    % f^T x gives us the minus the area area of the design variables 
    %x = (x_1, ..., x_N) equal. Since the solver minimizes we minimize the
    %negative area, i.e. maximize the area. The overlapping is dealt with in
    %the problem constraints
    f = zeros(N,1);
    for i=1:N
        f(i) = -pi*discs(i,3)^2 -pi*discs(i,1)*pi*discs(i,3)^2 - pi*discs(i,2)*pi*discs(i,3)^2/200;
		%also try and maximize y, but not at the expense of an extra disc. Weight determined by experimentation.

    end 
    
    % The matrix A and vector b to
    % encode the constraint that x_i + x_j <= 1 whenever i != j. 

    A = sparse(intersection_matrix);
    b = ones(size(A,1),1);
    
    Aeq = [];
    beq = [];
    
    % intcon are the design variables which are integers. i.e. all of them.
    intcon = 1:1:N;
    % lb is the lower bounds of the design variables. 0 for each in our case.
    lb = zeros(N,1);
    
    tic
    %Start optimizing strips
    for i=1:number_of_iterations-1
		% Constrain part of the region to be 0.
        % The floor(N/(8*number_of_iterations) is a fudge to make the first
        % strips smaller (since we're working with disc centers.
        ub = ones(N,1) - 0.5*[zeros(floor(i*N/number_of_iterations) - floor(N/(8*number_of_iterations)),1); ones(N+floor(N/(8*number_of_iterations))-floor(i*N/number_of_iterations),1)];
        time = max_time/number_of_iterations 
        solution = gurobi_intlinprog_time(f, intcon, A, b, Aeq, beq, lb, ub, time);%Figure out the best choice of vectors
        
        %compute the current area and output.
        current_area = -transpose(a)*solution
        toc

        % Use what we just worked out to fix part of the solution for the
        % next round.
        lb = zeros(N,1) + solution*0.5;

    end
    
    %Start end pass.
    f = zeros(N,1);
    for i=1:N
	    % Now we just maximize area.
        f(i) = -pi*discs(i,3)^2;
    end 
    
    % Trying to solve whatever is left. 
    ub = ones(N,1);
    
    time = max_time/number_of_iterations
    solution = gurobi_intlinprog_time(f, intcon, A, b, Aeq, beq, lb, ub, time);
    toc
      
    %Build the vector of indicies for output. 
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

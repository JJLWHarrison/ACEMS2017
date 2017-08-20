% JJHarrison_mixed_ILP_and_sorted_greedy() is my (John J. Harrison) entry 
% for the ACEMS 2017 student competition. 
%
% Details:
% https://acems.org.au/2017-student-competition
% 
%Sample syntax for hidden solution function
% [area_final, ind_final] = JJHarrison_mixed_ILP_and_sorted_greedy('1000.1.hidden.csv')
% 
% Various helper functions are in this file below the actual submission.
%
function [area_final, ind_final] = JJHarrison_mixed_ILP_iteratedILP_and_sorted_greedy(filename)
    discs = csvread(filename);
    N_discs = size(discs,1);
    area_final = 0;
    ind_final = [];
    % First we will try four greedy approaches where we heuristically
    % choose circles in such a way to maximize the packing, prefering
    % circles closest to one of the four "ends" first. This approach could
    % be improved by trying to pack on lots of different angles with many 
    % starting points. Seems like too much effort though!
    % Since sorting occurs this is O(N log N). The greedy bit is O(N).
    % With my core i7-7700k running another job on a different core it
    % takes:
    % ~1 second for 500.1.csv
    % ~33 seconds for 10000.1.csv
    % ~184 seconds for 50000.1.csv
    disp('Trying sorted greedy method...')
    tic
    [B,index] = sortrows(discs,[-3 -2]);
    [area, ind_keep] = JJHarrison_greedy(discs,index);
    if(area > area_final)
        area_final=area;
        ind_final=ind_keep;
    end
    [B,index] = sortrows(discs,[-3 2]);
    [area, ind_keep] = JJHarrison_greedy(discs,index);
    if(area > area_final)
        area_final=area;
        ind_final=ind_keep;
    end
    [B,index] = sortrows(discs,[-3 1]);
    [area, ind_keep] = JJHarrison_greedy(discs,index);
    if(area > area_final)
        area_final=area;
        ind_final=ind_keep;
    end
    [B,index] = sortrows(discs,[-3 -1]);
    [area, ind_keep] = JJHarrison_greedy(discs,index);
    if(area > area_final)
        area_final=area;
        ind_final=ind_keep;
    end
    toc
    disp('Finished sorted greedy method.')
    % The smaller problems can be approached by treating them as an integer
    % linear program with one variable x_i per circle, 1 for included, 0 for
    % not, constraints x_i + x_j <= 1 if x_i and x_j intersect, 
    % 0 <= x_i <= 1 , x_i integers.
    %We do that below if N_discs isn't too big. It doesn't tend to get a better
    %solution than the one above in under 15 minutes and more than 500
    %circles on my machine. Doesn't cope with big data sets either because
    %the matlab solver says it is out of memory. 
    %Also, the method of finding pairwise circle intersections to build the
    %constraint matrix is inefficient (O(N^2)). Building a quadtree
    %with the points could speed that part up a lot.
    if N_discs < 750
        disp('Trying ILP...')
        [area, ind_keep] = JJHarrison_ILP(discs);
        if(area > area_final)
            area_final=area;
            ind_final=ind_keep;
        end
        toc
        disp('Finished ILP.')
    elseif N_discs < 1250 && N_discs > 750
        disp('Trying two stage ILP...')
        [area, ind_keep] = JJHarrison_iterated_ILP(sortrows(discs,[-3 -2]),2);
        if(area > area_final)
            area_final=area;
            ind_final=ind_keep;
        end
        toc
        disp('Finished two stage ILP.')
    else
        disp('Skipping ILP and multistage ILP because there are too many discs to bother!')
    end 
    ind_final=transpose(ind_final)
end

function [area, ind_keep] = JJHarrison_greedy( discs, index )

    %Read all the discs from the csv into a matrix
    %One row per disc. Each row is x,y,radius
    %Put the number of discs in N (i.e. the size of the first dimension.
    N = size(discs,1);




    %We'll keep the first disc since we're doing a greedy algorithm
    ind = index(1);
    ind_keep = ind; %This will store the indicies we decide to keep (row vector)
    discs_keep = discs(ind,:); %This will store the rows of discs we keep

    %Iterate on the remaining discs
    for i=2:N
        ind = index(i);

        %Check if the current disc overlaps any of the ones we are keeping
        if (JJHarrison_not_overlap(discs(ind,:),discs_keep))
            %If it doesn't, store the discs in discs_keep and indicies in
            %ind_keep
            discs_keep = [discs_keep;discs(ind,:)];
            ind_keep = [ind_keep, ind];
        end
        %If there is overlap we just go to the next disc.
    end


    %Compute the area
    area = 0;
    for i=1:size(discs_keep,1)
        area = area + pi*discs_keep(i,3)^2;
    end
end

function [area, ind_keep] = JJHarrison_ILP( discs )
    %Put the number of discs in N (i.e. the size of the first dimension.
    N = size(discs,1);

    %We will use MATLAB's
    %intlinprog(f,intcon,A,b,Aeq,beq,lb,ub)
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

    % We prevent intersections by constructing the matrix A and vector b to
    % encode the constraint that x_i + x_j <= 1 whenever i != j. 

    %Build the constraint matrix.
    %Need to have x_i + x_j <= 1 for every pair of points that intersect.
    disp('Constructing sparse intersection matrix...')
    A = sparse(N^2,N); %Start with an empty sparse matrix
    tic
    for i=1:N
        %Iterate through each circle, find the intersecting circles and add each
        %intersection as a row in A. Takes O(N^2) iterations since finding the 
        % overlap is currently O(N) time and we do it for each row.
        % This would be a lot faster with a quadtree implentation.
        overlap_ind = JJHarrison_get_overlap_ind(discs(i,:),discs);
        
        for j=1:size(overlap_ind,2) %O(N)
            A((N-1)*i+j, i) = 1;
            A((N-1)*i+j, overlap_ind(j)) = 1;
        end
    end
    toc
    disp('Done. Starting intlinprog solver...')

    b = ones(N^2,1);

    options = optimoptions('intlinprog','MaxTime',780); 
    %Allow 13mins for the ILP solver conservatively allowing enough time 
    %for the greedy approach above.

    problem = struct('f',f,'intcon',intcon,...
        'Aineq',A,'bineq',b,...
        'lb',lb,'ub',ub,'options',options,...
        'solver','intlinprog');

    solution = intlinprog(problem);%Figure out the best choice of vectors

    ind_keep = [];
    for i=1:N
        %Construct the list of circle indicies we kept. 
        if solution(i) > 0.5
            ind_keep = [ind_keep, i];
        end
    end

    count = size(ind_keep,2);
    area = -transpose(f)*solution;
end

function [area, ind_keep] = JJHarrison_iterated_ILP( discs,number_of_iterations )

    %Put the number of discs in N (i.e. the size of the first dimension.
    N = size(discs,1);




    %We will use MATLAB's
    %intlinprog(f,intcon,A,b,Aeq,beq,lb,ub)
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
    ub = ones(N,1) - 0.5*[zeros(floor(N/number_of_iterations),1); ones(N-floor(N/number_of_iterations),1)];
    
    % We prevent intersections by constructing the matrix A and vector b to
    % encode the constraint that x_i + x_j <= 1 whenever i != j. 

    %Build the constraint matrix.
    %Need to have x_i + x_j <= 1 for every pair of points that intersect.
    disp('Constructing sparse intersection matrix...')
    A = sparse(N^2,N); %Start with an empty sparse matrix
    tic
    for i=1:N
        %Iterate through each circle, find the intersecting circles and add each
        %intersection as a row in A. Takes o(N^2) iterations since finding the 
        % overlap is currently O(N) time and we do it for each row.
        % This would be a lot faster with a quadtree implentation or similar.
        overlap_ind = JJHarrison_get_overlap_ind(discs(i,:),discs);
        %overlap_ind_new = get_overlap_ind_fast(discs(i,:),discs) %O(N)
        for j=1:size(overlap_ind,2) %O(N)
            A((N-1)*i+j, i) = 1;
            A((N-1)*i+j, overlap_ind(j)) = 1;
        end
    end
    toc
    disp('Done. Starting intlinprog solver...')

    b = ones(N^2,1);

    options = optimoptions('intlinprog','MaxTime',400); 
    %Allow 13mins for the ILP solver conservatively allowing enough time 
    %for the greedy approach above.

    problem = struct('f',f,'intcon',intcon,...
        'Aineq',A,'bineq',b,...
        'lb',lb,'ub',ub,'options',options,...
        'solver','intlinprog');

    solution = intlinprog(problem);%Figure out the best choice of vectors
    
    lb = zeros(N,1) + solution*0.5;
    ub = ones(N,1);

    problem = struct('f',f,'intcon',intcon,...
        'Aineq',A,'bineq',b,...
        'lb',lb,'ub',ub,'options',options,...
        'solver','intlinprog');

    solution = intlinprog(problem);
    
    
    ind_keep = [];
    for i=1:N
        %Construct the list of circle indicies we kept. 
        if solution(i) > 0.5
            ind_keep = [ind_keep, i];
        end
    end

    count = size(ind_keep,2);
    area = -transpose(f)*solution;
end


function overlap_ind = JJHarrison_get_overlap_ind(master_disc,discs)
    %function [overlap_discs, overlap_ind] = get_overlap(master_disc,discs)
    N = size(discs,1);

    overlap_ind = [];
    %overlap_discs = [];

    %Iterate on the remaining discs
    for i=1:N
        if JJHarrison_overlap(master_disc,discs(i,:));
            %if the two discs overlap, add the constraint
             overlap_ind = [overlap_ind, i];
             %overlap_discs = [overlap_discs;discs(i,:)];
        end
    end
end

function out = JJHarrison_overlap(disc1,disc2)
        %This is a modified version of the example provided in the competition
        %that only figures out if two discs overlap or not. 
    x = disc1(1:2); rx = disc1(3);
    y = disc2(1:2); ry = disc2(3);
    out = (min([norm(x - y), ...
        norm(x - y + [1,0]), ...
        norm(x - y - [1,0]), ...
        norm(x - y + [0,1]), ...
        norm(x - y - [0,1]), ...
        norm(x - y + [1,1]), ...
        norm(x - y - [1,1]), ...
        norm(x - y + [-1,1]), ...
        norm(x - y - [-1,1])]) < rx + ry ); 
end

function out = JJHarrison_not_overlap(disc,discs_keep)
    %Same as the not_overlap() given in the competition details. 
    x = disc(1:2); rx = disc(3);
    out = 1;
    for i=1:size(discs_keep,1)
        y = discs_keep(i,1:2);
        ry = discs_keep(i,3);
        out = out*(min([norm(x - y), ...
            norm(x - y + [1,0]), ...
            norm(x - y - [1,0]), ...
            norm(x - y + [0,1]), ...
            norm(x - y - [0,1]), ...
            norm(x - y + [1,1]), ...
            norm(x - y - [1,1]), ...
            norm(x - y + [-1,1]), ...
            norm(x - y - [-1,1])]) > rx + ry ); 
    end
end



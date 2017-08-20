% See generate_intersections_range_runpar.m.
function intersection_matrix = generate_intersections_range(discs,lower,upper)
    N = size(discs,1);
    intersection_matrix = sparse(0,N); %Start with an empty sparse matrix
    k=1;
    for i=lower:upper
        %Iterate through each circle, find the intersecting circles and add each
        %intersection as a row in A. Takes o(N^2) iterations since finding the 
        % overlap is currently O(N) time and we do it for each row.
        % This would be a lot faster with a quadtree implentation or similar.
        overlap_ind = get_overlap_ind_fast(discs(i,:),discs);
        %overlap_ind_new = get_overlap_ind_fast(discs(i,:),discs) %O(N)
        for j=1:size(overlap_ind,2) %O(N)
            %intersection_matrix((N-1)*i+j, i) = 1;
            %intersection_matrix((N-1)*i+j, overlap_ind(j)) = 1;
            intersection_matrix(k, i) = 1;
            intersection_matrix(k, overlap_ind(j)) = 1;
            k = k+1;
        end
    end
end
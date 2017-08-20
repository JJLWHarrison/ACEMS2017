%Given a matrix discs with one disc per row in format x,y,radius and a
%master_disc, this finds the overlapping_discs and their indicies in
%overlap_ind.
function overlap_ind = get_overlap_ind_fast(master_disc,discs)
N = size(discs,1);

overlap_ind = [];

%Iterate on the remaining discs
for i=1:N
    % if not not overlap is poor semantics, but leaving it that way since 
    % not_overlap was already written by the competition providers.
    if not_overlap_fast(master_disc,discs(i,:));
         overlap_ind = [overlap_ind, i];
    end
end
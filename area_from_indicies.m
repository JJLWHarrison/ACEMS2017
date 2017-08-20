function  area = area_from_indicies(discs,indicies)
%Compute the area. Double counts overlapping area!
area = 0;
for i=1:size(indicies,1)
    area = area + pi*discs(indicies(i),3)^2;
end
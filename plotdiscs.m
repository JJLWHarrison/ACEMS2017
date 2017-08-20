% This plots a solution. The code was provided at
% https://people.smp.uq.edu.au/RadislavVaisman/ACEMS2017/
% Works well inconjunction with readcsv.
% E.g. plotdiscs(readcsv('sol_for_200.1_0.463385.csv'));

function  plotdiscs(discs)
%discs: Nx3 matrix of centres of the discs and radius
centres = discs(:,1:2);
R = discs(:,3);
N = size(centres,1);
figure(), clf
col = [0.8 0.8 0.8];
hold on
for i=1:N
filledCircle(centres(i,:),R(i),100,col);
if abs(centres(i,1) - 1)< R(i)
    filledCircle(centres(i,:) - [1,0],R(i),100,col);
end
if abs(centres(i,2) - 1)< R(i)
    filledCircle(centres(i,:) - [0,1],R(i),100,col);
end
if centres(i,1)< R(i)
    filledCircle(centres(i,:) + [1,0],R(i),100,col);
end
if centres(i,2)< R(i)
    filledCircle(centres(i,:) + [0,1],R(i),100,col);
end
end
plot(centres(:,1),centres(:,2),'.', 'MarkerEdgeColor',[0 0 0],...
    'MarkerSize',16);
xlim([0,1])
ylim([0,1])
box('on');
hold off
daspect([1 1 1])
set(gca,'Xtick',[],'Ytick',[]);
end


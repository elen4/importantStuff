function approachDir=computeApproachDirection (times1, trajectory1, times2, trajectory2, minDistance)
% Compute relative position of trajectory1 w.r.t to trajectory2 when the
% two are closest
if isempty(times1) || isempty(times2)
    approachDir= '';
else
    trajectory2interp=interp1(times2, trajectory2, times1);

    distance2=sqrt(sum((trajectory1-trajectory2interp).^2, 2));
    distance2(distance2<minDistance)=minDistance;
    
    [C, I]=min(distance2); %I is the index in times1 at which trajectories get closest

    % % Uncomment this to see a plot of the two trajectories for each trial
    %plot(times1, trajectory1, times2, trajectory2, times1, distance2, 'k', times1(I), C, 'kd');
    %legend('tooltip x', 'tooltip y', 'tooltip z', 'object x', 'object y', 'object z', 'distance', 'minpoint')
    %pause;
    
    approachDir=computeMovementDirection(trajectory2interp(I, :), trajectory1(I,:));
end
function direction=computeMovementDirection(positionBefore, positionAfter, threshold)
% For iCub "root" frame of reference: X is pointing backwards, Y is
% pointing rightwards, Z (ignored) is pointing upwards
% should add check on input arguments direction

if nargin <3
    threshold =0.0;
end

threshold=abs(threshold);

differencePositions=positionAfter-positionBefore;
direction='';
if differencePositions(1) < -threshold
    direction= 'away';
elseif differencePositions(1) > threshold
    direction= 'closer';
end

if differencePositions(2) < -threshold
    direction= [direction ' left'];
elseif differencePositions(2) > threshold
        direction= [direction ' right'];
end

if differencePositions(3) < -threshold  %for generality, but for current experiments this should always be 0
    direction= [direction ' down'];
elseif differencePositions(3) > threshold
        direction= [direction ' up'];
end

if isempty(direction)
    direction = 'still';
end
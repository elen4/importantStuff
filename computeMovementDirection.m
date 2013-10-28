function direction=computeMovementDirection(positionBefore, positionAfter)
% For iCub "root" frame of reference: X is pointing backwards, Y is
% pointing rightwards, Z (ignored) is pointing upwards
differencePositions=positionAfter-positionBefore;
direction='';
if differencePositions(1) < 0.0
    direction= 'away';
elseif differencePositions(1) >0.0
    direction= 'closer';
end

if differencePositions(2) < 0.0
    direction= [direction ' left'];
elseif differencePositions(2) >0.0
        direction= [direction ' right'];
end

if differencePositions(3) < 0.0  %for generality, but for current experiments this should always be 0
    direction= [direction ' down'];
elseif differencePositions(3) >0.0
        direction= [direction ' up'];
end
%% read files
fld=dir([basedir '/dumpLeftWrench_*']);
leftWrenchData=importdata([basedir '/' fld(1).name '/data.log']);
fld=dir([basedir '/dumpLeftEEFVel_*']);
leftEEFvelData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/dumpLeftEEF_*']);
leftEEFData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/dumpRightWrench_*']);
rightWrenchData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/dumpRightEEFVel_*']);
rightEEFvelData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/dumpRightEEF_*']);
rightEEFData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/dumpTarget3d_*']);
target3dData=importdata([basedir '/' fld(1).name  '/data.log']);
fld=dir([basedir '/humanOpDump_*']);
humanInteraction=importdata([basedir '/' fld(1).name  '/data.log']);


%% extract time instants at which commands are sent
nCmds=size(humanInteraction,1);
cmdTimes=zeros(nCmds,1);
cmds=cell(nCmds,1);
for i=1:nCmds
    tmp= regexp (humanInteraction{i}, ' ', 'split');
    cmdTimes(i)=str2double(tmp{2});
    tmpCmd=tmp(1,4);
    
    if strcmp(tmpCmd, '(grasp')
      tool = tmp{1, 5};
      toolDimsString=tmp(1, 7:9);
      toolDims(1)=str2double(toolDimsString{1});
      toolDims(2)=str2double(toolDimsString{2});
      toolDims(3)=str2double(toolDimsString{3}(1:end-1));
      hand=tmp{1,6};
      cmds{i,1}='grasp';
      cmds{i,2}.tool=tool;
      cmds{i,2}.toolDims=toolDims;
      cmds{i,2}.hand=hand;
    end
    
        
    if strcmp(tmpCmd, '(push')
      cmds{i,1}='push';
      cmds{i,2}.tool=tool;
      cmds{i,2}.object=tmp{1,5};
      cmds{i,2}.toolDims=toolDims;
      cmds{i,2}.hand=hand;
    end
    
    if strcmp(tmpCmd, '(draw')
      cmds{i,1}='pull';
      cmds{i,2}.tool=tool;
      cmds{i,2}.object=tmp{1,5};
      cmds{i,2}.toolDims=toolDims;
      cmds{i,2}.hand=hand;
    end
    
        
    if strcmp(tmpCmd, '(ack)')
      cmds{i,1}='ack';
    end
    
    
end

%% for push/pull commands, find list of start-end couples
foundPush=strfind(humanInteraction, 'push');
foundPushIndices=find(~cellfun('isempty',foundPush));
startTimesPush= cmdTimes(foundPushIndices);
endTimesPush=cmdTimes(1+foundPushIndices); %sort of hack - the "ack" that signals action ending is always after the command

foundPull=strfind(humanInteraction, 'draw');
foundPullIndices=find(~cellfun('isempty',foundPull));
startTimesPull= cmdTimes(foundPullIndices);
endTimesPull=cmdTimes(1+foundPullIndices); %sort of hack - the "ack" that signals action ending is always after the command

nPushes=length(startTimesPush);
nPulls=length(startTimesPull);

%% extract quantities in files
leftWrench=leftWrenchData(:,9); % norm of forces at left EEF
leftWrenchTimes=leftWrenchData(:,2);

leftEEFvel=sqrt(leftEEFvelData(:,3).^2+leftEEFvelData(:,4).^2+leftEEFvelData(:,5).^2);
leftEEFvelTimes=leftEEFvelData(:,2);

leftEEF=leftEEFData(:,3:9);
leftEEFTimes=leftEEFData(:,2);

rightWrench=rightWrenchData(:,9);
rightWrenchTimes=rightWrenchData(:,2);

rightEEFvel=sqrt(rightEEFvelData(:,3).^2+rightEEFvelData(:,4).^2+rightEEFvelData(:,5).^2);
rightEEFvelTimes=rightEEFvelData(:,2);

rightEEF=rightEEFData(:,3:9);
rightEEFTimes=rightEEFData(:,2);

target3dTimes=target3dData(:,2);
target3dPos=target3dData(:, 3:5);
%temporary for faulty "stick" data:
target3dPos(end, :)=target3dPos(end-1, :);

%% average values for each push or pull action

avgLeftWrench=zeros(nPushes+ nPulls,1);
avgLeftEEFvel=zeros(nPushes+ nPulls,1);
avgRightWrench=zeros(nPushes+ nPulls,1);
avgRightEEFvel=zeros(nPushes+ nPulls,1);
for t_ind=1:nPushes
   avgLeftWrench(t_ind)=mean(leftWrench(leftWrenchTimes>startTimesPush(t_ind) & leftWrenchTimes < endTimesPush(t_ind)));
   avgLeftEEFvel(t_ind)=mean(leftEEFvel(leftEEFvelTimes>startTimesPush(t_ind) & leftEEFvelTimes < endTimesPush(t_ind)));
   avgRightWrench(t_ind)=mean(rightWrench(rightWrenchTimes>startTimesPush(t_ind) & rightWrenchTimes < endTimesPush(t_ind)));
   avgRightEEFvel(t_ind)=mean(rightEEFvel(rightEEFvelTimes>startTimesPush(t_ind) & rightEEFvelTimes < endTimesPush(t_ind)));
end

for t_ind=1:nPulls
   avgLeftWrench(t_ind+nPushes)=mean(leftWrench(leftWrenchTimes>startTimesPull(t_ind) & leftWrenchTimes < endTimesPull(t_ind)));
   avgLeftEEFvel(t_ind+nPushes)=mean(leftEEFvel(leftEEFvelTimes>startTimesPull(t_ind) & leftEEFvelTimes < endTimesPull(t_ind)));
   avgRightWrench(t_ind+nPushes)=mean(rightWrench(rightWrenchTimes>startTimesPull(t_ind) & rightWrenchTimes < endTimesPull(t_ind)));
   avgRightEEFvel(t_ind+nPushes)=mean(rightEEFvel(rightEEFvelTimes>startTimesPull(t_ind) & rightEEFvelTimes < endTimesPull(t_ind)));
end

%% bin into low/medium/high and associate qualities back to action cmd

[nLW,binsLW]=histc(avgLeftWrench, linspace(min(avgLeftWrench), max(avgLeftWrench), 3));  
[nRW,binsRW]=histc(avgRightWrench, linspace(min(avgRightWrench), max(avgRightWrench), 3));
[nLvel,binsLvel]=histc(avgLeftEEFvel, linspace(min(avgLeftEEFvel), max(avgLeftEEFvel), 3));
[nRvel,binsRvel]=histc(avgRightEEFvel, linspace(min(avgRightEEFvel), max(avgRightEEFvel), 3));
 %0: missing data, 1: low, 2:medium, 3:high
qualityMapValues={'', 'low', 'medium', 'high'};
qualityLW=qualityMapValues(binsLW+1);
[actionProperties([foundPushIndices; foundPullIndices]).leftWrench]=deal(qualityLW{:});
qualityRW=qualityMapValues(binsRW+1);
[actionProperties([foundPushIndices; foundPullIndices]).rightWrench]=deal(qualityRW{:});
qualityLvel=qualityMapValues(binsLvel+1);
[actionProperties([foundPushIndices; foundPullIndices]).leftEEFvel]=deal(qualityLvel{:});
qualityRvel=qualityMapValues(binsRvel+1);
[actionProperties([foundPushIndices; foundPullIndices]).rightEEFvel]=deal(qualityRvel{:});

%% compute approach direction
minDistance=0.15;
% filter target 3d position
target3dSamplingStep=target3dTimes(2)-target3dTimes(1);
cutoffFreq=1; %hertz
[b,a]=butter(3,cutoffFreq*(2*target3dSamplingStep));
target3dPosFiltered=filtfilt(b,a, target3dPos);

figure, plot(target3dTimes, target3dPos, target3dTimes, target3dPosFiltered)
pause
for t_ind=1:nPushes
    globalCmdIndex=foundPushIndices(t_ind);
    if strcmp(cmds{globalCmdIndex, 2}.hand,'left')
        timeSegment1=find(leftEEFTimes>startTimesPush(t_ind) & leftEEFTimes < endTimesPush(t_ind));
        tooltipPosition=zeros(length(timeSegment1), 3);
        for action_t_ind=timeSegment1'
            tooltipPosition(action_t_ind, :)=leftEEF(action_t_ind, 1:3)+(vrrotvec2mat(leftEEF(action_t_ind, 4:7))*cmds{globalCmdIndex, 2}.toolDims')';
        end

    else
        % TODO complete
        timeSegment1=find(rightEEFTimes>startTimesPush(t_ind) & rightEEFTimes < endTimesPush(t_ind));
        tooltipPosition=zeros(length(timeSegment1), 3);
        for action_t_ind=timeSegment1'
            tooltipPosition(action_t_ind, :)=rightEEF(action_t_ind, 1:3)+(vrrotvec2mat(rightEEF(action_t_ind, 4:7))*cmds{globalCmdIndex, 2}.toolDims')';
        end

    end
    timeSegment2=find(target3dTimes>startTimesPush(t_ind) & target3dTimes< endTimesPush(t_ind));
    actionProperties(foundPushIndices(t_ind)).approachDirection=computeApproachDirection(leftEEFTimes(timeSegment1), tooltipPosition(timeSegment1,:), target3dTimes(timeSegment2), target3dPosFiltered(timeSegment2, :) , minDistance);

end

for t_ind=1:nPulls
    globalCmdIndex=foundPullIndices(t_ind);
    if strcmp(cmds{globalCmdIndex, 2}.hand,'left')
        timeSegment1=find(leftEEFTimes>startTimesPull(t_ind) & leftEEFTimes < endTimesPull(t_ind));
        tooltipPosition=zeros(length(timeSegment1), 3);
        for action_t_ind=timeSegment1'
            tooltipPosition(action_t_ind, :)=leftEEF(action_t_ind, 1:3)+(vrrotvec2mat(leftEEF(action_t_ind, 4:7))*cmds{globalCmdIndex, 2}.toolDims')';
        end

    else
        % TODO complete
        timeSegment1=find(rightEEFTimes>startTimesPull(t_ind) & rightEEFTimes < endTimesPull(t_ind));
        tooltipPosition=zeros(length(timeSegment1), 3);
        for action_t_ind=timeSegment1'
            tooltipPosition(action_t_ind, :)=rightEEF(action_t_ind, 1:3)+(vrrotvec2mat(rightEEF(action_t_ind, 4:7))*cmds{globalCmdIndex, 2}.toolDims')';
        end

    end
    timeSegment2=find(target3dTimes>startTimesPull(t_ind) & target3dTimes< endTimesPull(t_ind));
    actionProperties(foundPullIndices(t_ind)).approachDirection=computeApproachDirection(leftEEFTimes(timeSegment1), tooltipPosition(timeSegment1,:), target3dTimes(timeSegment2), target3dPosFiltered(timeSegment2, :), minDistance );

end

%% Print to file

[pathstr,name]=fileparts(basedir);
fName = [name '.txt'];         %# A file name
fid = fopen(fName,'w');            %# Open the file
if fid ~= -1    
    for i=1:nCmds
        
        if strcmp(cmds{i,1}, 'grasp')
            fprintf(fid,'(grasp %s)\n',cmds{i,2}.tool);
        end
        
        
        if strcmp(cmds{i,1}, 'push')
            fprintf(fid,'(push %s %s) ',cmds{i,2}.tool, cmds{i,2}.object);
            
            fprintf(fid,'(leftForce %s) ',actionProperties(i).leftWrench);
            fprintf(fid,'(leftVelocity %s) ',actionProperties(i).leftEEFvel);
            fprintf(fid,'(rightForce %s) ',actionProperties(i).rightWrench);
            fprintf(fid,'(rightVelocity %s) ',actionProperties(i).rightEEFvel);
            fprintf(fid,'(approachDirection %s)\n',actionProperties(i).approachDirection);
            
        end
        
        if strcmp(cmds{i,1}, 'pull')
            fprintf(fid,'(pull %s %s)',cmds{i,2}.tool, cmds{i,2}.object);
               
            fprintf(fid,'(leftForce %s) ',actionProperties(i).leftWrench);
            fprintf(fid,'(leftVelocity %s) ',actionProperties(i).leftEEFvel);
            fprintf(fid,'(rightForce %s) ',actionProperties(i).rightWrench);
            fprintf(fid,'(rightVelocity %s) ',actionProperties(i).rightEEFvel);
            fprintf(fid,'(approachDirection %s)\n',actionProperties(i).approachDirection);
        end
        
        
        if strcmp(cmds{i,1}, 'ack')
            [dummy,timeBefore]=min(abs(target3dTimes - cmdTimes(i-1)));
            [dummy,timeAfter]=min(abs(target3dTimes - cmdTimes(i)));
            fprintf(fid,'(targetPosition %s)\n', computeMovementDirection(target3dPosFiltered(timeBefore, :), target3dPosFiltered(timeAfter, :), 0.01));
        end
        
        
    end
    fclose(fid);                     %# Close the file
end

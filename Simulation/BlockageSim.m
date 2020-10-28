function [output, blockage_events] = BlockageSim(s_mobility,BS_input)
% Written by Mustafa F Ozkoc, Athanasios Koutsaftis, Rajeev Kumar
% Based on Ish Jain's Script
% NYU Tandon School of Engineering
% Date: May 2020
%
% Input:
%   s_mobility: contains parameters corresponding to blockers mobility
%   BS_input: contains infromation related to BS-UE topology and simulation
%   parameters. See SimulationLOS.m for the usage.
% Description:
% We use random way point mobility model for the blockers. The UE is at the
% origin and the BSs are located in a circle around the UE. A random
% blocker will block the BS-UE LOS path is it crosses the line joining
% between BS and the UE. We use find_blockage_distance.m function to fine
% intersection of two such lines. Finally, we repeat the process for all
% the blockers, for all the BSs and for the whole simulation duration. 



%----Play-with-values-here--------------------------------------
nB = BS_input.NUM_BL; %number of blokers
rT =BS_input.LOC_AP_DISTANCE; %location of APs
alphaTorig = BS_input.LOC_AP_ANGLE;%location of APs

frac = BS_input.FRACTION;
omega = BS_input.SELF_BL_ANGLE_OMEGA;

%%Implementing self-blockage
tempInd =  find(alphaTorig>=omega); %These BSs are not blocked by self-blockage
xT = rT(tempInd).*cos(alphaTorig(tempInd));%location of APs (distance)
yT = rT(tempInd).*sin(alphaTorig(tempInd));%location of APs (angle)
nT = length(tempInd); % number of BS not blocked by self-blockage
% nT=0
if(nT==0)
    output=[0,0,0];
    disp('Zero AP in the coverage region')
    return;
end % Dealing zero APs

xTfrac = frac*xT; %blockage zone around UE for each APs
yTfrac = frac*yT;
locT = [xTfrac';yTfrac']; %2 rows for x and y, nT columns
alphaT = alphaTorig(tempInd); %angle from x-axis for BS not blocked by self-bl
simTime = BS_input.SIMULATION_TIME; %sec Total Simulation time
mu = BS_input.MU; %Expected bloc dur =1/mu
conDegree = BS_input.DEGREE_CONNECTIVITY;


dataBS = cell(nT,1);

for indB = 1:nB %for every blocker
    
    for iter =1:(length(s_mobility.VS_NODE(indB).V_POSITION_X)-1)
        
        % for every time blocker changes direction
        loc0 = [s_mobility.VS_NODE(indB).V_POSITION_X(iter);...
            s_mobility.VS_NODE(indB).V_POSITION_Y(iter)];
        loc1 = [s_mobility.VS_NODE(indB).V_POSITION_X(iter+1);...
            s_mobility.VS_NODE(indB).V_POSITION_Y(iter+1)];
        start_time = s_mobility.VS_NODE(indB).V_TIME(iter);
        velocity = sqrt((s_mobility.VS_NODE(indB).V_SPEED_X(iter))^2+ ...
            (s_mobility.VS_NODE(indB).V_SPEED_Y(iter))^2);
        for indT = 1:nT %for every BS around the UE (outside self-bl zone)
            %The find_blockage_distance() function is written by Ish Jain
            distance_travelled = find_blockage_distance([loc0,loc1],locT(:,indT),alphaT(indT));
            timeToBl = distance_travelled/velocity; %time to blocking event
            timestampBl = start_time+timeToBl; %timestamp of blockage event
            if(distance_travelled>=0 && timestampBl<=simTime)
                %                 data{indB,indT} = [data{indB,indT},start_time+blockage_time];
                dataBS{indT} = [dataBS{indT}, timestampBl];
                
            end
            
        end
        
    end
end


for i=1:nT
    dataBS{i} = sort(dataBS{i});
end



if conDegree > nT
    conDegree = nT;
end

for indT = 1:nT
    len =length(dataBS{indT});
    dataBS{indT}(2,:) =  exprnd(1/mu,1,len); % block duration
    dataBS{indT}(3,:) = dataBS{indT}(2,:) + dataBS{indT}(1,:); % end of physical blockages\
    %if a blocker arrives before the previous blocker served then that is a
    %one long blockage, for programming purposes we delete the second
    %arrival and make one long combined blockage
    for jj=len:-1:2
        if dataBS{indT}(3,jj-1) >= dataBS{indT}(1,jj)
            dataBS{indT}(3,jj-1) = max(dataBS{indT}(3,jj),dataBS{indT}(3,jj-1));
            dataBS{indT}(:,jj) = [];
        end
    end
    
end


discovery_time = BS_input.DISCOVERY_TIME;
preparation_time = BS_input.HO_PREP_TIME;

initial_BS_idx = randperm(nT,conDegree);

output = cell(length(discovery_time),length(preparation_time));
blockage_events = cell(length(discovery_time),length(preparation_time));

for indDisc=1:length(discovery_time)
    dt = discovery_time(indDisc);
    for indPrep = 1:length(preparation_time)
        w = preparation_time(indPrep);
        
        for indT = 1:nT
            len =size(dataBS{indT},2);
            % here we can change exprnd to deterministic for real
            % simulation
            dataBS{indT}(4,:) =  dt*ones(1,len);%exprnd(dt,1,len); % discovery duration
            dataBS{indT}(5,:) = dataBS{indT}(3,:) + dataBS{indT}(4,:); % discovery time\
            %if a blocker arrives before the previous blocker served and the bs is discovered then that is a
            %one long blockage, for programming purposes we delete the second
            %arrival and make one long combined blockage and find the
            %discovery time
            for jj=len:-1:2
                if dataBS{indT}(5,jj-1) >= dataBS{indT}(1,jj)
                    dataBS{indT}(5,jj-1) = max(dataBS{indT}(5,jj),dataBS{indT}(5,jj-1));
                    dataBS{indT}(:,jj) = [];
                end
            end
            
        end
        current_time=0;
        
        for indT = nT:-1:1
            base_stations(indT) = BaseStation(current_time,dataBS{indT},indT);
        end
        
        
        for idxAnt = length(initial_BS_idx):-1:1
            antenna_elements(idxAnt) = AntennaElement(base_stations(initial_BS_idx(idxAnt)),w,current_time);
        end
        
        durationConnected = 0;
        durationBlocked = 0;
        
        prev_time = 0;
        next_event_time = min([antenna_elements.next_event_time]);
        
        state = 0;
        last_state_change = 0;
        blockage_duration = [];
        
        while next_event_time < simTime
            isConnected = sum([antenna_elements.isConnected]);
            if isConnected > 0
                if state == 1
                    state = 0;
                    blockage_ended = prev_time;
                    blockage_duration = [blockage_duration , blockage_ended-blockage_started];
                    last_state_change = prev_time;
                end
                durationConnected = durationConnected + next_event_time - prev_time;
            else
                if state == 0
                    state = 1;
                    last_state_change = prev_time;
                    blockage_started = last_state_change;
                end
                durationBlocked = durationBlocked + next_event_time - prev_time;
            end
            % Update BS Times
            base_stations = base_stations.advTime(next_event_time);
            % Update Antenna Times
            antenna_elements = antenna_elements.advTime(next_event_time,base_stations);
            prev_time = next_event_time;
            next_event_time = min([antenna_elements.next_event_time]);
            if prev_time >= next_event_time
                disp('Something Wrong infinite loop')
            end
        end
        
        isConnected = sum([antenna_elements.isConnected]);
        if isConnected > 0
            durationConnected = durationConnected + simTime - prev_time;
            if state == 1
                    state = 0;
                    blockage_ended = prev_time;
                    blockage_duration = [blockage_duration , blockage_ended-blockage_started];
            end
        else
            if state == 1
                blockage_duration = [blockage_duration , simTime-blockage_started];
            end
            if state == 0
                blockage_duration = [blockage_duration , simTime - prev_time];
            end
            durationBlocked = durationBlocked + simTime - prev_time;
        end
        
        
        total_blockage_duration_by_ind_blockages = sum(blockage_duration);
        if abs(durationBlocked - total_blockage_duration_by_ind_blockages) < 1e-6
%             disp('Equal')
        else
            disp('There might be a problem, not equal')
            disp('Difference = ')
            disp(durationBlocked-total_blockage_duration_by_ind_blockages)
        end
        
        probBl = durationBlocked / (durationBlocked + durationConnected);
        output{indDisc,indPrep} = probBl;
        blockage_events{indDisc,indPrep} = blockage_duration;
    end
end

output = cell2mat(output);
end

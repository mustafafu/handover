classdef AntennaElement
% Written by Mustafa F Ozkoc, Athanasios Koutsaftis, Rajeev Kumar
% Based on Ish Jain's Script
% NYU Tandon School of Engineering
% Date: May 2020
%
% Description:
% Antenna element object handling discovery, connection establishment etc.
    properties
        current_time = -1;
        next_event_time = -1;
        isConnected = -1;
        isEstablishing = -1;
        isIdle = -1;
        Connected_BS = [];
        Connected_BS_idx = 0;
        targetBS = [];
        target_BS_idx = -1;
        wait_time = 30/1000;
        state = -1;
        %1-> connected BS gets blocked, either initate connection move to
        % state 2 or wait for bs to become available move to state 3,
        % 2-> connection time passed addition if BS still available  else
        % go back to state 2 or 3
        %3-> BS become available
    end
    methods
        function obj = AntennaElement(BaseStation,waiting_time,current_time)
            if nargin ~= 0
                obj.current_time=current_time;
                obj.Connected_BS = BaseStation;
                obj.Connected_BS_idx = BaseStation.index;
                obj.wait_time = waiting_time;
                obj.next_event_time = BaseStation.nextBlockageArrival(obj.current_time);
                if ~isempty(obj.Connected_BS)
                    obj.isConnected = 1;
                    obj.isEstablishing = 0;
                    obj.isIdle = 0;
                    obj.state = 1;
                else
                    obj.isConnected = 0;
                    disp('something wrong in initialization of antenna element')
                end
            end
        end
        function obj = advTime(obj,next_time,base_stations)
            num_object = length(obj);
            for ii=1:num_object
                if next_time == obj(ii).next_event_time
                    %The event is for this antenna element
                    % either the BS it was connected gets blocked
                    % or it will try to establish a connection
                    %update the time
                    obj(ii).current_time = next_time;
                    %update properties of your connected BS.
                    if isempty(obj(ii).Connected_BS)
                        % no need to update BS
                    else
                        obj(ii).Connected_BS = base_stations(obj(ii).Connected_BS_idx);
                    end
                    if isempty(obj(ii).targetBS)
                        % no need to update BS
                    else
                        obj(ii).targetBS = base_stations(obj(ii).target_BS_idx);
                    end
                    %if there is a BS connected then this event must be
                    %that bs getting blocked
                    if obj(ii).state == 1
                        obj(ii).Connected_BS = base_stations(obj(ii).Connected_BS_idx);
                        if obj(ii).Connected_BS.isBlocked
                            obj(ii).Connected_BS = [];
                            obj(ii).Connected_BS_idx = -1;
                            obj(ii).isConnected = 0;
                            % Dont check is blocked but check isDiscovered
                            available_BS = find(([base_stations.isDiscovered]==1) );
                            %remove Base stations targeted by other antenna
                            %elements
                            available_BS = setdiff(available_BS,[obj.Connected_BS_idx]);
                            available_BS = setdiff(available_BS,[obj.target_BS_idx]);
                            if ~isempty(available_BS)
                                %Choose a BS
                                next_bs_idx = available_BS(randi(length(available_BS),1));
                                obj(ii).state = 2;
                                obj(ii).isConnected = 0;
                                obj(ii).isEstablishing = 1;
                                obj(ii).isIdle = 0;
                                obj(ii).targetBS = base_stations(next_bs_idx);
                                obj(ii).target_BS_idx = next_bs_idx;
                                obj(ii).next_event_time = obj(ii).current_time + obj(ii).wait_time;% exprnd(obj(ii).wait_time,1);
                            else
                                obj(ii).state = 3;
                                obj(ii).targetBS = [];
                                obj(ii).target_BS_idx = 0;
                                obj(ii).isConnected = 0;
                                obj(ii).isEstablishing = 0;
                                obj(ii).isIdle = 1;
                                % find out when a bs will be available
                                obj(ii).next_event_time = min([base_stations([base_stations.isDiscovered]==0).nextAvailableTime]);
                            end
                        else
                            disp('Something is wrong event is for this antenna element, it has an active BS but the event is not a blocker arrival for that BS')
                        end
                        % if there was not a bs connected then this antenna
                        % element either finished wait time and will try to
                        % connect a new available base station
                        % ot it has to wait until a base station becomes
                        % available.
                    elseif obj(ii).state == 2
                        %make sure noone connected to that target BS
                        available_BS = setdiff(obj(ii).target_BS_idx,[obj.Connected_BS_idx]);
                        %check if the target BS is still discovered
                        isTarget_Discovered = obj(ii).targetBS.isDiscovered;
                        % if everything is all right
                        if isTarget_Discovered && ~isempty(available_BS)
                            obj(ii).Connected_BS = obj(ii).targetBS;
                            obj(ii).targetBS = [];
                            obj(ii).Connected_BS_idx = obj(ii).target_BS_idx;
                            obj(ii).target_BS_idx = 0;
                            obj(ii).state = 1;
                            obj(ii).isConnected = 1;
                            obj(ii).isEstablishing = 0;
                            obj(ii).isIdle = 0;
                            % next event time is the next blockage of this bs
                            obj(ii).next_event_time =  obj(ii).Connected_BS.nextBlockageArrival(obj(ii).current_time);
                        else %find a new target
                            % Dont check is blocked but check isDiscovered
                            available_BS = find(([base_stations.isDiscovered]==1));
                            %remove Base stations targeted by other antenna
                            %elements
                            available_BS = setdiff(available_BS,[obj.Connected_BS_idx]);
                            available_BS = setdiff(available_BS,[obj.target_BS_idx]);
                            if ~isempty(available_BS)
                                %Choose a BS
                                next_bs_idx = available_BS(randi(length(available_BS),1));
                                obj(ii).state = 2;
                                obj(ii).isConnected = 0;
                                obj(ii).isEstablishing = 1;
                                obj(ii).isIdle = 0;
                                obj(ii).targetBS = base_stations(next_bs_idx);
                                obj(ii).target_BS_idx = next_bs_idx;
                                obj(ii).next_event_time = obj(ii).current_time + obj(ii).wait_time;%exprnd(obj(ii).wait_time,1);
                            else
                                obj(ii).state = 3;
                                obj(ii).targetBS = [];
                                obj(ii).target_BS_idx = 0;
                                obj(ii).isConnected = 0;
                                obj(ii).isEstablishing = 0;
                                obj(ii).isIdle = 1;
                                % find out when a bs will be available
                                obj(ii).next_event_time = min([base_stations([base_stations.isDiscovered]==0).nextAvailableTime]);
                            end
                        end
                    elseif obj(ii).state == 3
                        % Dont check is blocked but check isDiscovered
                        available_BS = find(([base_stations.isDiscovered]==1));
                        %remove Base stations targeted by other antenna
                        %elements
                        available_BS = setdiff(available_BS,[obj.Connected_BS_idx]);
                        available_BS = setdiff(available_BS,[obj.target_BS_idx]);
                        if ~isempty(available_BS)
                            %Choose a BS
                            next_bs_idx = available_BS(randi(length(available_BS),1));
                            obj(ii).state = 2;
                            obj(ii).isConnected = 0;
                            obj(ii).isEstablishing = 1;
                            obj(ii).isIdle = 0;
                            obj(ii).targetBS = base_stations(next_bs_idx);
                            obj(ii).target_BS_idx = next_bs_idx;
                            obj(ii).next_event_time = obj(ii).current_time + obj(ii).wait_time;% exprnd(obj(ii).wait_time,1);
                        else
                            obj(ii).state = 3;
                            obj(ii).targetBS = [];
                            obj(ii).target_BS_idx = 0;
                            obj(ii).isConnected = 0;
                            obj(ii).isEstablishing = 0;
                            obj(ii).isIdle = 1;
                            % find out when a bs will be available
                            obj(ii).next_event_time = min([base_stations([base_stations.isDiscovered]==0).nextAvailableTime]);
                        end
                    else
                        disp('Antenna element is not in a defined state something is wrong')
                    end
                else
                    %The event is not about this antenna element continue
                    %your life as it is
                    %update your time
                    obj(ii).current_time = next_time;
                    %update properties of your connected BS.
                    if isempty(obj(ii).Connected_BS)
                        % no need to update BS
                    else
                        obj(ii).Connected_BS = base_stations(obj(ii).Connected_BS_idx);
                    end
                    if isempty(obj(ii).targetBS)
                        % no need to update BS
                    else
                        obj(ii).targetBS = base_stations(obj(ii).target_BS_idx);
                    end
                end
            end
        end
    end
end
classdef BaseStation
% Written by Mustafa F Ozkoc, Athanasios Koutsaftis, Rajeev Kumar
% Based on Ish Jain's Script
% NYU Tandon School of Engineering
% Date: May 2020
%
% Description:
% Base station object handling discovery, connection establishment etc.

    properties
        current_time = -1;
        index = -1;
        isBlocked = -1;
        isDiscovered = -1;
        blockage_arrivals = [];
        blockage_departures = [];
        nextAvailableTime = -1;
    end
    methods
        function obj = BaseStation(current_time,blockages,index)
            if nargin ~= 0
                obj.current_time=current_time;
                obj.index = index;
                obj.blockage_arrivals=blockages(1,:);
                obj.blockage_departures=blockages(5,:);
                obj.isBlocked = 0;
                obj.isDiscovered = 1;
            end
        end
        function obj = advTime(obj,next_time)
            num_object = length(obj);
            for ii=1:num_object
                obj(ii).current_time=next_time;
                num_arrivals = sum(obj(ii).blockage_arrivals<=obj(ii).current_time);
                num_departures = sum(obj(ii).blockage_departures<=obj(ii).current_time);
                if (num_arrivals - num_departures) == 0
                    obj(ii).isBlocked = 0;
                    obj(ii).isDiscovered = 1;
                else
                    obj(ii).isBlocked = 1;
                    obj(ii).isDiscovered = 0;
                    obj(ii).nextAvailableTime = min(obj(ii).blockage_departures(obj(ii).blockage_departures>obj(ii).current_time));
                end
            end
        end
        function nextBlockageArrival = nextBlockageArrival(obj,this_time)
            nextBlockageArrival = obj.blockage_arrivals(find(obj.blockage_arrivals>this_time,1));
        end
    end
end
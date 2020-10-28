classdef State
    properties
        left = 0;
        right = 0;
        M = 0;
        K = 0;
        index = 0;
        incoming = [];
        incoming_idx = [];
        outgoing = [];
        outgoing_idx = [];
    end
    methods
        function obj = State(left,right,index,M,K)
            if nargin ~= 0
                obj.M = M;
                obj.K = K;
                obj.index = index;
                obj.left = left;
                obj.right = right;
            end
        end
        function [sl,sr] = get_left_right(obj)
            sl = obj.left;
            sr = obj.right;
        end
    end
end
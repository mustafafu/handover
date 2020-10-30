% Written by Mustafa F Ozkoc, Athanasios Koutsaftis, Rajeev Kumar
% Based on Ish Jain's Script
% NYU Tandon School of Engineering
% Date: May 2020
%
% Description:
% First we get the blocker mobility using Generate_Mobility.m function.
% Then for different BS Densities, blocker densities and self-blockage
% angle, we call BlockageSimFn.m function to get key blockage metrics like
% blockage duration, frequency, and blockage. We should run this code for
% many iterations prefebly on high performance computing machine.

close all;
clear;

%----Play-with-values---------------------------------------
aID = getenv('SLURM_ARRAY_TASK_ID')
if(isempty(aID))
  warning('aID is empty. Replacing it with 1.')  
  aID = '2'; %Runs only for first value of AP density when aID=1
end
rng(str2double(aID),'twister');


V = 1; %velocity of blocker m/s
hb = 1.8; %height blocker
hr = 1.4; %height receiver (UE)
ht = 5; %height transmitter (BS)
frac = (hb-hr)/(ht-hr);
simTime = 4*60*60; %sec Total Simulation time should be more than 100.
mu = 2; %Expected bloc dur =1/mu sec
R = 56; %coverage range, 100,56,23

discovery = [20 50 200]*10^(-3);
preparation = [10 20 50]*10^(-3);
densityBS = [500 750 1000]*10^(-6);
connectivity = [1 2 3 4];
densityBL = [0.01 0.1];


PARAMS = struct('COVERAGERANGE',R,...
    'DISCOVERY',discovery,...
    'PREPARATION',preparation,...
    'DENSITYBS',densityBS,...
    'CONNECTIVITY',connectivity,...
    'DENSITYBL',densityBL);



nTorig = densityBS*pi*R^2;
omega = pi/3;

s_input = cell(1,2); 
s_mobility = cell(1,2);

for indB=1:length(densityBL)
s_input{indB} = struct('V_POSITION_X_INTERVAL',[-R R],...%(m)
    'V_POSITION_Y_INTERVAL',[-R R],...%(m)
    'V_SPEED_INTERVAL',[V V],...%(m/s)
    'V_PAUSE_INTERVAL',[0 0],...%pause time (s)
    'V_WALK_INTERVAL',[1.00 60.00],...%walk time (s)
    'V_DIRECTION_INTERVAL',[-180 180],...%(degrees)
    'SIMULATION_TIME',simTime,...%(s)
    'NB_NODES',4*R^2*densityBL(indB));

% Generate_Mobility function is Copyright (c) 2011, Mathieu Boutin
s_mobility{indB} = Generate_Mobility(s_input{indB});
end
 finaldata = zeros(length(discovery),length(preparation),length(densityBS),length(connectivity),length(densityBL));
 blockageDurations = cell(length(densityBS),length(connectivity),length(densityBL));

for indBS = 1:length(densityBS)
    tempInd =[];
    while size(tempInd,1) < 1
        nT = poissrnd(densityBS(indBS)*pi*R^2);
        %nT = floor(densityBS(indBS)*pi*R^2);
        rT = R*sqrt(rand(nT,1));%2*R/3 * ones(nT,1); %location of APs (distance from origin)
        alphaT = 2*pi*rand(nT,1);%location of APs (angle from x-axis)
        tempInd =  find(alphaT>=omega);
    end
    BS_pos_stat = [rT,alphaT];
    for indT = 1:length(connectivity)
        currConnec = connectivity(indT);
        for indB = 1:length(densityBL) %for all blockers
            rhoB = densityBL(indB);%0.65;%Rajeev calculated central park
            nB = 4*R^2*rhoB;%=4000; %number of blokers
            tic
            BS_input = struct('DEGREE_CONNECTIVITY', currConnec,...
                'RADIUS_AROUND_UE',R,...
                'SIMULATION_TIME',simTime,...
                'MU',mu,...
                'FRACTION',frac,...
                'SELF_BL_ANGLE_OMEGA',omega,...
                'Original_NUM_AP',nT,...
                'LOC_AP_DISTANCE', rT,... 
                'LOC_AP_ANGLE',alphaT,...
                'NUM_BL',nB,...
                'DISCOVERY_TIME',discovery,...
                'HO_PREP_TIME',preparation,...
                'BS_DENSITY',densityBS(indBS)*10^6,...
                'BL_Density',densityBL(indB)*100,...
                'ITR',aID);

                %BlockageSimFn function is written by Ish Jain
                [output, blockage_events] = BlockageSim(s_mobility{indB},BS_input);
                toc
                finaldata(:,:,indBS,indT,indB) = output;
                blockageDurations{indBS,indT,indB} = blockage_events;
        end
   end
end

savefolder = strcat('data/Coverage',num2str(R),'m')
if ~exist(savefolder, 'dir')
       mkdir(savefolder)
end

save(strcat('data/Coverage',num2str(R),'m/output_2','_',num2str(aID),'.mat'),'finaldata','PARAMS')
save(strcat('data/Coverage',num2str(R),'m/blockages_2','_',num2str(aID),'.mat'),'blockageDurations','PARAMS')

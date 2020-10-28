clear;

clear;

V = 1; %velocity of blocker m/s
hb = 1.8; %height blocker
hr = 1.4; %height receiver (UE)
ht = 5; %height transmitter (BS)
frac = (hb-hr)/(ht-hr);
mu = 2; %Expected bloc dur =1/mu sec
u = mu;
R = 100; %m Radius
lambda_B = [0.01 0.1]; % blocker density
C = 2*V.*lambda_B*frac/pi;


lambda_BS =[200,300,400,500]*10^(-6); %densityBS
density_limits = [30,40,50,60,70];      % up to how many BS in coverage area, it will be ok since poisson distr.
K_list = [1,2,3,4];                      % Degree of Connectivity
w_list = 1000./[10,20,50]; %1000./[10,15,25,30,70,200,1000];      %Connection establishment times
dt_list = 1000./[1,5,20,100,200,1000,2000];   %Discovery Times
a_list = C.*2*R/3;                       %Blocker Arrivals
self_blockage = 5/6;


P_OS = zeros(length(lambda_BS),length(K_list),length(w_list),length(dt_list),length(a_list));

for indBS=1:length(lambda_BS)
    M_max = density_limits(indBS);
    for M = 1:M_max
        P_M =  exp(-1*lambda_BS(indBS)*self_blockage*pi*R^2) * (lambda_BS(indBS)*self_blockage*pi*R^2)^(M)/factorial(M);
        P_M = P_M / (1-exp(-self_blockage*pi*R^2*lambda_BS(indBS)));
        for indK = 1:length(K_list)
            K = K_list(indK);
            for indW = 1:length(w_list)
                w = w_list(indW);
                for indDt = 1:length(dt_list)
                    dt = dt_list(indDt);
                    u = 1/(1/mu + 1/dt);
                    for indA = 1:length(a_list)
                        a = a_list(indA);
                        index = 0;
                        for idxM = 0:M
                            K_lim = min(K,idxM);
                            for idxK = 0:K_lim
                                index = index+1;
                                %         disp([idxM,idxK])
                                chain_states(index) = State(idxM,idxK,index,M,K);
                            end
                        end
                        num_states = index;
                        
                        % %% Compute state transitions
                        MM = zeros(num_states+1, num_states);
                        % MM(num_states+1,:)=1;
                        for state = chain_states
                            [sl,sr] = state.get_left_right;
                            state_idx = state.index;
                            right_side_state = chain_states(([chain_states.left] == sl-1) & ([chain_states.right] == sr));
                            left_side_state = chain_states(([chain_states.left] == sl+1) & ([chain_states.right] == sr));
                            up_side_state = chain_states(([chain_states.left] == sl) & ([chain_states.right] == sr+1));
                            down_right_side_state = chain_states(([chain_states.left] == sl-1) & ([chain_states.right] == sr-1));
                            
                            if ~isempty(right_side_state)
                                target_idx =  right_side_state.index;
                                MM(target_idx,state_idx) = (sl - sr)*a;
                            end
                            if ~isempty(left_side_state)
                                target_idx =  left_side_state.index;
                                MM(target_idx,state_idx) = (M-sl) * u;
                            end
                            if ~isempty(up_side_state)
                                target_idx =  up_side_state.index;
                                MM(target_idx,state_idx) = min(K-sr,sl-sr) * w;
                            end
                            if ~isempty(down_right_side_state)
                                target_idx =  down_right_side_state.index;
                                MM(target_idx,state_idx) = sr * a;
                            end
                        end
                        
                        for idx = 1:num_states
                            MM(idx,idx) = -1*sum(MM(:,idx));
                        end
                        
                        MM(num_states+1,:) = ones(1,num_states);
                        B = zeros(num_states+1,1);
                        B(num_states+1)=1;
                        X = mldivide(MM,B);
%                         disp(P_M * sum(X([chain_states.right]==0)))
                        P_OS(indBS,indK,indW,indDt,indA) = P_OS(indBS,indK,indW,indDt,indA) + P_M * sum(X([chain_states.right]==0));
%                         P_OS(indBS,indK,indW,indDt,indA) = sum(X([chain_states.right]==0));
                        clearvars chain_states
                    end
                end
            end
        end
    end
end

% string = ['ChangedSB-NoRLF_Numerical-Results'];
% description = 'P_OS is a matrix where first indexing element is for different BS densities, second indexing element is for K connectivity, third indexing is for W the time to initiate handover, fourth indexing is for Dt the time to discover BS, and the fifth indexing is for different blocker densities.';
% 
% save(string,'description','P_OS','lambda_BS','K_list','w_list','dt_list','a_list');
string = ['P_OS_',num2str(R)];
description = 'P_OS is a matrix where first indexing element is for different BS densities, second indexing element is for K connectivity, third indexing is for W the time to initiate handover, fourth indexing is for Dt the time to discover BS, and the fifth indexing is for different blocker densities.';

save(string,'description','P_OS','lambda_BS','K_list','w_list','dt_list','a_list');

% 
% figure()
% BS_idx = 4
% semilogy(K_list,P_OS(BS_idx,:,1,2,2))
% hold on;
% grid on;
% semilogy(K_list,P_OS(BS_idx,:,2,2,2))
% semilogy(K_list,P_OS(BS_idx,:,3,2,2))
% 
% 
% figure()
% linspec={'-x','--+',':*','-.s','-o'};
% wIdx = 1;
% this_w =  1000/w_list(wIdx);
% for K=[1,4]
% for dIdx=1:length(dt_list)
%     t_disc = 1000/dt_list(dIdx);
%     semilogy(lambda_BS*1e6,P_OS(:,K,wIdx,dIdx,2),linspec{dIdx},'DisplayName',['\Delta=',num2str(t_disc),' ms', ', K = ',num2str(K)])
%     hold on
%     grid on
% end
% end
% l=legend;
% ylabel('Out-of-Service Probability')
% xlabel('BS density per km^2')
% title(['THz Range, R=',num2str(R),' m,  \Omega=',num2str(this_w),' ms, High BL Desnity'])


% 
% figure()
% for dIdx=1:length(dt_list)
%     t_disc = 1000/dt_list(dIdx);
%            if t_disc>2
%             continue
%         end
%     for indK = 1:length(K_list)
%         K = K_list(indK);
%         if K == 3 || K==2
%             continue
%         end
%         
%         plot(lambda_BS,P_OS(:,K,1,dIdx),'DisplayName',['\Delta=',num2str(t_disc),' ms', ', K = ',num2str(K)])
%         hold on
%     end
% end
% grid on
% l=legend;
% title('Connectivity, BS Desnity vs OOS in THz range 56m');

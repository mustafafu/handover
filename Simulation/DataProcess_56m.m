R = 56;
outputs = dir(['./data/Coverage',num2str(R),'m/out','*']);
num_files = length(outputs)

discovery = [20 50 200]*10^(-3);% <-for Thz , for mmWave ->[1 5 20 200 1000]*10^(-3);
preparation = [10 20 50]*10^(-3);
densityBL = [0.01 0.1];
densityBS = [500 750 1000]*10^(-6);%higher density for Thz %[200 300 400 500]*10^(-6);
connectivity = [1 2 3 4];

results_array = zeros(length(discovery),length(preparation),length(densityBS),length(connectivity),length(densityBL),num_files);
 

for ii=1:num_files
    ii;
    aa = load([outputs(ii).folder,'/',outputs(ii).name]);
    results_array(:,:,:,:,:,ii) = aa.finaldata;
end

final_results = mean(results_array,6);

save(strcat('finalresults_R',num2str(R),'m-',num2str(num_files),'files.mat'),'final_results','discovery','preparation','densityBL','densityBS','connectivity','results_array')

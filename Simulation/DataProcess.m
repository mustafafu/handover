R = 23;
outputs = dir(['./data/Coverage',num2str(R),'m/out','*']);
num_files = length(outputs)
aa = load([outputs(1).folder,'/',outputs(1).name]);


discovery = aa.PARAMS.DISCOVERY;
preparation = aa.PARAMS.PREPARATION;
densityBL = aa.PARAMS.DENSITYBL;
densityBS = aa.PARAMS.DENSITYBS;
connectivity = aa.PARAMS.CONNECTIVITY;

results_array = zeros(length(discovery),length(preparation),length(densityBS),length(connectivity),length(densityBL),num_files);
 

for ii=1:num_files
    ii;
    aa = load([outputs(ii).folder,'/',outputs(ii).name]);
    results_array(:,:,:,:,:,ii) = aa.finaldata;
end

final_results = mean(results_array,6);

save(strcat('./data/finalresults_R',num2str(R),'m-',num2str(num_files),'files.mat'),'final_results','discovery','preparation','densityBL','densityBS','connectivity','results_array','PARAMS')

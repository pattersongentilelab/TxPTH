% Analyze PTH treatment data

data_path_reg = getpref('TxPTH','pfizerDataPath');
data_path_tx = getpref('TxPTH','TxPthDataPath');

load([data_path_reg '/Pfizer_data013123.mat'])
load([data_path_tx '/prevTxPTH.mat'])

%% Combine 
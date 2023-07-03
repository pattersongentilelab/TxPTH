% Analyze PTH treatment data

% load Pfizer dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/PfizerHAdataJun23.mat'])
pfizer = data;

% load Tx PTH dataset
data_path_tx = getpref('TxPTH','TxPthDataPath');
load([data_path_tx '/TxPTH061323.mat'])
pth_tx = data;

clear data data_path*

%% Combine relevant pfizer and pth_tx datasets

% remove duplicate records in pth_tx dataset (only includes 8 - 17yrs, 
uniqueID = unique(pth_tx.pfizer_id);
for x = 1:length(uniqueID)
    temp = find(pth_tx.pfizer_id==uniqueID(x));
    if length(temp)>1
        temp2 = 1:height(pth_tx); temp2 = temp2(temp2~=temp(1));
        pth_tx = pth_tx(temp2,:);
    end
end

% join with pfizer data
pfizer_short = pfizer(:,[1 6 7 10:12 16:67 87:115 130:153 166:226 244]);
pfizer_short.Properties.VariableNames{'record_id'} = 'pfizer_id';

data = join(pth_tx,pfizer_short,'Keys','pfizer_id');

data.race = reordercats(data.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data.ethnicity = reordercats(data.ethnicity,{'no_hisp','hisp','no_answer','unk'});

clear temp* pfizer* pth_tx uniqueID x
%% Inclusion criteria (run on PTH treatment dataset)


% Preventive pharmacologic therapy started within 4 months of concussion

data.days_post_visit1 = between(data.date_onset,data.firstvisit,'days');
data.days_post_visit1 = split(data.days_post_visit1,'d');
data = data(data.days_post_visit1<120,:);

% Separate those who received treatement within the first 4 months from
% those who did not
data.prev_cat = zeros(height(data),1);
data.prev_cat(data.follow_treat1_dur_cont<120 & (data.follow_treat_cat2___nut_prev==1|data.follow_treat_cat2___rx_prev==1)) = 1;

% Compare demographics and headache features of those who were vs. were not
% started on a preventive medication
mdl_prev_cat = fitglm(data,'prev_cat ~ age + gender + race + ethnicity + p_sev_usual + p_pedmidas_score + fu','Distribution','binomial');

% Compare demographics, treatment group, and headache features of those who
% were lost to follow up
data.fu = zeros(height(data),1);
data.fu(data.follow_return=='Yes') = 1;
mdl_lost = fitglm(data,'fu ~ age + gender + race + ethnicity + p_sev_usual + p_pedmidas_score + prev_cat','Distribution','binomial');

% Follow up at 6 weeks
data.fu_outcome = NaN*ones(height(data),1);
data.fu_outcome(data.follow_ben=='wor') = -1;
data.fu_outcome(data.follow_ben=='non_ben') = 0;
data.fu_outcome(data.follow_ben=='som_ben') = 1;
data.fu_outcome(data.follow_ben=='sig_ben') = 2;

mdl_fu_benefit = fitglm(data,'fu_outcome ~ age + gender + race + ethnicity + p_sev_usual + p_pedmidas_score + prev_cat');

% FOllow up at 1 year

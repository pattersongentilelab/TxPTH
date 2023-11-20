% Analyze PTH acute treatment data

% load Pfizer dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/PfizerHAdataAug23.mat'])

%% Organize pfizer data

% Run ICHD3 diagnostic algorithm and update categories

[ICHD3] = ichd3_Dx(data);

data.pheno = ICHD3.pheno;

data.mig_pheno = zeros(height(data),1);
data.mig_pheno(data.pheno=='migraine'|data.pheno=='chronic_migraine'|data.pheno=='prob_migraine') = 1;
data.cm = zeros(height(data),1);
data.cm(data.pheno=='chronic_migraine') = 1;

data.freq_bad = NaN*ones(height(data),1);
data.freq_bad (data.p_fre_bad=='never') = 1;
data.freq_bad (data.p_fre_bad=='1mo') = 2;
data.freq_bad (data.p_fre_bad=='1to3mo') = 3;
data.freq_bad (data.p_fre_bad=='1wk') = 4;
data.freq_bad (data.p_fre_bad=='2to3wk') = 5;
data.freq_bad (data.p_fre_bad=='3wk') = 6;
data.freq_bad (data.p_fre_bad=='daily') = 7;
data.freq_bad (data.p_fre_bad=='always') = 8;

data.severity_grade = NaN*ones(height(data),1);
data.severity_grade(data.p_sev_overall=='mild') = 1;
data.severity_grade(data.p_sev_overall=='mod') = 2;
data.severity_grade(data.p_sev_overall=='sev') = 3;

% Pedmidas severity grade
data.pedmidas_grade = NaN*ones(height(data),1);
data.pedmidas_grade(data.p_pedmidas_score<=10) = 0;
data.pedmidas_grade(data.p_pedmidas_score>10 & data.p_pedmidas_score<=30) = 1;
data.pedmidas_grade(data.p_pedmidas_score>30 & data.p_pedmidas_score<=50) = 2;
data.pedmidas_grade(data.p_pedmidas_score>50) = 3;

data.race = reordercats(data.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data.ethnicity = reordercats(data.ethnicity,{'no_hisp','hisp','no_answer','unk'});
data.race_white = zeros(height(data),1);
data.race_white(data.race=='white') = 1;
data.race_black = zeros(height(data),1);
data.race_black(data.race=='black') = 1;
data.race_asian = zeros(height(data),1);
data.race_asian(data.race=='asian') = 1;
data.eth_nonHisp = zeros(height(data),1);
data.eth_nonHisp(data.ethnicity=='no_hisp') = 1;
data.eth_Hisp = zeros(height(data),1);
data.eth_Hisp(data.ethnicity=='hisp') = 1;

data.ha_cont = zeros(height(data),1);
data.ha_cont(data.p_current_ha_pattern=='cons_flare'|data.p_current_ha_pattern=='cons_same') = 1;

% include any duration of med overuse
data.med_overuse = zeros(height(data),1);
data.med_overuse(data.p_duration_overuse=='1to3mo'|data.p_duration_overuse=='less_1mo'|data.p_duration_overuse=='3mo_greater') = 1;

% headache program vs. general neurology
data.prov_nm = categorical(data.prov_nm);
data.ha_program = zeros(height(data),1);
data.ha_program(data.prov_nm=='BARMHERZIG, REBECCA'|data.prov_nm=='CHADEHUMBE, MADELINE'|data.prov_nm=='MALAVOLTA, CARRIE  P'|...
    data.prov_nm=='PATTERSON GENTILE, CARLYN A'|data.prov_nm=='STEPHENSON, DONNA'|data.prov_nm=='SZPERKA, CHRISTINA L'|...
    data.prov_nm=='ZIPLOW, JASON'|data.prov_nm=='ANTO, MARISSA'|data.prov_nm=='KUMAR, ISHANI'|data.prov_nm=='YOUNKIN, DONALD'|data.prov_nm=='HADFIELD, JOCELYN H') = 1;


pfizer = data;


%% Combine preventive Tx data
% load Tx PTH dataset
data_path_tx = getpref('TxPTH','TxPthDataPath');
load([data_path_tx '/TxPTH091823.mat'])
pth_tx = data;

clear data


% remove duplicate records in pth_tx dataset (only includes 8 - 17yrs) and those without a pfizer id 
uniqueID = unique(pth_tx.pfizer_id);
for x = 1:length(uniqueID)
    temp = find(pth_tx.pfizer_id==uniqueID(x));
    if length(temp)>1
        temp2 = 1:height(pth_tx); temp2 = temp2(temp2~=temp(1));
        pth_tx = pth_tx(temp2,:);
    end
end

pth_tx = pth_tx(~isnan(pth_tx.pfizer_id),:);

% join with pfizer data
pfizer_short = pfizer;
pfizer_short.Properties.VariableNames{'record_id'} = 'pfizer_id';

data = join(pth_tx,pfizer_short,'Keys','pfizer_id');

clear temp* uniqueID x


% remove variables (columns) with all zeros
masktable = varfun(@(V) isnumeric(V) && ~any(V), data);
data(:,masktable{:,:}) = [];

data.fu = zeros(height(data),1);
data.fu(data.follow_return=='Yes' & data.follow_ben~='unk') = 1;

% days post injury
data.days_post_visit1 = between(data.date_onset,data.firstvisit,'Days');
data.days_post_visit1 = split(data.days_post_visit1,'d');

data.days_post_visit2 = between(data.date_onset,data.follow_return_relevant,'Days');
data.days_post_visit2 = split(data.days_post_visit2,'d');

data.days_visit1to2 = between(data.firstvisit,data.follow_return_relevant,'Days');
data.days_visit1to2 = split(data.days_visit1to2,'d');

data.prior_ha_in_lifetime = reordercats(data.prior_ha_in_lifetime,{'no','sick','epi','cont_epi','cont','mis'});

data.prior_ha = NaN*ones(height(data),1);
data.prior_ha(data.prior_ha_in_lifetime=='no'|data.prior_ha_in_lifetime=='sick') = 0;
data.prior_ha(data.prior_ha_in_lifetime=='epi'|data.prior_ha_in_lifetime=='cont_epi'|data.prior_ha_in_lifetime=='cont') = 1;


% determine season of concussion, first visit, and follow up visit
% winter december - february
% spring march - may
% summer june - august
% fall september - november

data.conc_season = NaN*ones(height(data),1);
conc_month = month(data.date_onset);
data.conc_season(conc_month==12 | conc_month==1 | conc_month==2) = 1;
data.conc_season(conc_month==3 | conc_month==4 | conc_month==5) = 2;
data.conc_season(conc_month==6 | conc_month==7 | conc_month==8) = 3;
data.conc_season(conc_month==9 | conc_month==10 | conc_month==11) = 4;
data.conc_seasonCat = categorical(data.conc_season,[4 1 2 3],{'fall','winter','spring','summer'});

data.visit1_season = NaN*ones(height(data),1);
visit1_month = month(data.firstvisit);
data.visit1_season(visit1_month==12 | visit1_month==1 | visit1_month==2) = 1;
data.visit1_season(visit1_month==3 | visit1_month==4 | visit1_month==5) = 2;
data.visit1_season(visit1_month==6 | visit1_month==7 | visit1_month==8) = 3;
data.visit1_season(visit1_month==9 | visit1_month==10 | visit1_month==11) = 4;
data.visit1_seasonCat = categorical(data.visit1_season,[4 1 2 3],{'fall','winter','spring','summer'});

data.visit2_season = NaN*ones(height(data),1);
visit2_month = month(data.follow_return_relevant);
data.visit2_season(visit2_month==12 | visit2_month==1 | visit2_month==2) = 1;
data.visit2_season(visit2_month==3 | visit2_month==4 | visit2_month==5) = 2;
data.visit2_season(visit2_month==6 | visit2_month==7 | visit2_month==8) = 3;
data.visit2_season(visit2_month==9 | visit2_month==10 | visit2_month==11) = 4;
data.visit2_seasonCat = categorical(data.visit2_season,[4 1 2 3],{'fall','winter','spring','summer'});

% back up functional status
data.pedmidas_gradeBackup = NaN*ones(height(data),1);
data.pedmidas_gradeBackup(data.pres_school___att_good==1) = 0; % attending school, normal grades
data.pedmidas_gradeBackup(data.pres_school___att_down==1) = 2; % attending school, grades down
data.pedmidas_gradeBackup(data.pres_school___att_unk==1) = 0; % attending school, academic performance unknown
data.pedmidas_gradeBackup(data.pres_school___mis_2_less==1) = 1; % missing school 5 days or less per month
data.pedmidas_gradeBackup(data.pres_school___mis_2_great==1) = 2; % missing school 6 days or more per month
data.pedmidas_gradeBackup(data.pres_school___ada==1) = 3; % adapted schedule
data.pedmidas_gradeBackup(data.pres_school___hom_cyb==1) = 3; % Homebound/cyber for medical/prolonged absence

for x = 1:height(data)
    if isnan(data.pedmidas_grade(x)) && ~isnan(data.pedmidas_gradeBackup(x))
        data.pedmidas_grade(x) = data.pedmidas_gradeBackup(x);
    end
end


data.fu_outcome = NaN*ones(height(data),1);
data.fu_outcome(data.follow_ben=='wor') = 1;
data.fu_outcome(data.follow_ben=='non_ben') = 2;
data.fu_outcome(data.follow_ben=='som_ben') = 3;
data.fu_outcome(data.follow_ben=='sig_ben') = 4;

% get rid of identifying variables
data = removevars(data,{'record_id','pfizer_id','firstvisit','date_onset','follow_return_relevant',...
    'follow_duration_pfmom','follow_duration_pfday','follow_duration_pfwk','follow_treat1_date',...
    'follow_treat2_date','follow_treat3_date','follow_treat4_date','follow_treat5_date','visit_dt',...
    'prov_nm','clin_loc','locator_nm','street_long_deg_x','street_lat_deg_y','p_epi_conc_date',...
    'p_con_start_date','p_prim_care_occ','c_epi_conc_date','c_con_conc_date'});

save([data_path_reg '/pthTxPrev_noID.mat'],'data')

%% Make sure we have all pfizer registry eligible respondents
% -	Age: 8-17 at time of first visit
% -	Diagnosed with post-traumatic headache (PTH) based on ICHD-3 classification as determined by clinical information (patient questionnaire and provider documentation)
% -	First clinic visit within 4 months of concussion
% -	First clinic visit must be between February 2017 to March 2022

% did not follow this inclusion because too restrictive: second visit, documented PCSI score within 12 months of concussion and at least 6 weeks from the first clinic visit

pfizer.days_post_epi = between(pfizer.p_epi_conc_date,pfizer.visit_dt,'days'); pfizer.days_post_epi = split(pfizer.days_post_epi,'d');
pfizer.days_post_cont = between(pfizer.p_con_conc_date,pfizer.visit_dt,'days'); pfizer.days_post_cont = split(pfizer.days_post_cont,'d');
pfizer_eligible = pfizer.record_id(pfizer.age>=8 & pfizer.age<18 & pfizer.visit_dt>=datetime('2017-02-01') & pfizer.age<18 & pfizer.visit_dt<datetime('2022-04-01') &...
    (pfizer.days_post_epi<120 | pfizer.days_post_cont<120));

pfizer_comp = ismember(pfizer_eligible,pth_tx.pfizer_id);

pfizer_add = pfizer_eligible(pfizer_comp == 0);


% Exclusion criteria:
% -	Concussion between first visit and follow up visit
% -	Documented history of chronic migraine prior to concussion
% -	History of chronic pain syndrome such as AMPS
% -	History of IBS
% -	History of nerve block
% -	Patients who are started on a preventive more than 6 weeks prior to first appointment
% -	History of severe neurologic disorders such as stroke, epilepsy, MS
% -	History of severe cardiac disease such as CHD, arrhythmias 
% -	Non-compliance noted with preventive medication at follow up visit (not
% able to do this one because so many were lost to follow up)
% -	Patients started on the following medications 6 weeks to 3 months from the first neurology visit: started on a preventive pharmacologic or supplement medication

clear data

%% Combine triptan data

% load Triptan Tx PTH dataset
data_path_tx = getpref('TxPTH','TxPthDataPath');
load([data_path_tx '/Triptans_112023.mat'])
pth_tx = data;

uniqueID = unique(pth_tx.pfizer_id);
for x = 1:length(uniqueID)
    temp = find(pth_tx.pfizer_id==uniqueID(x));
    if length(temp)>1
        temp2 = 1:height(pth_tx); temp2 = temp2(temp2~=temp(1));
        pth_tx = pth_tx(temp2,:);
    end
end

pth_tx = pth_tx(~isnan(pth_tx.pfizer_id),:);

% join with pfizer data
pfizer_short = pfizer;
pfizer_short.Properties.VariableNames{'record_id'} = 'pfizer_id';

data = join(pth_tx,pfizer_short,'Keys','pfizer_id');

clear temp* uniqueID x


% remove variables (columns) with all zeros
masktable = varfun(@(V) isnumeric(V) && ~any(V), data);
data(:,masktable{:,:}) = [];

% days post injury from first visit
data.days_post = between(data.date_onset,data.firstvisit,'Days');
data.days_post = split(data.days_post,'d');

% days post injury triptans were tried
data.days_post_trp1 = between(data.date_onset,data.trp1_date,'Days');
data.days_post_trp1 = split(data.days_post_trp1,'d');
data.days_post_trp2 = between(data.date_onset,data.trp2_date,'Days');
data.days_post_trp2 = split(data.days_post_trp2,'d');
data.days_post_trp3 = between(data.date_onset,data.trp3_date,'Days');
data.days_post_trp3 = split(data.days_post_trp3,'d');
data = removevars(data,{'record_id','pfizer_id','firstvisit','date_onset','visit_dt',...
    'prov_nm','clin_loc','locator_nm','street_long_deg_x','street_lat_deg_y','p_epi_conc_date',...
    'p_con_start_date','p_prim_care_occ','c_epi_conc_date','c_con_conc_date','trp1_date','trp2_date','trp3_date'});

save([data_path_reg '/pthTxTrp_noID.mat'],'data')
clear data
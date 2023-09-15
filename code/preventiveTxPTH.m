% Analyze PTH treatment data

% load Pfizer dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/PfizerHAdataAug23.mat'])
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
pfizer_short = pfizer;
pfizer_short.Properties.VariableNames{'record_id'} = 'pfizer_id';

data = join(pth_tx,pfizer_short,'Keys','pfizer_id');

clear temp* uniqueID x


% remove variables (columns) with all zeros
masktable = varfun(@(V) isnumeric(V) && ~any(V), data);
data(:,masktable{:,:}) = [];

%% Inclusion criteria (run on PTH treatment dataset)


% Preventive pharmacologic therapy started within 4 months of concussion,
% and symptomatic at time of visit

data.days_post_visit1 = between(data.date_onset,data.firstvisit,'Days');
data.days_post_visit1 = split(data.days_post_visit1,'d');
data = data(data.days_post_visit1<120 & (data.diagnosis_chart_rev=='pth_epi'|data.diagnosis_chart_rev=='pth_cont'),:);

data.days_post_visit2 = between(data.date_onset,data.follow_return_relevant,'Days');
data.days_post_visit2 = split(data.days_post_visit2,'d');

data.days_visit1to2 = between(data.firstvisit,data.follow_return_relevant,'Days');
data.days_visit1to2 = split(data.days_visit1to2,'d');

% Separate those who received treatement within the first 4 months from
% those who did not
data.prev_cat = zeros(height(data),1);
data.prev_cat(data.follow_treat1_dur_cont<120 & (data.follow_treat_cat2___nut_prev==1|data.follow_treat_cat2___rx_prev==1)) = 1;

data.prev_cat2 = categorical(data.prev_cat,[0 1],{'no_prev','prev'});


data.prev_catFull = data.prev_cat;
data.prev_catFull(data.follow_treat_cat2___rx_prev==1) = 2;
data.prev_catFull2 = categorical(data.prev_catFull,[0 1 2],{'no_prev','nutri','rx'});

data.ha_cont = zeros(height(data),1);
data.ha_cont(data.p_current_ha_pattern=='cons_flare'|data.p_current_ha_pattern=='cons_same') = 1;

data.ha_cont = categorical(data.ha_cont,[0 1],{'intermittent','constant'});

%% determine season of concussion, first visit, and follow up visit
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

%% Run ICHD3 diagnostic algorithm and update categories

[ICHD3] = ichd3_Dx(data);

data.pheno = ICHD3.pheno;

data.mig_pheno = zeros(height(data),1);
data.mig_pheno(data.pheno=='migraine'|data.pheno=='chronic_migraine') = 1;

% were lost to follow up
data.fu = zeros(height(data),1);
data.fu(data.follow_return=='Yes' & data.days_post_visit2<365 & data.days_visit1to2<180) = 1;

data.freq_bad = NaN*ones(height(data),1);
data.freq_bad (data.p_fre_bad=='never') = 1;
data.freq_bad (data.p_fre_bad=='1mo') = 2;
data.freq_bad (data.p_fre_bad=='1to3mo') = 3;
data.freq_bad (data.p_fre_bad=='1wk') = 4;
data.freq_bad (data.p_fre_bad=='2to3wk') = 5;
data.freq_bad (data.p_fre_bad=='3wk') = 6;
data.freq_bad (data.p_fre_bad=='daily') = 7;
data.freq_bad (data.p_fre_bad=='always') = 8;

data.pedmidas_grade = NaN*ones(height(data),1);
data.pedmidas_grade(data.p_pedmidas_score<=10) = 0;
data.pedmidas_grade(data.p_pedmidas_score>10 & data.p_pedmidas_score<=30) = 1;
data.pedmidas_grade(data.p_pedmidas_score>30 & data.p_pedmidas_score<=50) = 2;
data.pedmidas_grade(data.p_pedmidas_score>50) = 3;

data.race = reordercats(data.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data.ethnicity = reordercats(data.ethnicity,{'no_hisp','hisp','no_answer','unk'});
data.follow_ben = reordercats(data.follow_ben,{'wor','non_ben','som_ben','sig_ben'});
data.follow_ben(data.follow_ben~='wor' & data.follow_ben~='non_ben' & data.follow_ben~='som_ben' & data.follow_ben~='sig_ben') = 'unk';

% include any duration of med overuse
data.med_overuse = zeros(height(data),1);
data.med_overuse(data.p_duration_overuse=='1to3mo'|data.p_duration_overuse=='less_1mo'|data.p_duration_overuse=='3mo_greater') = 1;


% headache program vs. general neurology
data.prov_nm = categorical(data.prov_nm);
data.ha_program = zeros(height(data),1);
data.ha_program(data.prov_nm=='BARMHERZIG, REBECCA'|data.prov_nm=='CHADEHUMBE, MADELINE'|data.prov_nm=='MALAVOLTA, CARRIE  P'|...
    data.prov_nm=='PATTERSON GENTILE, CARLYN A'|data.prov_nm=='STEPHENSON, DONNA'|data.prov_nm=='SZPERKA, CHRISTINA L'|...
    data.prov_nm=='ZIPLOW, JASON'|data.prov_nm=='ANTO, MARISSA'|data.prov_nm=='KUMAR, ISHANI'|data.prov_nm=='YOUNKIN, DONALD'|data.prov_nm=='HADFIELD, JOCELYN H') = 1;

%% compile treatment specifics

data.tx_medoveruse = data.follow_treat_cat1___withdraw;
data.tx_healthyhabits = data.follow_treat_cat1___hh;
data.tx_bh = zeros(height(data),1); 
data.tx_bh(data.follow_treat_cat1___cbt==1|data.follow_treat_1_non_pharm___counsel) = 1;
data.tx_pt = data.follow_treat_cat1___pt;
data.tx_hep = data.follow_treat_1_non_pharm___hep;
data.tx_vision = data.follow_treat_1_non_pharm___vision;
data.tx_nerveblock = data.follow_treat_cat1___nerv;
data.tx_amitrip = data.follow_treat_1_rx_prev___amitrip;
data.tx_nortrip = data.follow_treat_1_rx_prev___nortrip;
data.tx_cypro = data.follow_treat_1_rx_prev___cypro;
data.tx_metopro = data.follow_treat_1_rx_prev___metopro;
data.tx_propano = data.follow_treat_1_rx_prev___propano;
data.tx_topa = data.follow_treat_1_rx_prev___topa;
data.tx_gaba = data.follow_treat_1_rx_prev___gaba;
data.tx_vpa = data.follow_treat_1_rx_prev___vpa;
data.tx_b2 = data.follow_treat_1_nut_prev___vitb2;
data.tx_vitD = data.follow_treat_1_nut_prev___vitd;
data.tx_CoQ10 = data.follow_treat_1_nut_prev___coenzq10;
data.tx_mag = data.follow_treat_1_nut_prev___mag;
data.tx_melatonin = data.follow_treat_1_nut_prev___melatonin;

% plot treatments



%% Compare initial factors that were associated with being prescribed a preventive medication, and follow up

% Univariate analyses for those with missing data: 
% - age
% - sex
% - socioeconomic status (using zipcode as a surrogate if needed)
% - race
% - ethnicity
% - history of multiple concussions
% - history of migraine
% - family history of migraine
% - overall headache severity at initial visit
% - headache frequency at initial visit
% - disability at initial visit
% - preventive tx vs. none

data.concuss_number(isnan(data.concuss_number)) = 0;
data.concuss_number(data.concuss___general_unclear==1) = NaN;

mdl_fu_age = fitglm(data,'fu ~ age','Distribution','binomial');
mdl_fu_sex = fitglm(data,'fu ~ gender','Distribution','binomial');
mdl_fu_race = fitglm(data,'fu ~ race','Distribution','binomial');
mdl_fu_ethnicity = fitglm(data,'fu ~ ethnicity','Distribution','binomial');
mdl_fu_severity = fitglm(data,'fu ~ p_sev_usual','Distribution','binomial');
mdl_fu_frequency = fitglm(data,'fu ~ freq_bad','Distribution','binomial');
mdl_fu_disability = fitglm(data,'fu ~ p_pedmidas_score','Distribution','binomial');
mdl_fu_conc = fitglm(data,'fu ~ concuss_number','Distribution','binomial');
mdl_fu_prev = fitglm(data,'fu ~ prev_cat','Distribution','binomial');
mdl_fu_cont = fitglm(data,'fu ~ ha_cont','Distribution','binomial');
mdl_fu_dayspost = fitglm(data,'fu ~ days_post_visit1','Distribution','binomial');
mdl_fu_concspec = fitglm(data,'fu ~ p_prov_seen___conc','Distribution','binomial');
mdl_fu_depress = fitglm(data,'fu ~ depression___general_prior','Distribution','binomial');
mdl_fu_anxiety = fitglm(data,'fu ~ anxiety___general_prior','Distribution','binomial');
mdl_fu_concSeason = fitglm(data,'fu ~ conc_seasonCat','Distribution','binomial');
mdl_fu_visit1Season = fitglm(data,'fu ~ visit1_seasonCat','Distribution','binomial');

% do we have data on personal or family history of migraine?

mdl_fu_full = fitglm(data,'fu ~ conc_seasonCat + age + race + p_pedmidas_score + concuss_number + prev_cat + p_prov_seen___conc','Distribution','binomial');

mdl_fu_final = fitglm(data,'fu ~ concuss_number + prev_cat','Distribution','binomial');

% Covariates for preventive prescription and outcome
% - Comorbid anxiety and depression
% - Family history of migraine
% - Personal history of migraine
% - Medication overuse headache
% - Concomitant concussion management including PT/CBT/vision therapy, school accommodations, and acute pharmacologic management 
% - History of multiple concussions
% - Headache burden metrics: 
%  - continuous vs. intermittent
%  - headache frequency
%  - headache severity
%  - headache-related disability (pedMIDAS where available, otherwise will defer to provider documentation)
%  - Presence of migraine-like features as defined by meeting criteria for migraine features based on ICHD-3 criteria C and D
%  - Seen in headache clinic or general neurology for headache management

mdl_prev_age = fitglm(data,'prev_cat ~ age','Distribution','binomial');
mdl_prev_sex = fitglm(data,'prev_cat ~ gender','Distribution','binomial');
mdl_prev_race = fitglm(data,'prev_cat ~ race','Distribution','binomial');
mdl_prev_ethnicity = fitglm(data,'prev_cat ~ ethnicity','Distribution','binomial');
mdl_prev_severity = fitglm(data,'prev_cat ~ p_sev_usual','Distribution','binomial');
mdl_prev_frequency = fitglm(data,'prev_cat ~ freq_bad','Distribution','binomial');
mdl_prev_disability = fitglm(data,'prev_cat ~ p_pedmidas_score','Distribution','binomial');
mdl_prev_conc = fitglm(data,'prev_cat ~ concuss_number','Distribution','binomial');
mdl_prev_medoveruse = fitglm(data,'prev_cat ~ med_overuse','Distribution','binomial');
mdl_prev_mig = fitglm(data,'prev_cat ~ mig_pheno','Distribution','binomial');
mdl_prev_cont = fitglm(data,'prev_cat ~ ha_cont','Distribution','binomial');
mdl_prev_haprog = fitglm(data,'prev_cat ~ ha_program','Distribution','binomial');
mdl_prev_dayspost1 = fitglm(data,'prev_cat ~ days_post_visit1','Distribution','binomial');
mdl_prev_concspec = fitglm(data,'prev_cat ~ p_prov_seen___conc','Distribution','binomial');
mdl_prev_depress = fitglm(data,'prev_cat ~ depression___general_prior','Distribution','binomial');
mdl_prev_anxiety = fitglm(data,'prev_cat ~ anxiety___general_prior','Distribution','binomial');

mdl_prev_full = fitglm(data,'prev_cat ~ age + gender + freq_bad + p_pedmidas_score + concuss_number + mig_pheno + ha_cont','Distribution','binomial');

mdl_prev_final = fitglm(data,'prev_cat ~ age + p_pedmidas_score','Distribution','binomial');

% Follow up at 6 weeks
data.fu_outcome = NaN*ones(height(data),1);
data.fu_outcome(data.follow_ben=='wor') = 1;
data.fu_outcome(data.follow_ben=='non_ben') = 2;
data.fu_outcome(data.follow_ben=='som_ben') = 3;
data.fu_outcome(data.follow_ben=='sig_ben') = 4;

[B,dev,stats] = mnrfit([data.prev_cat data.p_pedmidas_score data.age],data.fu_outcome,'model','ordinal');

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

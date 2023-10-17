% Analyze PTH treatment data

% load Pfizer dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/PfizerHAdataAug23.mat'])
pfizer = data;

% load Tx PTH dataset
data_path_tx = getpref('TxPTH','TxPthDataPath');
load([data_path_tx '/TxPTH091823.mat'])
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
data.prev_cat(data.follow_treat1_dur_cont<120 & (data.follow_treat_cat1___nut_prev==1|data.follow_treat_cat1___rx_prev==1)) = 1;

data.prev_cat2 = categorical(data.prev_cat,[0 1],{'no_prev','prev'});


data.prev_catFull = data.prev_cat;
data.prev_catFull(data.follow_treat_cat2___rx_prev==1) = 2;
data.prev_catFull2 = categorical(data.prev_catFull,[0 1 2],{'no_prev','nutri','rx'});

data.ha_cont = zeros(height(data),1);
data.ha_cont(data.p_current_ha_pattern=='cons_flare'|data.p_current_ha_pattern=='cons_same') = 1;


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
data.mig_pheno(data.pheno=='migraine'|data.pheno=='chronic_migraine'|data.pheno=='prob_migraine') = 1;
data.cm = zeros(height(data),1);
data.cm(data.pheno=='chronic_migraine') = 1;

% were lost to follow up
data.fu = zeros(height(data),1);
data.fu(data.follow_return=='Yes' & data.follow_ben~='unk') = 1;

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


% overall severity grade
data.severity_grade = NaN*ones(height(data),1);
data.severity_grade(data.p_sev_overall=='mild') = 1;
data.severity_grade(data.p_sev_overall=='mod') = 2;
data.severity_grade(data.p_sev_overall=='sev') = 3;

data.race = reordercats(data.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data.ethnicity = reordercats(data.ethnicity,{'no_hisp','hisp','no_answer','unk'});
data.follow_ben = reordercats(data.follow_ben,{'wor','non_ben','som_ben','sig_ben'});
data.follow_ben(data.follow_ben~='wor' & data.follow_ben~='non_ben' & data.follow_ben~='som_ben' & data.follow_ben~='sig_ben') = 'unk';
data.prior_ha_in_lifetime = reordercats(data.prior_ha_in_lifetime,{'no','sick','epi','cont_epi','cont','mis'});
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

data.prior_ha = NaN*ones(height(data),1);
data.prior_ha(data.prior_ha_in_lifetime=='no'|data.prior_ha_in_lifetime=='sick') = 0;
data.prior_ha(data.prior_ha_in_lifetime=='epi'|data.prior_ha_in_lifetime=='cont_epi'|data.prior_ha_in_lifetime=='cont') = 1;

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
data.tx_bh(data.follow_treat_cat1___cbt==1|data.follow_treat_1_non_pharm___counsel==1) = 1;
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

num_bothPrev = length(data.age((data.tx_amitrip==1|data.tx_nortrip==1|data.tx_cypro==1|data.tx_metopro==1|data.tx_propano==1|...
    data.tx_topa==1|data.tx_gaba==1|data.tx_vpa==1) & (data.tx_b2==1|data.tx_vitD==1|data.tx_CoQ10==1|data.tx_mag==1|data.tx_melatonin==1)));

numRx_DisFreq = length(data.age(data.prev_cat==1 & (data.pedmidas_grade>=1 |data.freq_bad>4|data.ha_cont==1)));
numNoRx_DisFreq = length(data.age(data.prev_cat==0 & (data.pedmidas_grade>=1 |data.freq_bad>4|data.ha_cont==1)));
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
mdl_fu_severity = fitglm(data,'fu ~ severity_grade','Distribution','binomial');
mdl_fu_frequency = fitglm(data,'fu ~ freq_bad','Distribution','binomial');
mdl_fu_disability = fitglm(data,'fu ~ pedmidas_grade','Distribution','binomial');
mdl_fu_conc = fitglm(data,'fu ~ concuss_number','Distribution','binomial');
mdl_fu_prev = fitglm(data,'fu ~ prev_cat','Distribution','binomial');
mdl_fu_cont = fitglm(data,'fu ~ ha_cont','Distribution','binomial');
mdl_fu_dayspost = fitglm(data,'fu ~ days_post_visit1','Distribution','binomial');
mdl_fu_concspec = fitglm(data,'fu ~ p_prov_seen___conc','Distribution','binomial');
mdl_fu_depress = fitglm(data,'fu ~ depression___general_prior','Distribution','binomial');
mdl_fu_anxiety = fitglm(data,'fu ~ anxiety___general_prior','Distribution','binomial');
mdl_fu_haprog = fitglm(data,'fu ~ ha_program','Distribution','binomial');
mdl_fu_migraine = fitglm(data,'fu ~ mig_pheno','Distribution','binomial');
mdl_fu_priorHA = fitglm(data,'fu ~ prior_ha','Distribution','binomial');

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


%% preventive analysis

% univariate
mdl_prev_age = fitglm(data,'prev_cat ~ age','Distribution','binomial');
mdl_prev_sex = fitglm(data,'prev_cat ~ gender','Distribution','binomial');
mdl_prev_race = fitglm(data,'prev_cat ~ race','Distribution','binomial');
mdl_prev_ethnicity = fitglm(data,'prev_cat ~ ethnicity','Distribution','binomial');
mdl_prev_severity = fitglm(data,'prev_cat ~ severity_grade','Distribution','binomial');
mdl_prev_frequency = fitglm(data,'prev_cat ~ freq_bad','Distribution','binomial');
mdl_prev_disability = fitglm(data,'prev_cat ~ pedmidas_grade','Distribution','binomial');
mdl_prev_conc = fitglm(data,'prev_cat ~ concuss_number','Distribution','binomial');
mdl_prev_medoveruse = fitglm(data,'prev_cat ~ med_overuse','Distribution','binomial');
mdl_prev_mig = fitglm(data,'prev_cat ~ mig_pheno','Distribution','binomial');
mdl_prev_cont = fitglm(data,'prev_cat ~ ha_cont','Distribution','binomial');
mdl_prev_haprog = fitglm(data,'prev_cat ~ ha_program','Distribution','binomial');
mdl_prev_dayspost1 = fitglm(data,'prev_cat ~ days_post_visit1','Distribution','binomial');
mdl_prev_concspec = fitglm(data,'prev_cat ~ p_prov_seen___conc','Distribution','binomial');
mdl_prev_depress = fitglm(data,'prev_cat ~ depression___general_prior','Distribution','binomial');
mdl_prev_anxiety = fitglm(data,'prev_cat ~ anxiety___general_prior','Distribution','binomial');
mdl_prev_priorHA = fitglm(data,'prev_cat ~ prior_ha','Distribution','binomial');


% sensitivity analysis for Rx vs. nutraceutical
dataRxN = data(data.prev_catFull2=='nutri'|data.prev_catFull2=='rx',:);
dataRxN.prev_catFull = dataRxN.prev_catFull-1;
mdl_RxN_age = fitglm(dataRxN,'prev_catFull ~ age','Distribution','binomial');
mdl_RxN_sex = fitglm(dataRxN,'prev_catFull ~ gender','Distribution','binomial');
mdl_RxN_race = fitglm(dataRxN,'prev_catFull ~ race','Distribution','binomial');
mdl_RxN_ethnicity = fitglm(dataRxN,'prev_catFull ~ ethnicity','Distribution','binomial');
mdl_RxN_severity = fitglm(dataRxN,'prev_catFull ~ severity_grade','Distribution','binomial');
mdl_RxN_frequency = fitglm(dataRxN,'prev_catFull ~ freq_bad','Distribution','binomial');
mdl_RxN_disability = fitglm(dataRxN,'prev_catFull ~ pedmidas_grade','Distribution','binomial');
mdl_RxN_conc = fitglm(dataRxN,'prev_catFull ~ concuss_number','Distribution','binomial');
mdl_RxN_medoveruse = fitglm(dataRxN,'prev_catFull ~ med_overuse','Distribution','binomial');
mdl_RxN_mig = fitglm(dataRxN,'prev_catFull ~ mig_pheno','Distribution','binomial');
mdl_RxN_cont = fitglm(dataRxN,'prev_catFull ~ ha_cont','Distribution','binomial');
mdl_RxN_haprog = fitglm(dataRxN,'prev_catFull ~ ha_program','Distribution','binomial');
mdl_RxN_dayspost1 = fitglm(dataRxN,'prev_catFull ~ days_post_visit1','Distribution','binomial');
mdl_RxN_concspec = fitglm(dataRxN,'prev_catFull ~ p_prov_seen___conc','Distribution','binomial');
mdl_RxN_depress = fitglm(dataRxN,'prev_catFull ~ depression___general_prior','Distribution','binomial');
mdl_RxN_anxiety = fitglm(dataRxN,'prev_catFull ~ anxiety___general_prior','Distribution','binomial');
mdl_RxN_priorHA = fitglm(dataRxN,'prev_catFull ~ prior_ha','Distribution','binomial');
mdl_RxN_fu = fitglm(dataRxN,'fu ~ prev_catFull','Distribution','binomial');

%% Outcome analysis

% Follow up at 6 weeks
data.fu_outcome = NaN*ones(height(data),1);
data.fu_outcome(data.follow_ben=='wor') = 1;
data.fu_outcome(data.follow_ben=='non_ben') = 2;
data.fu_outcome(data.follow_ben=='som_ben') = 3;
data.fu_outcome(data.follow_ben=='sig_ben') = 4;

% Set missing values to all be 1 or all be 4
data.fu_outcomeReplace1 = data.fu_outcome;
data.fu_outcomeReplace1(isnan(data.fu_outcome)) = 1;

data.fu_outcomeReplace4 = data.fu_outcome;
data.fu_outcomeReplace4(isnan(data.fu_outcome)) = 4;

% univariable
[~,~,statsAge] = mnrfit([data.age],data.fu_outcome,'model','ordinal');
tbl_outcome_age = mnrfit_tbl(statsAge,{'age'});
[~,~,statsSex] = mnrfit([data.gender],data.fu_outcome,'model','ordinal');
tbl_outcome_sex = mnrfit_tbl(statsSex,{'gender'});
[~,~,statsWhite] = mnrfit([data.race_white],data.fu_outcome,'model','ordinal');
tbl_outcome_white = mnrfit_tbl(statsWhite,{'white'});
[~,~,statsBlack] = mnrfit([data.race_black],data.fu_outcome,'model','ordinal');
tbl_outcome_black = mnrfit_tbl(statsBlack,{'black'});
[~,~,statsAsian] = mnrfit([data.race_asian],data.fu_outcome,'model','ordinal');
tbl_outcome_asian = mnrfit_tbl(statsAsian,{'asian'});
[~,~,statsNonHisp] = mnrfit([data.eth_nonHisp],data.fu_outcome,'model','ordinal');
tbl_outcome_nonHisp = mnrfit_tbl(statsNonHisp,{'nonHisp'});
[~,~,statsHisp] = mnrfit([data.eth_Hisp],data.fu_outcome,'model','ordinal');
tbl_outcome_Hisp = mnrfit_tbl(statsHisp,{'nonHisp'});
[~,~,statsConc] = mnrfit([data.concuss_number],data.fu_outcome,'model','ordinal');
tbl_outcome_conc = mnrfit_tbl(statsConc,{'concussion number'});
[~,~,statsDep] = mnrfit([data.depression___general_prior],data.fu_outcome,'model','ordinal');
tbl_outcome_depress = mnrfit_tbl(statsDep,{'depression'});
[~,~,statsAnx] = mnrfit([data.anxiety___general_prior],data.fu_outcome,'model','ordinal');
tbl_outcome_anxiety = mnrfit_tbl(statsAnx,{'anxiety'});
[~,~,statsPriorHA] = mnrfit([data.prior_ha],data.fu_outcome,'model','ordinal');
tbl_outcome_priorHA = mnrfit_tbl(statsPriorHA,{'prior headache history'});
[~,~,statsPost1] = mnrfit([data.days_post_visit1],data.fu_outcome,'model','ordinal');
tbl_outcome_post1 = mnrfit_tbl(statsPost1,{'days post visit1'});
[~,~,statsPost2] = mnrfit([data.days_post_visit2],data.fu_outcome,'model','ordinal');
tbl_outcome_post2 = mnrfit_tbl(statsPost2,{'days post visit2'});
[~,~,statsDis] = mnrfit([data.pedmidas_grade],data.fu_outcome,'model','ordinal');
tbl_outcome_disability = mnrfit_tbl(statsDis,{'disability grade'});
[~,~,statsSev] = mnrfit([data.severity_grade],data.fu_outcome,'model','ordinal');
tbl_outcome_severity = mnrfit_tbl(statsSev,{'severity grade'});
[~,~,statsFreq] = mnrfit([data.freq_bad],data.fu_outcome,'model','ordinal');
tbl_outcome_frequency = mnrfit_tbl(statsFreq,{'frequency'});
[~,~,statsCont] = mnrfit([data.ha_cont],data.fu_outcome,'model','ordinal');
tbl_outcome_continuous = mnrfit_tbl(statsCont,{'continuous'});
[~,~,statsMig] = mnrfit([data.mig_pheno],data.fu_outcome,'model','ordinal');
tbl_outcome_migraine = mnrfit_tbl(statsMig,{'migraine phenotype'});
[~,~,statsMOH] = mnrfit([data.med_overuse],data.fu_outcome,'model','ordinal');
tbl_outcome_moh = mnrfit_tbl(statsMOH,{'medication overuse'});
[~,~,statsConcSpec] = mnrfit([data.p_prov_seen___conc],data.fu_outcome,'model','ordinal');
tbl_outcome_concSpec = mnrfit_tbl(statsConcSpec,{'concussion specialist'});
[~,~,statsHAprog] = mnrfit([data.ha_program],data.fu_outcome,'model','ordinal');
tbl_outcome_HAprog = mnrfit_tbl(statsHAprog,{'headache specialist'});
[~,~,statsPrev] = mnrfit([data.prev_cat],data.fu_outcome,'model','ordinal');
tbl_outcome_prev = mnrfit_tbl(statsPrev,{'preventive recommended'});

[~,~,statsPrevMax] = mnrfit([data.prev_cat],data.fu_outcomeReplace4,'model','ordinal');
tbl_outcome_prevMax = mnrfit_tbl(statsPrevMax,{'preventive recommended'});

[~,~,statsPrevMin] = mnrfit([data.prev_cat],data.fu_outcomeReplace1,'model','ordinal');
tbl_outcome_prevMin = mnrfit_tbl(statsPrevMin,{'preventive recommended'});


% multivariable
[~,~,statsFull] = mnrfit([data.age data.gender data.eth_nonHisp data.concuss_number data.days_post_visit1 data.pedmidas_grade data.freq_bad data.ha_cont data.mig_pheno data.prev_cat],data.fu_outcome,'model','ordinal');
tbl_outcome_full = mnrfit_tbl(statsFull,{'age','legal sex','ethicity non Hispanic','concussion number','days post injury 1st visit','HA disability','HA frequency','continuous HA','migraine phenotype','preventive'});

[~,~,statsFinal] = mnrfit([data.gender data.eth_nonHisp data.concuss_number data.days_post_visit1 data.freq_bad data.ha_cont data.prev_cat],data.fu_outcome,'model','ordinal');
tbl_outcome_final = mnrfit_tbl(statsFinal,{'legal sex','non-Hispanic','concussion number','days post injury 1st visit','HA frequency','continuous HA','preventive'});
% days postinjury had a 21% effect, frequency of bad headaches 22% effect, and non-Hispanic had a 17% effect on preventive interaction with outcome

[~,~,statsFinalMax] = mnrfit([data.gender data.eth_nonHisp data.concuss_number data.days_post_visit1 data.freq_bad data.ha_cont data.prev_cat],data.fu_outcomeReplace4,'model','ordinal');
tbl_outcome_finalMax = mnrfit_tbl(statsFinalMax,{'legal sex','non-Hispanic','concussion number','days post injury 1st visit','HA frequency','continuous HA','preventive'});

[~,~,statsFinalMin] = mnrfit([data.gender data.eth_nonHisp data.concuss_number data.days_post_visit1 data.freq_bad data.ha_cont data.prev_cat],data.fu_outcomeReplace1,'model','ordinal');
tbl_outcome_finalMin = mnrfit_tbl(statsFinalMin,{'legal sex','non-Hispanic','concussion number','days post injury 1st visit','HA frequency','continuous HA','preventive'});




% univariable sensitivity analysis (Rx vs. Nutraceutical)
[~,~,statsRxAge] = mnrfit([dataRxN.age],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_ageRx = mnrfit_tbl(statsRxAge,{'age'});
[~,~,statsRxSex] = mnrfit([dataRxN.gender],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_sexRx = mnrfit_tbl(statsRxSex,{'gender'});
[~,~,statsRxWhite] = mnrfit([dataRxN.race_white],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_whiteRx = mnrfit_tbl(statsRxWhite,{'white'});
[~,~,statsRxBlack] = mnrfit([dataRxN.race_black],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_blackRx = mnrfit_tbl(statsRxBlack,{'black'});
[~,~,statsRxAsian] = mnrfit([dataRxN.race_asian],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_asianRx = mnrfit_tbl(statsRxAsian,{'asian'});
[~,~,statsRxNonHisp] = mnrfit([dataRxN.eth_nonHisp],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_nonHispRx = mnrfit_tbl(statsRxNonHisp,{'nonHisp'});
[~,~,statsRxHisp] = mnrfit([dataRxN.eth_Hisp],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_HispRx = mnrfit_tbl(statsRxHisp,{'Hisp'});
[~,~,statsRxConc] = mnrfit([dataRxN.concuss_number],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_concRx = mnrfit_tbl(statsConc,{'concussion number'});
[~,~,statsRxDep] = mnrfit([dataRxN.depression___general_prior],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_depressRx = mnrfit_tbl(statsRxDep,{'depression'});
[~,~,statsRxAnx] = mnrfit([dataRxN.anxiety___general_prior],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_anxietyRx = mnrfit_tbl(statsRxAnx,{'anxiety'});
[~,~,statsRxPriorHA] = mnrfit([dataRxN.prior_ha],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_priorHARx = mnrfit_tbl(statsRxPriorHA,{'prior headache history'});
[~,~,statsRxPost1] = mnrfit([dataRxN.days_post_visit1],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_post1Rx = mnrfit_tbl(statsRxPost1,{'days post visit1'});
[~,~,statsRxPost2] = mnrfit([dataRxN.days_post_visit2],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_post2Rx = mnrfit_tbl(statsRxPost2,{'days post visit2'});
[~,~,statsRxDis] = mnrfit([dataRxN.pedmidas_grade],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_disabilityRx = mnrfit_tbl(statsRxDis,{'disability grade'});
[~,~,statsRxSev] = mnrfit([dataRxN.severity_grade],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_severityRx = mnrfit_tbl(statsRxSev,{'severity grade'});
[~,~,statsRxFreq] = mnrfit([dataRxN.freq_bad],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_frequencyRx = mnrfit_tbl(statsRxFreq,{'frequency'});
[~,~,statsRxCont] = mnrfit([dataRxN.ha_cont],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_continuousRx = mnrfit_tbl(statsRxCont,{'continuous'});
[~,~,statsRxMig] = mnrfit([dataRxN.mig_pheno],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_migraineRx = mnrfit_tbl(statsRxMig,{'migraine phenotype'});
[~,~,statsRxMOH] = mnrfit([dataRxN.med_overuse],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_mohRx = mnrfit_tbl(statsRxMOH,{'medication overuse'});
[~,~,statsRxConcSpec] = mnrfit([dataRxN.p_prov_seen___conc],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_concSpecRx = mnrfit_tbl(statsRxConcSpec,{'concussion specialist'});
[~,~,statsRxHAprog] = mnrfit([dataRxN.ha_program],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_HAprogRx = mnrfit_tbl(statsRxHAprog,{'headache specialist'});
[~,~,statsRxPrev] = mnrfit([dataRxN.prev_cat],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_prevRx = mnrfit_tbl(statsRxPrev,{'preventive recommended'});

% MnrModel = fitmnr(data.prev_cat,data.fu_outcome); need matlab 2023a at
% least

[~,~,statsRxFull] = mnrfit([dataRxN.age dataRxN.gender dataRxN.eth_nonHisp dataRxN.concuss_number dataRxN.pedmidas_grade dataRxN.freq_bad dataRxN.severity_grade dataRxN.med_overuse dataRxN.p_prov_seen___conc dataRxN.ha_program dataRxN.prev_cat],dataRxN.fu_outcome,'model','ordinal');
tbl_outcome_fullRx = mnrfit_tbl(statsRxFull,{'age','legal sex','ethicity non Hispanic','concussion number','HA disability','HA frequency','HA severity','MOH','concussion specialist','headache specialist','preventive'});

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

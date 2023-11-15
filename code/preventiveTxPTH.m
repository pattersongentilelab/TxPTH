% Analyze PTH treatment data

% load preventive dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/pthTxPrev_noID.mat'])


%% Inclusion criteria (run on PTH treatment dataset)


% Preventive pharmacologic therapy started within 4 months of concussion,
% and symptomatic at time of visit


data = data(data.days_post_visit1<120 & (data.diagnosis_chart_rev=='pth_epi'|data.diagnosis_chart_rev=='pth_cont'),:);


% Separate those who received treatement within the first 4 months from
% those who did not
data.prev_cat = zeros(height(data),1);
data.prev_cat(data.follow_treat1_dur_cont<120 & (data.follow_treat_cat1___nut_prev==1|data.follow_treat_cat1___rx_prev==1)) = 1;

data.prev_cat2 = categorical(data.prev_cat,[0 1],{'no_prev','prev'});

data.prev_catFull = data.prev_cat;
data.prev_catFull(data.follow_treat_cat2___rx_prev==1) = 2;
data.prev_catFull2 = categorical(data.prev_catFull,[0 1 2],{'no_prev','nutr','rx'});

% make race and ethnicity numeric
data.race_num = zeros(height(data),1);
data.race_num(data.race=='white') = 1;
data.race_num(data.race=='black') = 2;
data.race_num(data.race=='asian') = 3;
data.race_num(data.race=='no_answer') = 4;
data.race_num(data.race=='unk') = 5;

data.eth_num = zeros(height(data),1);
data.eth_num(data.ethnicity=='no_hisp') = 1;
data.eth_num(data.ethnicity=='hisp') = 2;
data.eth_num(data.ethnicity=='no_answer') = 3;


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
dataRxN = data(data.prev_catFull2=='nutr'|data.prev_catFull2=='rx',:);
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
mdl_OutcomeSex = fitmnr(data,'fu_outcome ~ gender',ModelType="ordinal",CategoricalPredictors="gender");
tbl_OutcomeSex = mnrfit_tbl(mdl_OutcomeSex);
mdl_OutcomeAge = fitmnr(data,'fu_outcome ~ age',ModelType="ordinal");
tbl_OutcomeAge = mnrfit_tbl(mdl_OutcomeAge);
mdl_OutcomeRace = fitmnr(data,'fu_outcome ~ race_num',ModelType="ordinal",CategoricalPredictors="race_num");
tbl_OutcomeRace = mnrfit_tbl(mdl_OutcomeRace);
mdl_OutcomeEth = fitmnr(data,'fu_outcome ~ eth_num',ModelType="ordinal",CategoricalPredictors="eth_num");
tbl_OutcomeEth = mnrfit_tbl(mdl_OutcomeEth);
mdl_OutcomeConcn = fitmnr(data,'fu_outcome ~ concuss_number',ModelType="ordinal");
tbl_OutcomeConcn = mnrfit_tbl(mdl_OutcomeConcn);
mdl_OutcomeDep = fitmnr(data,'fu_outcome ~ depression___general_prior',ModelType="ordinal",CategoricalPredictors="depression___general_prior");
tbl_OutcomeDep = mnrfit_tbl(mdl_OutcomeDep);
mdl_OutcomeAnx = fitmnr(data,'fu_outcome ~ anxiety___general_prior',ModelType="ordinal",CategoricalPredictors="anxiety___general_prior");
tbl_OutcomeAnx = mnrfit_tbl(mdl_OutcomeAnx);
mdl_OutcomePrHA = fitmnr(data,'fu_outcome ~ prior_ha',ModelType="ordinal",CategoricalPredictors="prior_ha");
tbl_OutcomePrHA = mnrfit_tbl(mdl_OutcomePrHA);
mdl_OutcomeDP1 = fitmnr(data,'fu_outcome ~ days_post_visit1',ModelType="ordinal");
tbl_OutcomeDP1 = mnrfit_tbl(mdl_OutcomeDP1);
mdl_OutcomeDP2 = fitmnr(data,'fu_outcome ~ days_post_visit2',ModelType="ordinal");
tbl_OutcomeDP2 = mnrfit_tbl(mdl_OutcomeDP2);
mdl_OutcomeDis = fitmnr(data,'fu_outcome ~ pedmidas_grade',ModelType="ordinal",CategoricalPredictors="pedmidas_grade");
tbl_OutcomeDis = mnrfit_tbl(mdl_OutcomeDis);
mdl_OutcomeSev = fitmnr(data,'fu_outcome ~ severity_grade',ModelType="ordinal",CategoricalPredictors="severity_grade");
tbl_OutcomeSev = mnrfit_tbl(mdl_OutcomeSev);
mdl_OutcomeFreq = fitmnr(data,'fu_outcome ~ freq_bad',ModelType="ordinal");
tbl_OutcomeFreq = mnrfit_tbl(mdl_OutcomeFreq);
mdl_OutcomeContHA = fitmnr(data,'fu_outcome ~ ha_cont',ModelType="ordinal",CategoricalPredictors="ha_cont");
tbl_OutcomeContHA = mnrfit_tbl(mdl_OutcomeContHA);
mdl_OutcomeMig = fitmnr(data,'fu_outcome ~ mig_pheno',ModelType="ordinal",CategoricalPredictors="mig_pheno");
tbl_OutcomeMig = mnrfit_tbl(mdl_OutcomeMig);
mdl_OutcomeMOH = fitmnr(data,'fu_outcome ~ med_overuse',ModelType="ordinal",CategoricalPredictors="med_overuse");
tbl_OutcomeMOH = mnrfit_tbl(mdl_OutcomeDP1);
mdl_OutcomeConcSpec = fitmnr(data,'fu_outcome ~ p_prov_seen___conc',ModelType="ordinal",CategoricalPredictors="p_prov_seen___conc");
tbl_OutcomeConcSpec = mnrfit_tbl(mdl_OutcomeConcSpec);
mdl_OutcomeHAprog = fitmnr(data,'fu_outcome ~ ha_program',ModelType="ordinal",CategoricalPredictors="ha_program");
tbl_OutcomeHAprog = mnrfit_tbl(mdl_OutcomeHAprog);
mdl_OutcomePrev = fitmnr(data,'fu_outcome ~ prev_cat',ModelType="ordinal",CategoricalPredictors="prev_cat");
tbl_OutcomePrev = mnrfit_tbl(mdl_OutcomePrev);
mdl_OutcomePrevMax = fitmnr(data,'fu_outcomeReplace4 ~ prev_cat',ModelType="ordinal",CategoricalPredictors="prev_cat");
tbl_OutcomePrevMax = mnrfit_tbl(mdl_OutcomePrevMax);
mdl_OutcomePrevMin = fitmnr(data,'fu_outcomeReplace1 ~ prev_cat',ModelType="ordinal",CategoricalPredictors="prev_cat");
tbl_OutcomePrevMin = mnrfit_tbl(mdl_OutcomePrevMin);


mdl_OutcomeFull = fitmnr(data,'fu_outcome ~ prev_cat + age + gender + eth_num + concuss_number + days_post_visit1 + pedmidas_grade + freq_bad + ha_cont',...
    ModelType="ordinal",CategoricalPredictors=["prev_cat" "gender" "eth_num" "pedmidas_grade" "ha_cont"]);
tbl_OutcomeFull = mnrfit_tbl(mdl_OutcomeFull);

mdl_OutcomeFinal = fitmnr(data,'fu_outcome ~ prev_cat + gender + eth_num + concuss_number + days_post_visit1 + freq_bad + ha_cont',...
    ModelType="ordinal",CategoricalPredictors=["prev_cat" "gender" "eth_num" "ha_cont"]);
tbl_OutcomeFinal = mnrfit_tbl(mdl_OutcomeFinal);
% days post, ethnicity, and frequency of bad HA >15% impact on preventive relationship
% with outcome


% % univariable sensitivity analysis (Rx vs. Nutraceutical)
mdl_oRxSex = fitmnr(dataRxN,'fu_outcome ~ gender',ModelType="ordinal",CategoricalPredictors="gender");
tbl_oRxSex = mnrfit_tbl(mdl_oRxSex);
mdl_oRxAge = fitmnr(dataRxN,'fu_outcome ~ age',ModelType="ordinal");
tbl_oRxAge = mnrfit_tbl(mdl_oRxAge);
mdl_oRxRace = fitmnr(dataRxN,'fu_outcome ~ race_num',ModelType="ordinal",CategoricalPredictors="race_num");
tbl_oRxRace = mnrfit_tbl(mdl_oRxRace);
mdl_oRxEth = fitmnr(dataRxN,'fu_outcome ~ eth_num',ModelType="ordinal",CategoricalPredictors="eth_num");
tbl_oRxEth = mnrfit_tbl(mdl_oRxEth);
mdl_oRxConcn = fitmnr(dataRxN,'fu_outcome ~ concuss_number',ModelType="ordinal");
tbl_oRxConcn = mnrfit_tbl(mdl_oRxConcn);
mdl_oRxDep = fitmnr(dataRxN,'fu_outcome ~ depression___general_prior',ModelType="ordinal",CategoricalPredictors="depression___general_prior");
tbl_oRxDep = mnrfit_tbl(mdl_oRxDep);
mdl_oRxAnx = fitmnr(dataRxN,'fu_outcome ~ anxiety___general_prior',ModelType="ordinal",CategoricalPredictors="anxiety___general_prior");
tbl_oRxAnx = mnrfit_tbl(mdl_oRxAnx);
mdl_oRxPrHA = fitmnr(dataRxN,'fu_outcome ~ prior_ha',ModelType="ordinal",CategoricalPredictors="prior_ha");
tbl_oRxPrHA = mnrfit_tbl(mdl_oRxPrHA);
mdl_oRxDP1 = fitmnr(dataRxN,'fu_outcome ~ days_post_visit1',ModelType="ordinal");
tbl_oRxDP1 = mnrfit_tbl(mdl_oRxDP1);
mdl_oRxDP2 = fitmnr(dataRxN,'fu_outcome ~ days_post_visit2',ModelType="ordinal");
tbl_oRxDP2 = mnrfit_tbl(mdl_oRxDP2);
mdl_oRxDis = fitmnr(dataRxN,'fu_outcome ~ pedmidas_grade',ModelType="ordinal",CategoricalPredictors="pedmidas_grade");
tbl_oRxDis = mnrfit_tbl(mdl_oRxDis);
mdl_oRxSev = fitmnr(dataRxN,'fu_outcome ~ severity_grade',ModelType="ordinal",CategoricalPredictors="severity_grade");
tbl_oRxSev = mnrfit_tbl(mdl_oRxSev);
mdl_oRxFreq = fitmnr(dataRxN,'fu_outcome ~ freq_bad',ModelType="ordinal");
tbl_oRxFreq = mnrfit_tbl(mdl_oRxFreq);
mdl_oRxContHA = fitmnr(dataRxN,'fu_outcome ~ ha_cont',ModelType="ordinal",CategoricalPredictors="ha_cont");
tbl_oRxContHA = mnrfit_tbl(mdl_oRxContHA);
mdl_oRxMig = fitmnr(dataRxN,'fu_outcome ~ mig_pheno',ModelType="ordinal",CategoricalPredictors="mig_pheno");
tbl_oRxMig = mnrfit_tbl(mdl_oRxMig);
mdl_oRxMOH = fitmnr(dataRxN,'fu_outcome ~ med_overuse',ModelType="ordinal",CategoricalPredictors="med_overuse");
tbl_oRxMOH = mnrfit_tbl(mdl_oRxMOH);
mdl_oRxConcSpec = fitmnr(dataRxN,'fu_outcome ~ p_prov_seen___conc',ModelType="ordinal",CategoricalPredictors="p_prov_seen___conc");
tbl_oRxConcSpec = mnrfit_tbl(mdl_OutcomeConcSpec);
mdl_oRxHAprog = fitmnr(dataRxN,'fu_outcome ~ ha_program',ModelType="ordinal",CategoricalPredictors="ha_program");
tbl_oRxHAprog = mnrfit_tbl(mdl_oRxHAprog);
mdl_oRxRxN = fitmnr(dataRxN,'fu_outcome ~ prev_catFull',ModelType="ordinal",CategoricalPredictors="prev_catFull");
tbl_oRxRxN = mnrfit_tbl(mdl_oRxRxN);


mdl_oRxFull = fitmnr(dataRxN,'fu_outcome ~ prev_catFull + age + gender + concuss_number + freq_bad + pedmidas_grade + severity_grade + med_overuse + ha_program + p_prov_seen___conc',ModelType="ordinal",...
    CategoricalPredictors=["prev_catFull" "gender" "pedmidas_grade" "severity_grade" "med_overuse" "ha_program" "p_prov_seen___conc"]);
tbl_oRxFull = mnrfit_tbl(mdl_oRxFull);

mdl_oRxFinal = fitmnr(dataRxN,'fu_outcome ~ prev_catFull + gender + concuss_number + pedmidas_grade',ModelType="ordinal",...
    CategoricalPredictors=["prev_catFull" "gender" "pedmidas_grade"]);
tbl_oRxFinal = mnrfit_tbl(mdl_oRxFinal);
% pedmidas affected Rx vs. nutraceutical relationship with outcome >15%


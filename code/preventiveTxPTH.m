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
data.prev_catFull2 = categorical(data.prev_catFull,[0 1 2],{'no_prev','nutri','rx'});


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


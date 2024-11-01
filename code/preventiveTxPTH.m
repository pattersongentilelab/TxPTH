% Analyze PTH treatment data

% load preventive dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/pthTxPrev_noID.mat'])

%% Inclusion criteria (run on PTH treatment dataset)


% Preventive pharmacologic therapy started within 4 months of concussion,
% and symptomatic at time of visit and did not receive a nerve block

data = data(data.days_post_visit1<=120,:);
data = data(data.diagnosis_chart_rev=='pth_epi'|data.diagnosis_chart_rev=='pth_cont',:);




% Separate those who received treatement within the first 4 months from
% those who did not
data.prev_cat = zeros(height(data),1);
data.prev_cat(data.follow_treat1_dur_cont<120 & (data.follow_treat_cat1___nut_prev==1|data.follow_treat_cat1___rx_prev==1)) = 1;

data.prev_cat2 = categorical(data.prev_cat,[0 1],{'no_prev','prev'});

data.race = mergecats(data.race,{'unk','am_indian','pacific_island','no_answer'});
data.ethnicity = removecats(data.ethnicity,{'unk','no_answer'});

% replace continuous headache variable with confirmed chart review
data.ha_contUc = data.ha_cont;
data.ha_cont = zeros(height(data),1);
data.ha_cont(data.diagnosis_chart_rev=='pth_epi') = 0;
data.ha_cont(data.diagnosis_chart_rev=='pth_cont') = 1;

% For those with prior headache history, convert NaN to zeros assuming if
% it is not documented, they did not have a prior history
data.prior_ha(isnan(data.prior_ha)) = 0;

% remove outcome data for participants whose follow up visit was >180 days
% after their first visit
data.fu(data.days_visit1to2<28 | data.days_visit1to2>180) = 0;
data.follow_ben(data.days_visit1to2<28 | data.days_visit1to2>180) = '<undefined>';

%% compile treatment specifics

data.tx_medoveruse = data.follow_treat_cat1___withdraw;
data.tx_medoveruse(data.follow_treat1_dur_cont>=120) = 0;
data.tx_healthyhabits = data.follow_treat_cat1___hh;
data.tx_healthyhabits(data.follow_treat1_dur_cont>=120) = 0;
data.tx_bh = zeros(height(data),1); 
data.tx_bh(data.follow_treat_cat1___cbt==1|data.follow_treat_1_non_pharm___counsel==1) = 1;
data.tx_bh(data.follow_treat1_dur_cont>=120) = 0;
data.tx_pt = data.follow_treat_cat1___pt;
data.tx_pt(data.follow_treat1_dur_cont>=120) = 0;
data.tx_hep = data.follow_treat_1_non_pharm___hep;
data.tx_hep(data.follow_treat1_dur_cont>=120) = 0;
data.tx_vision = data.follow_treat_1_non_pharm___vision;
data.tx_vision(data.follow_treat1_dur_cont>=120) = 0;
data.tx_amitrip = data.follow_treat_1_rx_prev___amitrip;
data.tx_amitrip(data.follow_treat1_dur_cont>=120) = 0;
data.tx_nortrip = data.follow_treat_1_rx_prev___nortrip;
data.tx_nortrip(data.follow_treat1_dur_cont>=120) = 0;
data.tx_sertra = data.follow_treat_1_rx_prev___sertra;
data.tx_sertra(data.follow_treat1_dur_cont>=120) = 0;
data.tx_cypro = data.follow_treat_1_rx_prev___cypro;
data.tx_cypro(data.follow_treat1_dur_cont>=120) = 0;
data.tx_metopro = data.follow_treat_1_rx_prev___metopro;
data.tx_metopro(data.follow_treat1_dur_cont>=120) = 0;
data.tx_propano = data.follow_treat_1_rx_prev___propano;
data.tx_propano(data.follow_treat1_dur_cont>=120) = 0;
data.tx_topa = data.follow_treat_1_rx_prev___topa;
data.tx_topa(data.follow_treat1_dur_cont>=120) = 0;
data.tx_gaba = data.follow_treat_1_rx_prev___gaba;
data.tx_gaba(data.follow_treat1_dur_cont>=120) = 0;
data.tx_vpa = data.follow_treat_1_rx_prev___vpa;
data.tx_vpa(data.follow_treat1_dur_cont>=120) = 0;
data.tx_zonis = data.follow_treat_1_rx_prev___zonis;
data.tx_zonis(data.follow_treat1_dur_cont>=120) = 0;
data.tx_othRx = data.follow_treat_1_rx_prev___oth;
data.tx_othRx(data.follow_treat1_dur_cont>=120) = 0;
data.tx_b2 = data.follow_treat_1_nut_prev___vitb2;
data.tx_b2(data.follow_treat1_dur_cont>=120) = 0;
data.tx_vitD = data.follow_treat_1_nut_prev___vitd;
data.tx_vitD(data.follow_treat1_dur_cont>=120) = 0;
data.tx_CoQ10 = data.follow_treat_1_nut_prev___coenzq10;
data.tx_CoQ10(data.follow_treat1_dur_cont>=120) = 0;
data.tx_mag = data.follow_treat_1_nut_prev___mag;
data.tx_mag(data.follow_treat1_dur_cont>=120) = 0;
data.tx_melatonin = data.follow_treat_1_nut_prev___melatonin;
data.tx_melatonin(data.follow_treat1_dur_cont>=120) = 0;
data.tx_othNut = data.follow_treat_1_nut_prev___oth;
data.tx_othNut(data.follow_treat1_dur_cont>=120) = 0;

data.prev_catFull = data.prev_cat;
data.prev_catFull(data.follow_treat_cat1___rx_prev==1 & data.prev_cat==1) = 2;
data.prev_catFull(data.follow_treat_cat1___rx_prev==1 & data.follow_treat_cat1___nut_prev==1 & data.prev_cat==1) = 3;
data.prev_catFull2 = categorical(data.prev_catFull,[0 1 2 3],{'no_prev','nutr','rx','both'});

data.num_prev = sum([data.tx_amitrip data.tx_nortrip data.tx_cypro data.tx_metopro data.tx_propano data.tx_topa data.tx_gaba data.tx_vpa data.tx_zonis data.tx_sertra data.tx_othRx ...
    data.tx_b2 data.tx_vitD data.tx_CoQ10 data.tx_mag data.tx_melatonin data.tx_othRx],2);

data.num_prevRx = sum([data.tx_amitrip data.tx_nortrip data.tx_cypro data.tx_metopro data.tx_propano data.tx_topa data.tx_gaba data.tx_vpa data.tx_zonis data.tx_sertra data.tx_othRx],2);
data.num_prevNut = sum([data.tx_b2 data.tx_vitD data.tx_CoQ10 data.tx_mag data.tx_melatonin data.tx_othRx],2);

data.DisFreq = zeros(height(data),1);
data.DisFreq(data.pedmidas_grade>=1 |data.freq_bad>4|data.ha_cont==1) = 1;


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

data.severity_gradeMin = data.severity_grade;
data.severity_gradeMin(isnan(data.severity_gradeMin)) = min(data.severity_grade);
data.severity_gradeMax = data.severity_grade;
data.severity_gradeMax(isnan(data.severity_gradeMax)) = max(data.severity_grade);

data.freq_badMin = data.freq_bad;
data.freq_badMin(isnan(data.freq_badMin)) = min(data.freq_bad);
data.freq_badMax = data.freq_bad;
data.freq_badMax(isnan(data.freq_badMax)) = max(data.freq_bad);

% for who was prescribed a preventive

[p_presAge,tbl_presAge,stats_presAge] = kruskalwallis(data.age,data.prev_cat2);
[tbl_presSex,chi2_presSex,p_presSex] = crosstab(data.gender,data.prev_cat2);
[tbl_presRace,chi2_presRace,p_presRace] = crosstab(data.race,data.prev_cat2);
[tbl_presEth,chi2_presEth,p_presEth] = crosstab(data.ethnicity,data.prev_cat2);
[p_presDis,tbl_presDis,stats_presDis] = kruskalwallis(data.pedmidas_grade,data.prev_cat2);
[p_presSev,tbl_presSev,stats_presSev] = kruskalwallis(data.severity_grade,data.prev_cat2);
[p_presSevMin,tbl_presSevMin,stats_presSevMin] = kruskalwallis(data.severity_gradeMin,data.prev_cat2);
[p_presSevMax,tbl_presSevMax,stats_presSevMax] = kruskalwallis(data.severity_gradeMax,data.prev_cat2);
[p_presFreqB,tbl_presFreqB,stats_presFreqB] = kruskalwallis(data.freq_bad,data.prev_cat2);
[p_presFreq,tbl_presFreq,stats_presFreq] = kruskalwallis(data.freq_bad,data.prev_cat2);
[p_presFreqMin,tbl_presFreqMin,stats_presFreqMin] = kruskalwallis(data.freq_badMin,data.prev_cat2);
[p_presFreqMax,tbl_presFreqMax,stats_presFreqMax] = kruskalwallis(data.freq_badMax,data.prev_cat2);
[tbl_presCont,chi2_presCont,p_presCont] = crosstab(data.ha_cont,data.prev_cat2);
[tbl_presMOH,chi2_presMOH,p_presMOH] = crosstab(data.med_overuse,data.prev_cat2);
[tbl_presMig,chi2_presMig,p_presMig] = crosstab(data.mig_pheno,data.prev_cat2);
[tbl_presHAprog,chi2_presHAprog,p_presHAprog] = crosstab(data.ha_program,data.prev_cat2);
[tbl_presConcProg,chi2_presConcProg,p_presConcProg] = crosstab(data.p_prov_seen___conc,data.prev_cat2);
[p_presConcNum,tbl_presConcNum,stats_presConcNum] = kruskalwallis(data.concuss_number,data.prev_cat2);
[p_presDaysPost,tbl_presDaysPost,stats_presDaysPost] = kruskalwallis(data.days_post_visit1,data.prev_cat2);
[tbl_presPriorHA,chi2_presPriorHA,p_presPriorHA,] = crosstab(data.prior_ha,data.prev_cat2);



%% Outcome analysis

% Follow up
data.follow_ben = reordercats(data.follow_ben,{'wor','non_ben','som_ben','sig_ben'});
data.fu_outcome = NaN*ones(height(data),1);
data.fu_outcome(data.follow_ben=='wor') = -1;
data.fu_outcome(data.follow_ben=='non_ben') = 0;
data.fu_outcome(data.follow_ben=='som_ben') = 1;
data.fu_outcome(data.follow_ben=='sig_ben') = 2;

[p,tbl,stats] = kruskalwallis(data.fu_outcome,data.prev_cat2);

%% compare complete and incomplete data

data.comp = zeros(height(data),1);
data.comp(~isundefined(data.follow_ben)) = 1;
[p_compAge,tbl_compAge,stats_compAge] = kruskalwallis(data.age,data.comp);
[tbl_compSex,chi2_compSex,p_compSex] = crosstab(data.gender,data.comp);
[tbl_compRace,chi2_compRace,p_compRace] = crosstab(data.race,data.comp);
[tbl_compEth,chi2_compEth,p_compEth] = crosstab(data.ethnicity,data.comp);
[p_compDaysPost,tbl_compDaysPost,stats_compDaysPost] = kruskalwallis(data.days_post_visit1,data.comp);
[tbl_compHAprog,chi2_compHAprog,p_compHAprog] = crosstab(data.ha_program,data.comp);
[tbl_compPrev,chi2_compPrev,p_compPrev] = crosstab(data.prev_cat2,data.comp);
[tbl_compCont,chi2_compCont,p_compCont] = crosstab(data.ha_cont,data.comp);
[tbl_compMOH,chi2_compMOH,p_compMOH] = crosstab(data.med_overuse,data.comp);
[tbl_compMig,chi2_compMig,p_compMig] = crosstab(data.mig_pheno,data.comp);
[p_compDis,tbl_compDis,stats_compDis] = kruskalwallis(data.pedmidas_grade,data.comp);
[p_compSev,tbl_compSev,stats_compSev] = kruskalwallis(data.severity_grade,data.comp);
[p_compFreq,tbl_compFreq,stats_compFreq] = kruskalwallis(data.freq_bad,data.comp);

close all
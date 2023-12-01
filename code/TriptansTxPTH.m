% Analyze PTH acute treatment data

% load triptans dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/pthTxTrp_noID.mat'])


%% Inclusion criteria (run on PTH treatment dataset)

% select only participants age 8 - 17 years who have PTH within one year of their concussion
% by triptan forms that have been filled out
data = data(data.num_prior_meds>=0 & data.age>8 & data.age<18 & data.days_post<=365,:);

% replace continuous headache variable with confirmed chart review
data.ha_contUc = data.ha_cont;
data.ha_cont = zeros(height(data),1);
data.ha_cont(data.diagnosis_chart_rev=='pth_epi') = 0;
data.ha_cont(data.diagnosis_chart_rev=='pth_cont') = 1;

% triptan category
data.trip_cat = zeros(height(data),1);
data.trip_cat(data.num_prior_trp>0) = 1;

% combine response to meds by class
data.nsaid = zeros(height(data),1);
data.nsaid(data.prior_acute_unk___ibupro==1|data.prior_acute_unk___naprox==1|data.prior_acute_unk___asp==1|data.prior_acute_unk___diclof==1|data.prior_acute_unk___celec==1) = 5;
data.nsaid(data.prior_acute_not___ibupro==1|data.prior_acute_not___naprox==1|data.prior_acute_not___nab==1|data.prior_acute_not___asp==1|data.prior_acute_not___ketorolac==1|data.prior_acute_not___ketoprof==1|data.prior_acute_not___diclof==1|data.prior_acute_not___mef==1|data.prior_acute_not___mel==1|data.prior_acute_not___indocin==1) = 1;
data.nsaid(data.prior_acute_effectivelost___ibupro==1|data.prior_acute_effectivelost___naprox==1|data.prior_acute_effectivelost___nab==1) = 2;
data.nsaid(data.prior_acute_partial___ibupro==1|data.prior_acute_partial___naprox==1|data.prior_acute_partial___nab==1|data.prior_acute_partial___asp==1|data.prior_acute_partial___ketorolac==1|data.prior_acute_partial___mef==1|data.prior_acute_partial___indocin==1) = 3;
data.nsaid(data.prior_acute_effective___ibupro==1|data.prior_acute_effective___naprox==1|data.prior_acute_effective___nab==1|data.prior_acute_effective___mef==1) = 4;

data.aceta = zeros(height(data),1);
data.aceta(data.prior_acute_unk___apap==1) = 5;
data.aceta(data.prior_acute_not___apap==1) = 1;
data.aceta(data.prior_acute_effectivelost___apap==1) = 2;
data.aceta(data.prior_acute_partial___apap==1) = 3;
data.aceta(data.prior_acute_effective___apap==1) = 4;

data.excedr = zeros(height(data),1);
data.excedr(data.prior_acute_unk___exced==1) = 5;
data.excedr(data.prior_acute_not___exced==1) = 1;
data.excedr(data.prior_acute_effectivelost___exced==1) = 2;
data.excedr(data.prior_acute_partial___exced==1) = 3;
data.excedr(data.prior_acute_effective___exced==1) = 4;

data.da = zeros(height(data),1);
data.da(data.prior_acute_unk___metoclop==1) = 5;
data.da(data.prior_acute_not___metoclop==1|data.prior_acute_not___proch==1|data.prior_acute_not___prometh==1) = 1;
data.da(data.prior_acute_effectivelost___metoclop==1) = 2;
data.da(data.prior_acute_partial___metoclop==1|data.prior_acute_partial___proch==1) = 3;
data.da(data.prior_acute_effective___metoclop==1) = 4;

data.ond = zeros(height(data),1);
data.ond(data.prior_acute_unk___ond==1) = 5;
data.ond(data.prior_acute_not___ond==1) = 1;
data.ond(data.prior_acute_partial___ond==1) = 3;
data.ond(data.prior_acute_effective___ond==1) = 4;

data.diphen = zeros(height(data),1);
data.diphen(data.prior_acute_unk___diphen==1) = 5;
data.diphen(data.prior_acute_not___diphen==1) = 1;
data.diphen(data.prior_acute_partial___diphen==1) = 3;

data.butal = zeros(height(data),1);
data.butal(data.prior_acute_not___butal==1) = 1;
data.butal(data.prior_acute_partial___butal==1) = 3;
data.butal(data.prior_acute_effective___butal==1) = 4;

data.othMed_resp = zeros(height(data),1);
data.othMed_resp(data.nsaid==5|data.aceta==5|data.excedr==5|data.da==5|data.diphen==5|data.ond==5|data.butal==5) = 5;
data.othMed_resp(data.nsaid==1|data.aceta==1|data.excedr==1|data.da==1|data.diphen==1|data.ond==1|data.butal==1) = 1;
data.othMed_resp(data.nsaid==2|data.aceta==2|data.excedr==2|data.da==2|data.diphen==2|data.ond==2|data.butal==2) = 2;
data.othMed_resp(data.nsaid==3|data.aceta==3|data.excedr==3|data.da==3|data.diphen==3|data.ond==3|data.butal==3) = 3;
data.othMed_resp(data.nsaid==4|data.aceta==4|data.excedr==4|data.da==4|data.diphen==4|data.ond==4|data.butal==4) = 4;

data.nsaid = categorical(data.nsaid,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.nsaid = mergecats(data.nsaid,{'no_effect','lost_effect'});
data.aceta = categorical(data.aceta,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.aceta = mergecats(data.aceta,{'no_effect','lost_effect'});
data.excedr = categorical(data.excedr,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.excedr = mergecats(data.excedr,{'no_effect','lost_effect'});
data.da = categorical(data.da,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.da = mergecats(data.da,{'no_effect','lost_effect'});
data.ond = categorical(data.ond,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.ond = mergecats(data.ond,{'no_effect','lost_effect'});
data.diphen = categorical(data.diphen,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.diphen = mergecats(data.diphen,{'no_effect','lost_effect'});
data.butal = categorical(data.butal,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.butal = mergecats(data.butal,{'no_effect','lost_effect'});
data.othMed_resp = categorical(data.othMed_resp,[1 2 3 4 5 0],{'no_effect','lost_effect','partial_effect','effective','unknown','not_tried'});
data.othMed_resp = mergecats(data.othMed_resp,{'no_effect','lost_effect'});

% triptans used
data.trp1 = zeros(height(data),1);
data.trp1(data.triptan_used_1st___riz==1) = 1;
data.trp1(data.triptan_used_1st___sum==1) = 2;
data.trp1(data.triptan_used_1st___sum_nsl==1) = 3;
data.trp1(data.triptan_used_1st___zol==1) = 4;
data.trp1(data.triptan_used_1st___alm==1) = 5;
data.trp1(data.triptan_used_1st___nar==1) = 6;
data.trp1 = categorical(data.trp1,[1 2 3 4 5 6 0],{'rizatriptan','sumatriptan_oral','sumatriptan_in','zolmatriptan_oral','almotriptan','naratriptan','none'});

data.trp2 = zeros(height(data),1);
data.trp2(data.triptan_used_2nd___riz==1) = 1;
data.trp2(data.triptan_used_2nd___zol==1) = 2;
data.trp2(data.triptan_used_2nd___zol_nsl==1) = 3;
data.trp2(data.triptan_used_2nd___alm==1) = 4;
data.trp2(data.triptan_used_2nd___nar==1) = 5;
data.trp2(data.triptan_used_2nd___fro==1) = 6;
data.trp2 = categorical(data.trp2,[1 2 3 4 5 6 0],{'rizatriptan','zolmatriptan_oral','zolmatriptan_in','almotriptan','naratriptan','frovatriptan','none'});

data.trp3 = zeros(height(data),1);
data.trp3(data.triptan_used_3rd___zol_nsl==1) = 1;
data.trp3(data.triptan_used_3rd___ele==1) = 2;
data.trp3 = categorical(data.trp3,[1 2 0],{'zolmatriptan_in','eletriptan','none'});

%% who was prescribed a triptan

mdl_trip_age = fitglm(data,'trip_cat ~ age','Distribution','binomial');
tbl_age = lmfitBi_tbl(mdl_trip_age);

mdl_trip_sex = fitglm(data,'trip_cat ~ gender','Distribution','binomial');
tbl_sex = lmfitBi_tbl(mdl_trip_sex);

mdl_trip_race = fitglm(data,'trip_cat ~ race','Distribution','binomial');
tbl_race = lmfitBi_tbl(mdl_trip_race);

mdl_trip_ethnicity = fitglm(data,'trip_cat ~ ethnicity','Distribution','binomial');
tbl_ethnicity = lmfitBi_tbl(mdl_trip_ethnicity);

mdl_trip_severity = fitglm(data,'trip_cat ~ severity_grade','Distribution','binomial');
tbl_severity = lmfitBi_tbl(mdl_trip_severity);

mdl_trip_frequency = fitglm(data,'trip_cat ~ freq_bad','Distribution','binomial');
tbl_frequency = lmfitBi_tbl(mdl_trip_frequency);

mdl_trip_disability = fitglm(data,'trip_cat ~ pedmidas_grade','Distribution','binomial');
tbl_disability = lmfitBi_tbl(mdl_trip_disability);

mdl_trip_medoveruse = fitglm(data,'trip_cat ~ med_overuse','Distribution','binomial');
tbl_medoveruse = lmfitBi_tbl(mdl_trip_medoveruse);

mdl_trip_mig = fitglm(data,'trip_cat ~ mig_pheno','Distribution','binomial');
tbl_mig = lmfitBi_tbl(mdl_trip_mig);

mdl_trip_cont = fitglm(data,'trip_cat ~ ha_cont','Distribution','binomial');
tbl_cont = lmfitBi_tbl(mdl_trip_cont);

mdl_trip_haprog = fitglm(data,'trip_cat ~ ha_program','Distribution','binomial');
tbl_haprog = lmfitBi_tbl(mdl_trip_haprog);

mdl_trip_dayspost = fitglm(data,'trip_cat ~ days_post','Distribution','binomial');
tbl_dayspost = lmfitBi_tbl(mdl_trip_dayspost);

mdl_trip_othMeds_resp = fitglm(data,'trip_cat ~ othMed_resp','Distribution','binomial');
tbl_othMeds_resp = lmfitBi_tbl(mdl_trip_othMeds_resp);

mdl_trip_othMeds = fitglm(data,'trip_cat ~ num_prior_meds','Distribution','binomial');
tbl_othMed = lmfitBi_tbl(mdl_trip_othMeds);


%% Triptan efficacy

data_trp = data(data.trip_cat==1,:);
data_trp.trp1_response = NaN*ones(height(data_trp),1);
data_trp.trp1_response(data_trp.response_triptan1___worse_resp==1) = 1;
data_trp.trp1_response(data_trp.response_triptan1___no_resp==1) = 2;
data_trp.trp1_response(data_trp.response_triptan1___partial_resp==1) = 3;
data_trp.trp1_response(data_trp.response_triptan1___full_resp==1) = 4;

data_trp.trp2_response = NaN*ones(height(data_trp),1);
data_trp.trp2_response(data_trp.response_triptan2___no_resp==1) = 2;
data_trp.trp2_response(data_trp.response_triptan2___partial_resp==1) = 3;
data_trp.trp2_response(data_trp.response_triptan2___full_resp==1) = 4;

data_trp.trp3_response = NaN*ones(height(data_trp),1);
data_trp.trp3_response(data_trp.response_triptan3___no_resp==1) = 2;
data_trp.trp3_response(data_trp.response_triptan3___partial_resp==1) = 3;

% make race and ethnicity numeric
data_trp.race_num = zeros(height(data_trp),1);
data_trp.race_num(data_trp.race=='white') = 1;
data_trp.race_num(data_trp.race=='black') = 2;
data_trp.race_num(data_trp.race=='asian') = 3;
data_trp.race_num(data_trp.race=='no_answer') = 4;
data_trp.race_num(data_trp.race=='unk') = 5;

data_trp.eth_num = zeros(height(data_trp),1);
data_trp.eth_num(data_trp.ethnicity=='no_hisp') = 1;
data_trp.eth_num(data_trp.ethnicity=='hisp') = 2;
data_trp.eth_num(data_trp.ethnicity=='no_answer') = 3;

mdl_TrpSex = fitmnr(data_trp,'trp1_response ~ gender',ModelType="ordinal",CategoricalPredictors="gender");
tbl_TrpSex = mnrfit_tbl(mdl_TrpSex);
mdl_TrpAge = fitmnr(data_trp,'trp1_response ~ age',ModelType="ordinal");
tbl_TrpAge = mnrfit_tbl(mdl_TrpAge);
mdl_TrpRace = fitmnr(data_trp,'trp1_response ~ race_num',ModelType="ordinal",CategoricalPredictors="race_num");
tbl_TrpRace = mnrfit_tbl(mdl_TrpRace);
mdl_TrpEth = fitmnr(data_trp,'trp1_response ~ eth_num',ModelType="ordinal",CategoricalPredictors="eth_num");
tbl_TrpEth = mnrfit_tbl(mdl_TrpEth);

mdl_TrpFreq = fitmnr(data_trp,'trp1_response ~ freq_bad',ModelType="ordinal");
tbl_TrpFreq = mnrfit_tbl(mdl_TrpFreq);
mdl_TrpDis = fitmnr(data_trp,'trp1_response ~ pedmidas_grade',ModelType="ordinal",CategoricalPredictors="pedmidas_grade");
tbl_TrpDis = mnrfit_tbl(mdl_TrpDis);
mdl_TrpSeverity = fitmnr(data_trp,'trp1_response ~ severity_grade',ModelType="ordinal",CategoricalPredictors="severity_grade");
tbl_TrpSeverity = mnrfit_tbl(mdl_TrpSeverity);
mdl_TrpCont = fitmnr(data_trp,'trp1_response ~ ha_cont',ModelType="ordinal",CategoricalPredictors="ha_cont");
tbl_TrpCont = mnrfit_tbl(mdl_TrpCont);
mdl_TrpMig = fitmnr(data_trp,'trp1_response ~ mig_pheno',ModelType="ordinal",CategoricalPredictors="mig_pheno");
tbl_TrpMig = mnrfit_tbl(mdl_TrpMig);
mdl_TrpPriorMed = fitmnr(data_trp,'trp1_response ~ num_prior_meds',ModelType="ordinal");
tbl_TrpPriorMed = mnrfit_tbl(mdl_TrpPriorMed);
mdl_TrpMOH = fitmnr(data_trp,'trp1_response ~ med_overuse',ModelType="ordinal",CategoricalPredictors="med_overuse");
tbl_TrpMOH = mnrfit_tbl(mdl_TrpMOH);

mdl_TrpNSAID = fitmnr(data_trp,'trp1_response ~ freq_reg_abort_meds_v2___nsaid',ModelType="ordinal",CategoricalPredictors="freq_reg_abort_meds_v2___nsaid");
tbl_TrpNSAID = mnrfit_tbl(mdl_TrpNSAID);
mdl_TrpDopa = fitmnr(data_trp,'trp1_response ~ freq_reg_abort_meds_v2___dopa',ModelType="ordinal",CategoricalPredictors="freq_reg_abort_meds_v2___dopa");
tbl_TrpDopa = mnrfit_tbl(mdl_TrpDopa);

mdl_TrpDaysPost = fitmnr(data_trp,'trp1_response ~ days_post_trp1',ModelType="ordinal");
tbl_TrpDaysPost = mnrfit_tbl(mdl_TrpDaysPost);

mdl_TrpFull = fitmnr(data_trp,'trp1_response ~ severity_grade + ha_cont + num_prior_meds + mig_pheno + days_post_trp1',ModelType="ordinal",CategoricalPredictors=["severity_grade" "ha_cont" "mig_pheno"]);
tbl_TrpFull = mnrfit_tbl(mdl_TrpFull);

mdl_TrpFinal = fitmnr(data_trp,'trp1_response ~ severity_grade + num_prior_meds + mig_pheno + days_post_trp1',ModelType="ordinal",CategoricalPredictors=["severity_grade" "mig_pheno"]);
tbl_TrpFinal = mnrfit_tbl(mdl_TrpFinal);

%% Side effects
data_trp.trp_se = NaN*ones(height(data_trp),1);
data_trp.trp_se(data_trp.triptan_se_v2___none==1) = 1;
data_trp.trp_se(data_trp.other_sx_trp_v2___none_noted==1) = 2;
data_trp.trp_se(data_trp.triptan_se_v2___chestpain==1) = 3;
data_trp.trp_se(data_trp.triptan_se_v2___numbting==1) = 4;
data_trp.trp_se(data_trp.triptan_se_v2___nausea==1) = 5;
data_trp.trp_se(data_trp.triptan_se_v2___tired==1) = 6;
data_trp.trp_se(data_trp.triptan_se_v2___dizz==1) = 7;
data_trp.trp_se(data_trp.triptan_se_v2___oth==1) = 8;
data_trp.trp_se(sum([data_trp.triptan_se_v2___chestpain data_trp.triptan_se_v2___numbting data_trp.triptan_se_v2___nausea data_trp.triptan_se_v2___tired data_trp.triptan_se_v2___dizz data_trp.triptan_se_v2___oth],2)>1) = 9;

data_trp.trp_se = categorical(data_trp.trp_se,1:9,{'none','none_noted','chest_pain','numbness','nausea','tired','dizziness','other','multiple'});

%% bootstrapped number of meds by triptan response

trp_worse_med_no = prctile(bootstrp(1000,@median,data_trp.num_prior_meds(data_trp.trp1_response==1)),[50 2.5 97.5]);
trp_no_med_no = prctile(bootstrp(1000,@median,data_trp.num_prior_meds(data_trp.trp1_response==2)),[50 2.5 97.5]);
trp_partial_med_no = prctile(bootstrp(1000,@median,data_trp.num_prior_meds(data_trp.trp1_response==3)),[50 2.5 97.5]);
trp_full_med_no = prctile(bootstrp(1000,@median,data_trp.num_prior_meds(data_trp.trp1_response==4)),[50 2.5 97.5]);
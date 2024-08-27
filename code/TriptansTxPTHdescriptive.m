% Analyze PTH acute treatment data

% load triptans dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/pthTxTrp_noID.mat'])


%% Inclusion criteria (run on PTH treatment dataset)

% select only participants age 8 - 17 years who have PTH within one year of their concussion
% by triptan forms that have been filled out
data = data(data.num_prior_meds>=0 & data.age>8 & data.age<18 & data.days_post<=365,:);

data.race = removecats(data.race);
data.race = removecats(data.race,'no_answer');
data.ethnicity = removecats(data.ethnicity);
data.ethnicity = removecats(data.ethnicity,'no_answer');

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

data.acuteChronic = ones(height(data),1);
data.acuteChronic(data.days_post<90) = 0;
data.acuteChronic = categorical(data.acuteChronic,[0 1],{'acute','chronic'});

%% who was prescribed a triptan

[p_presAge,tbl_presAge,stats_presAge] = kruskalwallis(data.age,data.trip_cat);
[tbl_presSex,chi2_presSex,p_presSex] = crosstab(data.gender,data.trip_cat);
[tbl_presRace,chi2_presRace,p_presRace] = crosstab(data.race,data.trip_cat);
[tbl_presEth,chi2_presEth,p_presEth] = crosstab(data.ethnicity,data.trip_cat);
[tbl_presMOH,chi2_presMOH,p_presMOH] = crosstab(data.med_overuse,data.trip_cat);
[tbl_presMig,chi2_presMig,p_presMig] = crosstab(data.mig_pheno,data.trip_cat);
[tbl_presHAprog,chi2_presHAprog,p_presHAprog] = crosstab(data.ha_program,data.trip_cat);
[p_presDaysPost,tbl_presDaysPost,stats_presDaysPost] = kruskalwallis(data.days_post,data.trip_cat);
[tbl_presAC,chi2_presAC,p_presAC] = crosstab(data.acuteChronic,data.trip_cat);
[p_presPriorMed,tbl_presPriorMed,stats_presPriorMed] = kruskalwallis(data.num_prior_meds,data.trip_cat);




%% Triptan efficacy

data_trp = data(data.trip_cat==1,:);
for x = 1:height(data_trp)
    if isnan(data_trp.days_post_trp1(x))
        data_trp.days_post_trp1(x) = data_trp.days_post(x);
    end
end
data_no_trp = data(data.trip_cat==0,:);
data_trp.trp1_response = NaN*ones(height(data_trp),1);
data_trp.trp1_response(data_trp.response_triptan1___worse_resp==1) = 0;
data_trp.trp1_response(data_trp.response_triptan1___no_resp==1) = 0;
data_trp.trp1_response(data_trp.response_triptan1___partial_resp==1) = 1;
data_trp.trp1_response(data_trp.response_triptan1___full_resp==1) = 2;

data_trp.trp2_response = NaN*ones(height(data_trp),1);
data_trp.trp2_response(data_trp.response_triptan2___no_resp==1) = 0;
data_trp.trp2_response(data_trp.response_triptan2___partial_resp==1) = 1;
data_trp.trp2_response(data_trp.response_triptan2___full_resp==1) = 2;

data_trp.trp3_response = NaN*ones(height(data_trp),1);
data_trp.trp3_response(data_trp.response_triptan3___no_resp==1) = 0;
data_trp.trp3_response(data_trp.response_triptan3___partial_resp==1) = 1;

data_trp.nsaid_dopa = zeros(height(data_trp),1);
data_trp.nsaid_dopa(data_trp.freq_reg_abort_meds_v2___nsaid==1) = 1;
data_trp.nsaid_dopa(data_trp.freq_reg_abort_meds_v2___dopa==1) = 1;

% efficacy vs. covariates
data_trp.outcome = zeros(height(data_trp),1);
data_trp.outcome(~isnan(data_trp.trp1_response)) = 1;
data_trp_comp = data_trp;

data_trp.trp1_responseMin = data_trp.trp1_response;
data_trp.trp1_responseMin(isnan(data_trp.trp1_responseMin)) = 0;
data_trp.trp1_responseMax = data_trp.trp1_response;
data_trp.trp1_responseMax(isnan(data_trp.trp1_responseMax)) = 2;

data_trp.acuteChronic_trp1 = 2*ones(height(data_trp),1);
data_trp.acuteChronic_trp1(data_trp.days_post_trp1<30) = 0;
data_trp.acuteChronic_trp1(data_trp.days_post_trp1>=30 & data_trp.days_post_trp1<90) = 1;
data_trp.acuteChronic_trp1 = categorical(data_trp.acuteChronic_trp1,[0 1 2],{'hyperacute','acute','chronic'});

data_trp.acuteChronic_trp1Simp = mergecats(data_trp.acuteChronic_trp1,{'acute','hyperacute'});

[rho_respPriorMed,p_respPriorMed] = corr(data_trp.num_prior_meds(data_trp.outcome==1),data_trp.trp1_response(data_trp.outcome==1));
[rho_respPriorMedmin,p_respPriorMedmin] = corr(data_trp.num_prior_meds,data_trp.trp1_responseMin);
[rho_respPriorMedmax,p_respPriorMedmax] = corr(data_trp.num_prior_meds,data_trp.trp1_responseMax);

[p_respAC,tbl_respAC,stats_respAC] = kruskalwallis(data_trp.trp1_response(data_trp.outcome==1),data_trp.acuteChronic(data_trp.outcome==1));
[p_respACmin,tbl_respACmin,stats_respACmin] = kruskalwallis(data_trp.trp1_responseMin,data_trp.acuteChronic);
[p_respACmax,tbl_respACmax,stats_respACmax] = kruskalwallis(data_trp.trp1_responseMax,data_trp.acuteChronic);

[p_respCombo,tbl_respCombo,stats_respCombo] = kruskalwallis(data_trp.trp1_response(data_trp.outcome==1),data_trp.nsaid_dopa(data_trp.outcome==1));
[p_respCombomin,tbl_respCombomin,stats_respCombomin] = kruskalwallis(data_trp.trp1_responseMin,data_trp.nsaid_dopa);
[p_respCombomax,tbl_respCombomax,stats_respCombomax] = kruskalwallis(data_trp.trp1_responseMax,data_trp.nsaid_dopa);


%% Side effects
data_trp.worseHA = zeros(height(data_trp),1);
data_trp.worseHA(data_trp.response_triptan1___worse_resp==1) = 1;

data_trp.trp_se = NaN*ones(height(data_trp),1);
data_trp.trp_se(data_trp.triptan_se_v2___none==1) = 1;
data_trp.trp_se(data_trp.other_sx_trp_v2___none_noted==1) = 2;
data_trp.trp_se(data_trp.triptan_se_v2___chestpain==1) = 3;
data_trp.trp_se(data_trp.triptan_se_v2___numbting==1) = 4;
data_trp.trp_se(data_trp.triptan_se_v2___nausea==1) = 5;
data_trp.trp_se(data_trp.triptan_se_v2___tired==1) = 6;
data_trp.trp_se(data_trp.triptan_se_v2___dizz==1) = 7;
data_trp.trp_se(data_trp.worseHA==1) = 8;
data_trp.trp_se(data_trp.triptan_se_v2___oth==1) = 9;
data_trp.trp_se(sum([data_trp.triptan_se_v2___chestpain data_trp.triptan_se_v2___numbting data_trp.triptan_se_v2___nausea data_trp.triptan_se_v2___tired data_trp.triptan_se_v2___dizz data_trp.triptan_se_v2___oth data_trp.worseHA],2)>1) = 10;

data_trp.trp_se = categorical(data_trp.trp_se,1:10,{'none','none_noted','chest_pain','numbness','nausea','tired','dizziness','worse HA','other','multiple'});
data_trp.se_yn = zeros(height(data_trp),1);
data_trp.se_yn(data_trp.triptan_se_v2___chestpain==1|data_trp.triptan_se_v2___numbting==1|data_trp.triptan_se_v2___nausea==1|data_trp.triptan_se_v2___tired==1 ...
    |data_trp.triptan_se_v2___dizz==1|data_trp.triptan_se_v2___oth==1|data_trp.worseHA==1) = 1;

close all

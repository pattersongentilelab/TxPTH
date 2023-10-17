% Analyze PTH acute treatment data

% load Pfizer dataset
data_path_reg = getpref('TxPTH','pfizerDataPath');
load([data_path_reg '/PfizerHAdataAug23.mat'])

pfizer = data;

% load Tx PTH dataset
data_path_tx = getpref('TxPTH','TxPthDataPath');
load([data_path_tx '/Triptans_101323.mat'])
pth_tx = data;

clear data data_path*

%% Combine relevant pfizer and pth_tx datasets

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

%% Inclusion criteria (run on PTH treatment dataset)

% select only participants age 8 - 17 years who have PTH within one year of their concussion
% by triptan forms that have been filled out
data = data(data.num_prior_meds>=0 & data.age>8 & data.age<18,:);


% days post injury
data.days_post = between(data.date_onset,data.firstvisit,'Days');
data.days_post = split(data.days_post,'d');

%% determine season of concussion, first visit, and follow up visit
% winter december - february
% spring march - may
% summer june - august
% fall september - november

data.conc_season = NaN*ones(height(data),1);
data.conc_month = month(data.date_onset);
data.conc_season(data.conc_month==12 | data.conc_month==1 | data.conc_month==2) = 1;
data.conc_season(data.conc_month==3 | data.conc_month==4 | data.conc_month==5) = 2;
data.conc_season(data.conc_month==6 | data.conc_month==7 | data.conc_month==8) = 3;
data.conc_season(data.conc_month==9 | data.conc_month==10 | data.conc_month==11) = 4;
data.conc_seasonCat = categorical(data.conc_season,[4 1 2 3],{'fall','winter','spring','summer'});


%% Run ICHD3 diagnostic algorithm and update categories

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

data.pedmidas_grade = NaN*ones(height(data),1);
data.pedmidas_grade(data.p_pedmidas_score<=10) = 0;
data.pedmidas_grade(data.p_pedmidas_score>10 & data.p_pedmidas_score<=30) = 1;
data.pedmidas_grade(data.p_pedmidas_score>30 & data.p_pedmidas_score<=50) = 2;
data.pedmidas_grade(data.p_pedmidas_score>50) = 3;

% overall severity grade
data.severity_grade = NaN*ones(height(data),1);
data.severity_grade(data.p_sev_overall=='mild') = 1;
data.severity_grade(data.p_sev_overall=='mod') = 2;
data.severity_grade(data.p_sev_overall=='sev') = 3;

data.race = reordercats(data.race,{'white','black','asian','am_indian','pacific_island','no_answer','unk'});
data.ethnicity = reordercats(data.ethnicity,{'no_hisp','hisp','no_answer','unk'});
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
data.trp1(data.triptan_used_1st___zol==1) = 3;
data.trp1(data.triptan_used_1st___alm==1) = 4;
data.trp1 = categorical(data.trp1,[1 2 3 4 0],{'rizatriptan','sumatriptan','zolmatriptan','almotriptan','none'});

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

[~,~,statsFreq] = mnrfit([data_trp.freq_bad],data_trp.trp1_response,'model','ordinal');
tbl_outcome_frequency = mnrfit_tbl(statsFreq,{'frequency'});
[~,~,statsDis] = mnrfit([data_trp.pedmidas_grade],data_trp.trp1_response,'model','ordinal');
tbl_outcome_disability = mnrfit_tbl(statsDis,{'disability grade'});
[~,~,statsSev] = mnrfit([data_trp.severity_grade],data_trp.trp1_response,'model','ordinal');
tbl_outcome_severity = mnrfit_tbl(statsSev,{'severity grade'});
[~,~,statsCont] = mnrfit([data_trp.ha_cont],data_trp.trp1_response,'model','ordinal');
tbl_outcome_continuous = mnrfit_tbl(statsCont,{'continuous'});
[~,~,statsMig] = mnrfit([data_trp.mig_pheno],data_trp.trp1_response,'model','ordinal');
tbl_outcome_migraine = mnrfit_tbl(statsMig,{'migraine phenotype'});

% other medications used with triptans
[~,~,statsWnsaid] = mnrfit([data_trp.freq_reg_abort_meds_v2___nsaid],data_trp.trp1_response,'model','ordinal');
tbl_outcome_wNsaids = mnrfit_tbl(statsWnsaid,{'used with NSAID'});
[~,~,statsWdopa] = mnrfit([data_trp.freq_reg_abort_meds_v2___dopa],data_trp.trp1_response,'model','ordinal');
tbl_outcome_wDopa = mnrfit_tbl(statsWdopa,{'used with DA'});

% number of prior medications
[~,~,statsPriorMed] = mnrfit([data_trp.num_prior_meds],data_trp.trp1_response,'model','ordinal');
tbl_outcome_PriorMed = mnrfit_tbl(statsPriorMed,{'number of prior meds'});


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

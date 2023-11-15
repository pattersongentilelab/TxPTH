
function [tbl] = mnrfit_tbl(mdl)

VarNames = mdl.CoefficientNames;
interceptNo = length(mdl.CoefficientNames(contains(mdl.CoefficientNames,"Intercept")==1));
nVar = length(mdl.CoefficientNames)-interceptNo;
VarNames = VarNames(interceptNo+1:end);

tbl = table('Size',[nVar 4],'VariableTypes',{'double','double','double','double'},'VariableNames',{'estimate','low95','hi95','p_val'},'RowNames',VarNames);

for i = 1:nVar
    predicted = mdl.Coefficients.Value(i+interceptNo);
    se = mdl.Coefficients.SE(i+interceptNo);
    tbl.estimate(i) = exp(predicted);
    tbl.low95(i) = exp(predicted - (1.96*se));
    tbl.hi95(i) = exp(predicted + (1.96*se));
    tbl.p_val(i) = mdl.Coefficients.pValue(i+interceptNo);
end

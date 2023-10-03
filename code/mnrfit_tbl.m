
function [tbl] = mnrfit_tbl(stats,VarNames)

nVar = size(VarNames,2);

tbl = table('Size',[nVar 1],'VariableTypes',{'double'},'VariableNames',{'estimate'},'RowNames',VarNames);

y = 1:length(stats.beta);
y = y(length(stats.beta)-nVar+1:end);

predicted = stats.beta(y);
se = stats.se(y);
tbl.estimate = exp(predicted);
tbl.low95 = exp(predicted - (1.96*se));
tbl.hi95 = exp(predicted + (1.96*se));
tbl.p_val = stats.p(y);

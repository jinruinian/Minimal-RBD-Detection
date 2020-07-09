function metrics = process_classification_results(Yhat, Ytst)
% This function produces performance results (accuracy, sensitivty,
% specificity, precision, recall, F1 score, positive-predicitive-value)
%
% Inputs:
%  Yhat   - Classified results
%  Ytst   - Actual Results (ground truth)
%
% Outputs:
%  [acc, sensi, speci, prec, recall, f1, ppv]
%    -accuracy
%    -sensitivity
%    -specificity
%    -precision
%    -recall
%    -F1 score
%    -Positive-predictive-value
% --
% RBD Sleep Detection Toolbox, version 1.0, November 2018
% Released under the GNU General Public License
%
% Copyright (C) 2018  Navin Cooray
% Institute of Biomedical Engineering
% Department of Engineering Science
% University of Oxford
% navin.cooray@eng.ox.ac.uk
%
%
% Referencing this work
% Navin Cooray, Fernando Andreotti, Christine Lo, Mkael Symmonds, Michele T.M. Hu, & Maarten De % Vos (in review). Detection of REM Sleep Behaviour Disorder by Automated Polysomnography Analysis. Clinical Neurophysiology.
%
% Last updated : 15-10-2018
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


TP = Yhat(Ytst == 1);
TP =  length(TP(TP == 1));

FP = Yhat(Ytst == 0);
FP = length(FP(FP == 1));

FN = Yhat(Ytst == 1);
FN = length(FN(FN==0));

TN = Yhat(Ytst == 0);
TN = length(TN(TN==0));

sensi = TP/(TP+FN);
speci = TN/(FP+TN);
acc = numel(find(Yhat==Ytst))/length(Ytst);
prec = TP/(TP+FP);
recall = TP/(TP+FN);
f1 = 2*((recall*prec)/(recall+prec));

ConfMat_Class_Summary = confusionmat(Yhat, Ytst, 'order', [0 1]);
kappa = kappa_result(ConfMat_Class_Summary);

metrics = [acc, sensi, speci, prec, recall, f1,kappa];
metrics(isnan(metrics)) = 0;

end
function    All_Confusion = print_confusion_mats(Sleep,Sleep_Struct,Yhat,print_figures,print_folder)
% This function combines all individial subject confusion matrices for
% sleep staging and generates figures for comparison of automated and
% annoated sleep staging (hypnograms) 
%
% Inputs:
%  Sleep    - Matrix with all features for every epoch
%  Sleep_Struct   - Structure with all features for every epoch, includes
%                   subject names
%  Yhat - Results of automated sleep staging for each epoch
%  print_figures - flag to print/save figures of results
%  print_folder - folder to save figures
% Outputs:
%  All_Confusion - summated confusion matrix of all subjects
%
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

num_subjects = unique(Sleep(:,1));
Subject = fieldnames((Sleep_Struct));   
num_states = unique(Yhat);
if length(num_states) >3
    state_labels = {'W','N1','N2','N3','R'};
else
    state_labels = {'W','NREM','R'};
end

for i=1:length(num_subjects)

    sub_idx = ismember(Sleep(:,1),num_subjects(i)); 

    metrics = process_classification_results(Yhat(sub_idx)==5, Sleep(sub_idx,7)==5);
    acc = metrics(1);
    sensi = metrics(2);
    speci = metrics(3);
    
    ConfMat1{i} = confusionmat(Yhat(sub_idx), Sleep(sub_idx,7), 'order', num_states);
    ConfMat3{i} = confusionmat(Yhat(sub_idx)==5, Sleep(sub_idx,7)==5, 'order', [0 1]);
    kappa(i) = kappa_result(ConfMat3{i});    
    conf_mat = ConfMat1{i}; 
    %total number of stages
    n = sum(sum(conf_mat,2)); 
    %number of agreements
    n_a = sum(sum(eye(size(conf_mat)).*conf_mat)); 
    %numberof agreement due to chance
    agree_chance = (sum(conf_mat,1)./n)*(sum(conf_mat,2)./n)*n;     
    kappa_SS(i) = (n_a-agree_chance)/(n-agree_chance);          
    %% Generate Figures
    % Confusion Matrix
    if print_figures
        generate_confmat(ConfMat1{i},Subject{i},print_figures,print_folder);

        %Hypnograms
        fig_1 = figure;
        a(1) = subplot(2,1,1);
        stairs(Sleep(sub_idx,7),'LineWidth',1);
        title(['Annotated Test Sequence: ',Subject{i}], 'Interpreter', 'none');
        ylabel('Sleep Stage');
        xlabel('Epoch #');
        ylim([-0.5 6]);
        set(gca,'YTick',num_states)
        set(gca,'YTickLabel',state_labels)    
        a(2) = subplot(2,1,2);
        stairs(Yhat(sub_idx),'r','LineWidth',1);
        title(['Automated Staging: REM (Acc:  ',num2str(acc,'%1.2f'),' Sen:  ',num2str(sensi,'%1.2f'),' Spe:  ',num2str(speci,'%1.2f'),')']);
        ylabel('Sleep Stage');
        xlabel('Epoch #');
        ylim([-0.5 6]);
        set(gca,'YTick',num_states)
        set(gca,'YTickLabel',state_labels)
        linkaxes(a,'x');
        xlim([0 length(Sleep(sub_idx,7))]);        
        if (print_figures), saveas(fig_1,strcat(print_folder,'\','RF_Hyp_Comparison_',Subject{i}),'png'), end
        close(fig_1);
        fig_1b = figure;
        h1a = stairs(Sleep(sub_idx,7),'DisplayName','Hypnogram','LineWidth',1);
        title(['Annotated Test Sequence: ',Subject{i}], 'Interpreter', 'none');
        ylabel('Sleep Stage');
        xlabel('Epoch #');
        ylim([-0.5 6]);
        set(gca,'YTick',num_states)
        set(gca,'YTickLabel',state_labels)   
        hold on;
        h2a = stairs(Yhat(sub_idx),'r','DisplayName','RF Result','LineWidth',1);
        if (print_figures), saveas(fig_1b,strcat(print_folder,'\','RF_Hyp_AlignComp_',Subject{i}),'epsc'), end
        close(fig_1b);
        %%
    T_results = process_classification_results_table(Yhat(sub_idx),Sleep(sub_idx,7));

    fig_t = figure;
    uitable('Data',T_results{:,:},'ColumnName',T_results.Properties.VariableNames,...
    'RowName',T_results.Properties.RowNames,'Units', 'Normalized', 'Position',[0, 0, 1, 1]);

    if (print_figures), saveas(fig_t,strcat(print_folder,'\','All_Sleep_Stage_Performance_Table_',Subject{i}),'png'), end
    close(fig_t);
    end


end
% Print Combined Confusion Matrix
    Summary_ConfMat = confusionmat(Yhat, Sleep(:,7), 'order', num_states);
    generate_confmat(Summary_ConfMat,'Summary',print_figures,print_folder);
% Print RBD Combined Confusion Matrix
    rbd_idx = Sleep(:,6)==5; 
    RBD_ConfMat = confusionmat(Yhat(rbd_idx), Sleep(rbd_idx,7), 'order', num_states);
    generate_confmat(RBD_ConfMat,'RBD_Summary',print_figures,print_folder);
% Print HC Combined Confusion Matrix
    HC_ConfMat = confusionmat(Yhat(~rbd_idx), Sleep(~rbd_idx,7), 'order', num_states);
    generate_confmat(HC_ConfMat,'HC_Summary',print_figures,print_folder);
    
    All_Confusion = ConfMat1;
end


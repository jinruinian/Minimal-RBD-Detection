function [epochs, labels] = importcsv_new(filename)

%% Import data from text file.
% Script for importing data from the following text file:
%
%    /data/datasets/Navin_Data/JR Data/Patient_N242_Night1_epochs.csv
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2017/10/26 21:58:15

delimiter = ',';
startRow = 2;

%% Format for each line of text:
%   column1: double (%f)
%	column2: text (%s)
%   column3: double (%f)
%	column4: text (%s)
%   column5: double (%f)
%	column6: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Create output variable
pat = table(dataArray{1:end-1}, 'VariableNames', {'Epoch','Stage','Epoch1','Stage1','Epoch2','Stage2'});


%% Create output variable
epochs = reshape(table2cell(pat(:,[1,3,5])),[],1);
Stage = reshape(table2cell(pat(:,[2,4,6])),[],1);
keep = cellfun(@(x) ~strcmp(x,'-'), epochs)|cellfun(@(x) ~strcmp(x,'-'), Stage);
epochs = str2double(epochs(keep));
Stage = Stage(keep);
Stage(cellfun(@(x) strcmp(x,'NREM 4'),cellstr(Stage))) = {'NREM 3'};
CLASSES = {'\<Wake\>', '\<NREM 1\>', '\<NREM 2\>', '\<NREM 3\>', '\<REM\>'};
labels = cellfun(@(x) regexp(x,CLASSES), Stage,'uniformoutput',0);
labels = cell2mat(cellfun(@(x) ~cellfun(@isempty, x), labels,'UniformOutput',0));

rem = ~any(labels,2); %find rows of zero
epochs(rem) = [];
labels(rem,:) = [];
%% Clear temporary variable
clearvars filename delimiter startRow formatSpec fileID dataArray ans raw col numericData rawData row regexstr result numbers invalidThousandsSeparator thousandsRegExp R;
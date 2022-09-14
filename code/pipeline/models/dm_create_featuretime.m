function [featuretab, feature] = dm_create_featuretime(subject, what)

d       = dm_dir;

savedir = fullfile(d.derived, subject.sublabel, subject.seslabel, 'meg');

% Filename
prefix = [num2str(subject.subnr) '-' num2str(subject.sesnr)];
fname  = ['_' what 's'];
suffix = '.txt';
savename = [prefix fname suffix];

if exist(fullfile(savedir, savename), 'file')
    
    fprintf('Loading feature table ...\n')
    featuretab = readtable(fullfile(savedir, savename));
    load(fullfile(savedir, [prefix, fname, '.mat']));

else
    
    fprintf('Creating %s feature table ...\n', what)
    % Load data
    load(subject.sourcedata); % 'data' variable

    % trial loop
    for k = 1:numel(data.trial)

        % Find textfile, use 4th column in .trl to derive run index
        pref = [sprintf('%02d', subject.sesnr) '_' num2str(subject.trl(k, 4))];
        txt = fullfile(d.stim, 'alignment_v2', [pref '_pfa.txt']);
        
        fprintf('Reading %s...\n', txt);
        [~, ~, tmp(k)]    = dm_pfa2ctf(txt, data.time{k}, what);
        %tmp{k}.trial   = repmat(k, size(tmp{k}(:, 1)));

    end
    
    % create .mat structure representation
    feature.trial = {tmp(:).trial};
    feature.time  = {tmp(:).time};
    feature.label = {tmp(:).label};
    
    % save tabular form
    %fprintf('Saving %s...\n', fullfile(savedir, savename));
    %writetable(feature1, fullfile(savedir, savename));
    
    % Save .mat
    fprintf('Saving %s...\n', fullfile(savedir, [prefix fname '.mat']));
    save(fullfile(savedir, [prefix fname '.mat']), 'feature');
    
end
end
function [subject] = dm_subjinfo(name, session)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

d = dm_dir();

if strcmp(name, 'p01')
    sublabel = 'pil-001';
else
    sublabel = name;
end

% Find .ds files in /raw and /meg
rawdir   = fullfile(d.raw, sublabel);
sessions = dir(rawdir);
sel      = ~cellfun('isempty', (strfind({sessions.name}, {'ses-'}))); % cell array of ones/zeros
sessions = sessions(sel);

if exist('session', 'var')
    sessions = sessions(ismember({sessions.name}, session));
end

num_sessions = numel(sessions);

% define known sessions that have slow drift and mark them as exceptions
exceptions = {'sub-002_ses-009';
              'sub-003_ses-004';
              'sub-003_ses-006';
              'sub-003_ses-008'};

% Preallocate structures
subject = struct('name',      repmat({name}, num_sessions, 1), ...
                 'sesname',   cell(num_sessions, 1), ...
                 'sublabel',  repmat({sublabel}, num_sessions, 1), ...
                 'seslabel',  cell(num_sessions, 1), ...
                 'sesdir',    cell(num_sessions, 1), ...
                 'dataset',   cell(num_sessions, 1), ...
                 'emptyroom', cell(num_sessions, 1), ...
                 'mri',       cell(num_sessions, 1), ...
                 'presentation', cell(num_sessions, 1), ...
                 'beh',       cell(num_sessions, 1), ...
                 'polhemus',  cell(num_sessions, 1), ...
                 'preproc',   cell(num_sessions, 1), ...
                 'preproc_repeats', cell(num_sessions, 1), ...
                 'sourcedata', cell(num_sessions, 1), ...
                 'sourcedata_repeats', cell(num_sessions, 1), ...
                 'hasexcept',  cell(num_sessions, 1), ...
                 'audiofiles',cell(num_sessions, 1), ...
                 'trl',       cell(num_sessions, 1), ...
                 'trl_noise', cell(num_sessions, 1), ...
                 'artfctdef', cell(num_sessions, 1), ...
                 'artfctdef2', cell(num_sessions, 1), ...
                 'selchans',  cell(num_sessions, 1), ...
                 'ica',       cell(num_sessions, 1), ...
                 'anatomy',   cell(num_sessions, 1));

% Session loop
for k = 1:numel(sessions)
    
   seslabel = sessions(k).name;   % ses-001 etc
   sespath  = sessions(k).folder; % path to sub-000 etc.
   sesname  = split(seslabel, '-');  %this is redundant, remove at some point
   sesname  = sprintf('%02s', strip(sesname{2}, '0'));
   
   fprintf('Loading %s info for session %s...\n', sublabel, seslabel); 
   
   % Create main subdir paths in /sub-XXX/ses-XXX
   megdir  = fullfile(sespath, seslabel, 'meg');
   mridir  = fullfile(sespath, 'ses-001', 'mri');  % mri are only in ses-001
   behdir  = fullfile(sespath, seslabel, 'beh');
   polydir = fullfile(sespath, seslabel, 'polhemus');
   
   % List target dataset files in direcotries
   dataset  = dir(fullfile(megdir, '*.ds'));     % meg .ds file
   polydata = dir(fullfile(polydir, '*.pos'));   % polhemus file
   behdata  = dir(fullfile(behdir, '*beh.txt')); % behavioral logs
   presdata  = dir(fullfile(behdir, '*.log')); % raw presentation logs
   
   subject(k).sesname  = sesname;
   subject(k).seslabel = seslabel;
   
   subnr = regexp(sublabel, '-', 'split');
   sesnr = regexp(seslabel, '-', 'split');
   subject(k).subnr = str2double(subnr{2});
   subject(k).sesnr = str2double(sesnr{2});
   
   subject(k).sesdir   = fullfile(sespath, seslabel);
   
   % find preproc files
   preprocpath  = fullfile(d.derived, sublabel, seslabel, 'meg');
   preprocfiles = dir(preprocpath);
   preprocsel   = contains({preprocfiles.name}, {sprintf('%02d-%02d_preproc_1-40.mat', ...
                                                         subject(k).subnr, ...
                                                         subject(k).sesnr)});
   preprocsel_repeats = contains({preprocfiles.name}, {sprintf('%02d-%02d_repeats_preproc_1-40.mat', ...
                                                         subject(k).subnr, ...
                                                         subject(k).sesnr)});
   megpreproc   = preprocfiles(preprocsel);
   megpreproc_repeats = preprocfiles(preprocsel_repeats);
   
   source_suffix = '*_lcmv-data_1-40.mat';
   source_suffix_repeats = '*_lcmv-data_repeats_1-40.mat';
   if ~strcmp(seslabel, 'ses-001')
     source_suffix = '*_lcmv-data_1_40_align.mat';
     source_suffix_repeats = '*_lcmv-data_repeats_1-40_align.mat';
   end
   
   sourcedata  = dir(fullfile(preprocpath, source_suffix)); % raw presentation logs
   sourcedata_repeats  = dir(fullfile(preprocpath, source_suffix_repeats)); % raw presentation logs

    % subject-specific MRI images
    switch sublabel
        case 'pil-001'
            subject(k).mri = 'put .IMA filename here';
        case 'pil-002'
            subject(k).mri = fullfile(mridir, ...
                'PILOT_HAGGORT.MR.KRIARM_SKYRA.0010.0208.2019.04.11.09.36.04.649721.547295652.IMA');
        case 'sub-001'
            subject(k).mri = fullfile(mridir, ...
            '3011000_01_SUB-X001_SES-01.MR.KRIARM_SKYRA.0004.0208.2019.04.15.09.00.03.6033.555503000.IMA');
        case 'sub-002'
            subject(k).mri = fullfile(mridir, ...
                '3011000_01_SUB-20190417T120000_SES-01.MR.KRIARM_SKYRA.0003.0208.2019.04.17.16.02.33.28486.559045052.IMA');
        case 'sub-003'
            subject(k).mri = fullfile(mridir, ...
                '3011000_01_SUB-X001_SES-01.MR.KRIARM_SKYRA.0003.0208.2019.04.18.16.43.54.345453.561570276.IMA');
    end
   
   % check if it needs special preproc due to drifts
   subject(k).hasexcept = ismember([subject(k).sublabel '_' subject(k).seslabel], ...
                                  exceptions);
   
   % add log files contigent on dataset existence
   if ~isempty(dataset)
       
       % find the right filenames
       taskds  = contains({dataset.name}, 'task-compr');
       emptyds = contains({dataset.name}, 'emptyroom');
       
       % if the dataset is not in bids-name, take anythin that does not have
       % 'empty-room' in the filename
       if ~any(taskds)
         taskds = ~emptyds;
       end
       
       subject(k).dataset  = fullfile(dataset(taskds).folder, dataset(taskds).name);
       if strcmp(sublabel, 'pil-001')
           subject(k).emptyroom = [];
       else
        subject(k).emptyroom = fullfile(dataset(emptyds).folder, dataset(emptyds).name);
       end
       subject(k).polhemus = fullfile(polydir, polydata.name);
       subject(k).beh      = fullfile(behdir, behdata.name);
       if numel(presdata)<=1
         subject(k).presentation = fullfile(behdir, presdata.name);
       else
         % JM: there is one session that has more than 1 presentation file,
         % sub-003, ses-008
         for kk = 1:numel(presdata)
           subject(k).presentation{kk} = fullfile(behdir, presdata(kk).name);
         end
       end
       
    if ~isempty(megpreproc)
        subject(k).preproc = fullfile(megpreproc.folder, megpreproc.name);
    else
        subject(k).preproc = [];
    end
    
    % see if noise ceiling data are preprocessed
    if ~isempty(megpreproc_repeats)
        subject(k).preproc_repeats = fullfile(megpreproc_repeats.folder, megpreproc_repeats.name);
    else
        subject(k).preproc_repeats = [];
    end
    
    if ~isempty(sourcedata)
        subject(k).sourcedata = fullfile(sourcedata.folder, sourcedata.name);
    else
        subject(k).sourcedata = [];
    end

    % find source reconstructed data for noise ceiling
    if ~isempty(sourcedata_repeats)
        subject(k).sourcedata_repeats = fullfile(sourcedata_repeats.folder, sourcedata_repeats.name);
    else
        subject(k).sourcedata_repeats = [];
    end

    
    % construct trigger codes (X0 - onset, X5 - offset)
    codes = (1:9)*10;
    task_codes = [codes codes + 5]; % story codes
    noise_codes = [100 150];        % codes for noise ceiling recording
    
    % task trial definition
    trlname = fullfile(preprocpath, 'trl.mat'); 
    if exist(trlname, 'file')

        load(trlname)
        subject(k).trl = trl;

    elseif ~isempty(subject(k).dataset)

        % create trl struct containtin trial definitions
        fprintf('Creating %s for subject %s session %s \n\n', 'trl.mat', name, seslabel);
        trl                = dm_definetrial(subject(k).dataset, task_codes);
        subject(k).trl = trl;

        save(trlname, 'trl');

    end

    % noise ceiling definition
    
    trlname = fullfile(preprocpath, 'trl_noise.mat'); 
    if exist(trlname, 'file') && ~strcmp(sublabel, 'pil-001')

        load(trlname, 'trl');
        subject(k).trl_noise = trl;

    elseif ~isempty(subject(k).dataset) && ~strcmp(sublabel, 'pil-001')

        % create trl struct containtin trial definitions
        fprintf('Creating %s for subject %s session %s \n\n', 'trl_noise.mat', name, seslabel);
        trl                = dm_definetrial(subject(k).dataset, noise_codes);
        
        % redefine the event codes here; code in 4th column as individual events
        trl(:, 5) = trl(:, 4);       % copy run ID to 5th column
        trl(:, 4) = 1:size(trl, 1);  % unique ID for every row (= event)
        
        subject(k).trl_noise = trl;

        save(trlname, 'trl');

    end
    
    % Determine which audiofiles were actually used
    stiminfo   = dm_stiminfo(); 
    audiofiles = stiminfo.audiofiles(ismember(stiminfo.seslabel, seslabel));
    
    % select only wavefiles for which there is a .trl value
    subject(k).audiofiles = audiofiles(subject(k).trl(:, 4));
    subject(k).audiofiles_repeats = repmat({fullfile(d.stim, 'noise_ceiling.wav')}, size(subject(k).trl_noise, 1), 1);
    
    % Squid jumps
    squidname  = fullfile(preprocpath, 'squid.mat');
    if exist(squidname, 'file')
       load(squidname)              % 'cfg' variable
       subject(k).artfctdef.jump = cfg.artfctdef.zvalue;
    else
       fprintf('Creating squidjump definition for subject %s session %d \n\n', name, k);
       cfg                        = dm_artifact_squidjumps(subject(k).dataset, ...
                                                           subject(k).trl);
       subject(k).artfctdef.jump = cfg.artfctdef.zvalue; 
       save(squidname, 'cfg');
    end
    
     % Squid jumps for repeats
    squidname  = fullfile(preprocpath, 'squid_repeats.mat');
    if exist(squidname, 'file')
       load(squidname, 'cfg');              % 'cfg' variable
       subject(k).artfctdef2.jump = cfg.artfctdef.zvalue;
    else
       fprintf('Creating repeats squidjump definition for subject %s session %d \n\n', name, k);
       cfg                        = dm_artifact_squidjumps(subject(k).dataset, ...
                                                           subject(k).trl_noise);
       subject(k).artfctdef2.jump = cfg.artfctdef.zvalue; 
       save(squidname, 'cfg');
    end
    
    % Muscle artifacts
    musclename = fullfile(preprocpath, 'muscle.mat');
    if exist(musclename, 'file')
       load(musclename, 'cfg');           % 'cfg' variable
       subject(k).artfctdef.muscle  = cfg.artfctdef.zvalue;
    else
       fprintf('Creating muscle definition for subject %s session %d \n', name, k);
       cfg                         = dm_artifact_muscle(subject(k).dataset, ...
                                                        subject(k).trl);
       subject(k).artfctdef.muscle = cfg.artfctdef.zvalue; 
       save(musclename, 'cfg');
    end
    
    % Muscle artifacts for repeats
    musclename  = fullfile(preprocpath, 'muscle_repeats.mat');
    if exist(musclename, 'file')
       load(musclename, 'cfg');              % 'cfg' variable
       subject(k).artfctdef2.muscle = cfg.artfctdef.zvalue;
    else
       fprintf('Creating repeats muscle definition for subject %s session %d \n\n', name, k);
       cfg                        = dm_artifact_muscle(subject(k).dataset, ...
                                                           subject(k).trl_noise);
       subject(k).artfctdef2.muscle = cfg.artfctdef.zvalue; 
       save(musclename, 'cfg');
    end
    
    % Check channel quality
    channame = fullfile(preprocpath, 'chansel.mat');
    if exist(channame, 'file')
        load(channame)
        subject(k).selchans = chansel;
    else
        warning('Channel quality check for subject %s session %s not performed yet', name, seslabel);
        %fprintf('Doing channel quality check for subject %s session %s\n', name, seslabel);
        %seltrl = 1:size(subject(k).trl, 1);
        %[selchan, artf] = dm_dataQC(subject(k), seltrl);
        %subject(k).selchans = selchan; clear selchan;
        %if ~isempty(artf)
        %    subject(k).artfctdef.visual = artf.artfctdef.visual;
        %end
    end
    
    % Get eye-blink ICA components
    icaname = fullfile(preprocpath, 'comp.mat');
    if exist(icaname, 'file')
        subject(k).ica.comp = icaname;
    elseif exist(channame, 'file')
        warning('ICA for subject %s session %s not performed yet', name, seslabel);
        %comp = dm_artifact_eye(subject(k));
        %subject(k).ica.comp = comp;
        %save(icaname, 'comp');
    else
        warning('Skipping ICA. Check data quality first.');
    end
    
    % Load component selection if it exists
    selcompname = fullfile(preprocpath, 'selcomp.mat');
    if exist(selcompname, 'file')
        load(selcompname) 
        subject(k).ica.selcomp = selcomp;  % chapter-specific estimates per story
    else
        warning('ICA components not selected yet for %s session %s', name, seslabel);
        subject(k).ica.selcomp    = [];
    end
    
    % Audiodelay
    delayname = fullfile(preprocpath, 'audiodelay.mat');
    if exist(delayname, 'file')
        load(delayname)
        subject(k).audiodelay = delay;
    else
        fprintf('Computing audiodelay for subject %s session %s \n\n', name, seslabel)
        delay                 = dm_audiodelay(subject(k), 'non-repeats');
        subject(k).audiodelay = delay;
        save(delayname, 'delay');
    end
    
    % Audiodelay for repeats
    delayname = fullfile(preprocpath, 'audiodelay_repeats.mat');
    if exist(delayname, 'file')
        load(delayname)
        subject(k).audiodelay_repeats = delay;
    else
        fprintf('Computing audiodelay for subject %s session %s \n\n', name, seslabel)
        delay                 = dm_audiodelay(subject(k), 'repeats');
        subject(k).audiodelay_repeats = delay;
        save(delayname, 'delay');
    end
    
    % Update offset column in .trl and .trl_noise
    subject(k).trl(:, 3) = -round(subject(k).audiodelay.*(1200/1000));
    subject(k).trl_noise(:, 3) = -round(subject(k).audiodelay_repeats.*(1200/1000));
    
    % Add session information column to .trl
    sesinfo    = zeros(size(subject(k).trl, 1), 1);
    sesnum     = strsplit(seslabel, '-');          % retain '002' etc.
    sesnum     = str2double(sesnum{2});
    sesinfo(:) = sesnum;
    
    subject(k).trl = [subject(k).trl, sesinfo];
   end
   
    % Add anatomy information for subject (/anatomy only present in ses-001)
    anatomypath = fullfile(d.derived, sublabel, 'ses-001', 'anatomy');
    subject(k).anatomy.headmodel   = fullfile(anatomypath, [subject(k).sublabel '_headmodel.mat']); 
    subject(k).anatomy.sourcemodel = fullfile(anatomypath, [subject(k).sublabel '_sourcemodel.mat']);
    subject(k).anatomy.leadfield   = fullfile(anatomypath, [subject(k).sublabel '_leadfield.mat']);
   
    % Add word onset info if recording already took place
    if ~isempty(dataset) && ~isempty(subject(k).preproc)
    
        pref        = [num2str(subject(k).subnr) '-' num2str(subject(k).sesnr)];
        fname       = '_words.mat';
        featuretime = fullfile(d.derived, subject(k).sublabel, subject(k).seslabel, 'meg', [pref fname]);

        if ~exist(featuretime, 'file')
            dm_create_featuretime(subject(k), 'word');
            %warning('%s not created yet', featuretime);
        end
        subject(k).feature{1} = featuretime;


        % Add phone info
        fname       = '_phones.mat';
        featuretime = fullfile(d.derived, subject(k).sublabel, subject(k).seslabel, 'meg', [pref fname]);
        if ~exist(featuretime, 'file')
            dm_create_featuretime(subject(k), 'phone');
            %warning('%s not created yet', featuretime);
        end
        subject(k).feature{2} = featuretime;
    end
    
end

end


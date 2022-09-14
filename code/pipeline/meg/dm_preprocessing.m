function [data, audio] = dm_preprocessing(inpcfg, subject)

% Get commonly used directory strings
d = dm_dir;

%% Initialize input options

% Sessions to preprocess, default = all
session    = ft_getopt(inpcfg, 'session');

doaudio    = ft_getopt(inpcfg, 'doaudio', 0);
doenvelope = ft_getopt(inpcfg, 'doenvelope', 0);
dorepeats = ft_getopt(inpcfg, 'dorepeats', 0);

% Filter specifications (default: don't filter except notch)
usehpfilter = ft_getopt(inpcfg, 'usehpfilter', 0); % high-pass
hpfreq      = ft_getopt(inpcfg, 'hpfreq', 0);      
usebpfilter = ft_getopt(inpcfg, 'usebpfilter', 0); % band-pass
bpfreq      = ft_getopt(inpcfg, 'bpfreq', 0);
uselpfilter = ft_getopt(inpcfg, 'uselpfilter', 0); % low-pass
lpfreq      = ft_getopt(inpcfg, 'lpfreq', 0);
usebsfilter = ft_getopt(inpcfg, 'usebsfilter', 1); % notch filter
bsfreq      = ft_getopt(inpcfg, 'bsfreq', [49 51; 99 101; 149 151]);
dohilbert   = ft_getopt(inpcfg, 'dohilbert', 0);
removeics   = ft_getopt(inpcfg, 'removeics', 1);
getchannel  = ft_getopt(inpcfg, 'channel', '');
fsample     = ft_getopt(inpcfg, 'fsample', 150);
dosave      = ft_getopt(inpcfg, 'dosave', 0);
megsuffix   = ft_getopt(inpcfg, 'megsuffix');
edgepadding = ft_getopt(inpcfg, 'edgepadding', 1);

% Choose session if specified
subject   = dm_subjinfo(subject, session);

%% Run the preprocessing loop over sessions per subject
for k = 1:numel(subject) % numel(subject) == number of sessions
    
    % Select subject data for current session
    subjecttmp = subject(k);
    
    % If there were bad channels in the session, add their labels in <channels> cell array
    if ~isempty(subjecttmp.selchans.bad) && ~isequal(getchannel, '')
        channels    = cell(numel(subjecttmp.selchans.bad)+1, 1);
        channels{1} = 'MEG';
        for j = 1:numel(subjecttmp.selchans.bad)
            channels{j + 1} = ['-' subjecttmp.selchans.bad{j}]; % '-MXXXX'
        end
    else % If no bad channels, process all MEG channels
        channels = getchannel;
    end
    
    % set trial, audiodile and audiodelay definition based on which trials we're preprocessing
    trl        = subjecttmp.trl;
    audiofiles = subjecttmp.audiofiles;
    audiodelay = subjecttmp.audiodelay;
    
    if dorepeats
      trl        = subjecttmp.trl_noise;
      audiofiles = subjecttmp.audiofiles_repeats;
      audiodelay = subjecttmp.audiodelay_repeats;
    end
    
    cfg            = [];
    cfg.dataset    = subjecttmp.dataset;
    cfg.trl        = trl;
    cfg.trl(:, 1)  = trl(:, 1) - edgepadding.*1200; % read in an extra second of data at the beginning
    cfg.trl(:, 2)  = trl(:, 2) + edgepadding.*1200; % read in an extra second of data at the end
    
    % ==== FIXME ====
    % this third .trl column was fixed as in
    % https://github.com/KristijanArmeni/Deep-MEG/commit/6f4dfd311b164e8a78701af0282136b0c6961ee4 
    % it was only applied to repeated snippets ('_repeats_'), but not to real
    % narrative data, those need to be recomputed with this fixed version
    
    cfg.trl(:, 3)  = trl(:, 3) - edgepadding.*1200; % update the offset, to account for the padding
    
    % ==== FIXME =====
    
    cfg.channel    = channels;
    cfg.continuous = 'yes';
    cfg.demean     = 'yes';
    
      % specify bandpas
    if usebpfilter
        cfg.bpfilter   = 'yes';
        cfg.bpfreq     = bpfreq;
        cfg.bpfilttype = 'firws';
        cfg.usefftfilt = 'yes';
    end
  
    % specfy high pass
    if usehpfilter
        cfg.hpfilter   = 'yes';
        cfg.hpfreq     = hpfreq;
        cfg.hpfilttype = 'firws';
        cfg.usefftfilt = 'yes';
    end
        
    data        = ft_preprocessing(cfg);

    trl_orig = data.cfg.trl;  % store original trial definition
    
    % Preprocess audio if required
    if doaudio
        % Turn off filtering for audio
        cfg.bpfilter = 'no';
        cfg.hpfilter = 'no';
        cfg.channel  = 'UADC003';
        audio        = ft_preprocessing(cfg);
    end
    
    % Compute audio envelope if required
    if doenvelope
    
    audioorig = audio; clear audio % store <audio> as <audioorig> due to other <audio> var below
        
        for kk = 1:size(data.trialinfo, 1)
          
          % use a boolean based on actual trl values (in case any of those are dropped)
          seltrl     = ismember(trl(:, 4), trl(kk, 4));  
          
          % for repeated snippets it can just be linear index as the same
          % audiofile is used for all trials
          if dorepeats
            seltrl = false(size(trl, 1), 1);
            seltrl(kk) = 1;
          end
          
          % Select audio for a single trial (story) corresponding to wavfile
          cfg        = [];
          cfg.trials = seltrl;
          audioacq   = ft_selectdata(cfg, audioorig);
          
          % Get correct wavfile (just replace the suffix, this assumes that
          % .audiofiles lists stimulus files which are aligned with trials. which is done
          % in dm_subjinfo: subject(k).audiofiles = audiofiles(subject(k).trl(:, 4));
          wavfile = strrep(audiofiles{seltrl}, '.wav', '.mat'); % stimulus wavfile   
          
          if exist(wavfile, 'file')
            load(wavfile, 'audio');           % new <audio> variable 
            audiowave = audio; clear audio
          end
          
          % Add precomputed audio envelope
          audioout{kk} = dm_add_envelope_delay(audioacq, audiowave);
    
        end
        
        audio = ft_appenddata([], audioout{:});
        clear seltrl audioout
        
    end
    
    % Notch filtering for MEG if specified
    if usebsfilter
    cfg          = [];
    cfg.bsfilter = 'yes';
        for kk = 1:size(bsfreq, 1)
            cfg.bsfreq = bsfreq(kk, :);
            data       = ft_preprocessing(cfg, data);
        end
    end
    
    timeaxis_orig = data.time;
    if doaudio
      timeaxis_orig_audio = audio.time;
    end
    
    % assign artifact defintion to a separate variable
    artfctdef = subjecttmp.artfctdef;
    
    % use the correct artifact definition field for noise ceiling trials
    if dorepeats
      artfctdef = subjecttmp.artfctdef2;
    end
    
    % Cut out muscle and squid artifacts (such that there are no nans in the input)
    cfg                        = [];
    cfg.artfctdef              = artfctdef;
    cfg.artfctdef.reject       = 'partial';
    cfg.artfctdef.minaccepttim = 2;
    data                       = ft_rejectartifact(cfg, data);
    if doaudio
       audio = ft_rejectartifact(cfg, audio); 
    end
    
    trl_partial = data.cfg.trl; % store trl definition after artifact rejection
    
    % demean  (ft_preprocessing)
    cfg = [];
    cfg.demean = 'yes';
    data = ft_preprocessing(cfg, data);

    % reconstruct the trial structure
    cfg = [];
    cfg.trl = trl_orig;
    data = ft_redefinetrial(cfg, data);
    if doaudio
        audio = ft_redefinetrial(cfg, audio);
    end
    
    if removeics
      % Remove eye-blink components
      fprintf('Removing ICA components for session %s, ...\n', subjecttmp.seslabel);
      
      ica = load(subjecttmp.ica.comp);
      
      cfg            = [];
      cfg.component  = sort([subjecttmp.ica.selcomp.eye, subjecttmp.ica.selcomp.heart]); % select badcomponents for this story
      cfg.updatesens = 'no';
      data   = ft_rejectcomponent(cfg, ica.comp, data);
    end
    
    % Do low-pass filtering if specified
    if uselpfilter
        cfg            = [];
        cfg.lpfreq     = lpfreq;
        cfg.lpfilter   = 'yes';
        cfg.lpfilttype = 'firws';
        cfg.usefftfilt = 'yes';
        data           = ft_preprocessing(cfg, data);
    end
    
    if dohilbert
        cfg            = [];
        cfg.hilbert    = 'complex';
        data           = ft_preprocessing(cfg, data);
    end
    
    % Downsample
    if fsample < 1200
    
        % first remove nans from the data (use the artifact trl definition)
        cfg = [];
        cfg.trl = trl_partial;
        data = ft_redefinetrial(cfg, data);
        
        trlinfoorig = data.trialinfo;
        
        data = dm_resample(data, timeaxis_orig, fsample);
        
        if doaudio
            audio = ft_redefinetrial(cfg, audio);
            audio = dm_resample(audio, timeaxis_orig_audio, fsample);
        end
        
        % check that the unique values in the first column of original trilinfo matches the one
        % created in dm_resample()
        assert(isequal(data.trialinfo', unique(trlinfoorig(:, 1))));
        % then, put original trial information back in -> JM Note: this
        % makes the trialinfo inconstent with the data.trial!
        data.trialinfo = trlinfoorig;
        
    end
    
    % Optionaly save
    if dosave
        
      subid = strsplit(subjecttmp.sublabel, '-');
      sesid = strsplit(subjecttmp.seslabel, '-');

      subid = sprintf('%02d', str2double(subid{2}));
      sesid = sprintf('%02d', str2double(sesid{2}));

      savename = fullfile(d.derived, subjecttmp.sublabel, subjecttmp.seslabel, 'meg', ...
                          [['s' subid] '-' sesid '_' megsuffix]);
      
      % make sure file name is different
      if dorepeats
        savename = fullfile(d.derived, subjecttmp.sublabel, subjecttmp.seslabel, 'meg', ...
                          [['s' subid] '-' sesid '_' 'repeats_'  megsuffix]);
      end
      
      %save(savename, 'data');


      if exist('audio', 'var')
          savename2 = fullfile(d.derived, subjecttmp.sublabel, subjecttmp.seslabel, 'meg', ...
                               ['s' subid '-' sesid '_audio.mat']);
          
          % make sure filename is different
          if dorepeats
            savename2 = strrep(savename2, '_audio.mat', '_repeats_audio.mat');
          end
          
          %save(savename2, 'audio');
      end

    end
    
    if numel(subject)>1
        % Clear subjecttmp variable before next loop
        clear subjecttmp data audio
    end
    
end
    
end
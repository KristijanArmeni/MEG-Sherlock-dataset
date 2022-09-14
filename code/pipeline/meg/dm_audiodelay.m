function delay = dm_audiodelay(subject, which, audiofile, trial)

% DM_AUDIODELAY computes the delay between the actual sending of the
% trigger and the onset of the audio based on the slope of the phase
% difference spectrum.
%
%   USE AS
%   [delay, audiofiles] = dm_audiodelay(subject, which, audiofile, trl)
%
%
%
%   INPUT ARGS
%   subject   = struct, as obtained form dm_subjinfo()
%   which     = string, 'repeats' or 'non-repeats' indicating whether to align
%               stimulus files or noise ceiling recordings
%   audiofile = string, indicating audiofile to be aligned
%   trial     = matrix, row from cfg.trl indicating the trial correspodning to the
%               selected audiofile

d = dm_dir;

% if no audiofile is specified, loop over all trials
if nargin == 2
    
    if strcmp(which, 'repeats')
      trl = subject.trl_noise;
      delay = zeros(size(trl, 1), 1);
      audiofiles = subject.audiofiles_repeats;
    elseif strcmp(which, 'non-repeats')
      trl = subject.trl;
      delay = zeros(size(trl, 1), 1);
      audiofiles = subject.audiofiles;
    end
      
    % Loop over audiofiles/trials
    for k = 1:numel(audiofiles)
        
      fprintf('\ncomputing audio delay for subject %s session %s file %s, run %d\n', ...
               subject.name, ...
               subject.seslabel, ...
               audiofiles{k},...
               trl(k, end));
             
      if iscell(subject.dataset)
        % data is in more than one file
        error('There are several datasets per session, this chunk of code needs to be checked');
        ntrlperdataset = cellfun('size',trl,1);
        indx           = zeros(0,2);
        cnt            = 0;
        for m = 1:numel(ntrlperdataset)
          indx(cnt+(1:ntrlperdataset(m)),1) = m;
          indx(cnt+(1:ntrlperdataset(m)),2) = 1:ntrlperdataset(m);
          cnt = size(indx,1);
        end
        tmpsubject          = subject;
        tmpsubject.dataset  = subject.dataset{indx(k,1)};
        tmptrl      = nan+zeros(numel(audiofiles),4);
        tmptrl(k,:) = trl{indx(k,1)}(indx(k,2),:);
        delay(k,1)          = dm_audiodelay(tmpsubject, which, audiofiles{k}, tmptrl(k, :));
      else
        
        if strcmp(which, 'non-repeats')
          % if non-repeat, pick trial based on string matching
          % in case trials have beend dropped
          trial = trl(strcmp(audiofiles, audiofiles{k}), :);
        elseif strcmp(which, 'repeats')
          % in case of repeats, audio and trial don't need to be matched
          % as it it the same audiofile is used for all trials
          trial = trl(k, :);
        end
        
        % normal case
        delay(k,1) = dm_audiodelay(subject, which, audiofiles{k}, trial);
      end
    end

    return;
end

% Read in audio channels from MEG
cfg = [];
cfg.dataset    = subject.dataset;
cfg.trl        = trial;
cfg.channel    = {'UADC003'};
cfg.continuous = 'yes';
cfg.bsfilter   = 'yes';
cfg.bsfreq     = [49 51;99 101;149 151;199 201];
data           = ft_preprocessing(cfg);

% Read in downsampled audio .mat file ('audio' variable)
[~, f, ~]      = fileparts(audiofile);
matfile        = fullfile(d.stim, [f '.mat']);
load(matfile);

cfg         = [];
cfg.channel = audio.label{1};
audio       = ft_selectdata(cfg, audio);

% deal with the exception that the recording was started after the audio
% presentation
if isequal(subject.subnr,3) && isequal(subject.sesnr,1)
  audioorig = audio; % just to be able to check
  
  % recording was started too late, about 8.5 s, so longer length needed
  offset = audio.time{1}(8400);
  audio.time{1} = audio.time{1}(8400:end)-offset;
  audio.trial{1} = audio.trial{1}(8400:end);
end

% Ensure the time axis has the same number of samples
nsmp1 = numel(audio.time{1});
nsmp2 = numel(data.time{1});
nsmp  = min(nsmp1,nsmp2);

% Data time axis has more samples, adjust
audio.time{1} = data.time{1}(1:nsmp);

audio.trial{1} = audio.trial{1}(:,1:nsmp);
audio.time{1}  = audio.time{1}(1:nsmp);
data.trial{1}  = data.trial{1}(:,1:nsmp);
data.time{1}   = data.time{1}(1:nsmp);

cfg                = [];
cfg.keepsampleinfo = 'no';
data = ft_channelnormalise([], ft_appenddata(cfg, data, audio));


% redefine
length_seg  = 10;
cfg         =  [];
cfg.length  = length_seg;
cfg.overlap = 0;
data        = ft_redefinetrial(cfg, data);

% spectral analysis
cfg            = [];
cfg.method     = 'mtmfft';
cfg.output     = 'powandcsd';
cfg.tapsmofrq  = 1;
cfg.channelcmb = {'all' 'all'};
freq           = ft_freqanalysis(cfg, data);

% compute coherence
cfg         = [];
cfg.method  = 'coh';
cfg.complex = 'complex';
coh         = ft_connectivityanalysis(cfg, freq);
phi         = unwrap(angle(coh.cohspctrm));

f1     = nearest(freq.freq,150);
f2     = nearest(freq.freq,250);
X      = [ones(1,f2-f1+1);freq.freq(f1:f2)];
X(2,:) = X(2,:)-mean(X(2,:));
beta   = phi(:,f1:f2)/X;
  
delay  = beta(:,2)*1000./(2*pi);
if isequal(subject.subnr,3) && isequal(subject.sesnr,1)
  % recording was started too late, about 8.5 s, so longer length needed
  delay = delay - offset*1000;
  
  audioorig = ft_channelnormalise([], audioorig);
  figure;plot(data.time{1},data.trial{1}(1,:)+2);
  hold on;plot(audioorig.time{1}(1:24000)+delay./1000, audioorig.trial{1}(1:24000));
end


end

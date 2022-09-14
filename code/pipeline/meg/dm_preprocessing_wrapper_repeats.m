function dm_preprocessing_wrapper_repeats(sub, ses, cfg)

% written by JM to run a bunch of sessions' preprocessing efficiently on the cluster

datadir = '/project/3011085.05/jansch/';

if nargin<3
  % specify the preprocessing cfg if not specified outside
  cfg             = [];
  cfg.usehpfilter = 1;
  cfg.hpfreq      = 1;
  cfg.usebsfilter = 1;
  cfg.bsfreq      = [49 51];
  cfg.uselpfilter = 1;
  cfg.lpfreq      = 30;
  cfg.fsample     = 120;
  cfg.dohilbert   = 0;
  cfg.removeics   = 1;
  cfg.doaudio     = 1;
  cfg.doenvelope  = 1;
  cfg.dorepeats   = true;
  cfg.channel     = 'MEG';
  cfg.edgepadding = 0.5; % needed to avoid ft_fetch_data error in ft_rejectartifact if repeats are too closely spaced
end

session   = sprintf('ses-%03d',ses);
cfg.session   = session;
[data,audio]  = dm_preprocessing(cfg, sub);

for k = 1:numel(data.trial)
  audio.trial{k} = audio.trial{k} - nanmean(audio.trial{k},2);
end

data  = ft_struct2single(data);
audio = ft_struct2single(audio);

fname = fullfile(datadir, sprintf('%s_%s_repeats',sub,session));
save(fname, 'data', 'audio');


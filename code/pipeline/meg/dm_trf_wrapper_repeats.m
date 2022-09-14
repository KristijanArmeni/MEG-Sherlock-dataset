function dm_trf_wrapper_repeats(sub, ses, cfg)

% written by JM to run a bunch of sessions' preprocessing+trf on the cluster

datadir = '/project/3011085.05/jansch';
if nargin<3
  cfg             = [];
  cfg.usehpfilter = 1;
  cfg.hpfreq      = 1;
  cfg.usebsfilter = 0;
  %cfg.bsfreq      = [49 51];
  cfg.uselpfilter = 1;
  cfg.lpfreq      = 30;
  cfg.fsample     = 300;
  cfg.dohilbert   = 0;
  cfg.removeics   = 1;%0
  cfg.doaudio     = 1;
  cfg.doenvelope  = 1;
  cfg.dorepeats   = true;
  cfg.channel     = 'MEG';
  cfg.edgepadding = 0.5;
end

session       = sprintf('ses-%03d',ses);
cfg.session   = session;
[data,audio]  = dm_preprocessing(cfg, sub);

for k = 1:numel(data.trial)
  audio.trial{k} = audio.trial{k} - nanmean(audio.trial{k},2);
end

data  = ft_struct2single(data);
audio = ft_struct2single(audio);

dt      = 1./data.fsample;
reflags = [-flip(dt:dt:0.1) 0:dt:0.8];

% build the cfg for the ridge regression
cfg             = [];
cfg.method      = 'mlrridge';
cfg.performance = 'r-squared';
cfg.channel     = 'MEG';
cfg.standardisedata = 1;
cfg.demeandata      = 1;
cfg.standardiserefdata = 1;
cfg.demeanrefdata   = 1;
cfg.reflags         = reflags; 
cfg.refchannel      = 'audio_avg'; 
cfg.threshold       = [5 0];
cfg.testtrials      = mat2cell(1:numel(data.trial),1,ones(1,numel(data.trial)));
trf = ft_denoise_tsr(cfg, data, audio);

label = trf.label;
cfg_trf = trf.cfg;
grad  = data.grad;
trf = trf.weights;
for k = 1:numel(trf)
  trf(k).label = label;
end

fname = fullfile(datadir, sprintf('%s_%s_trf_repeats',sub,session));
save(fname, 'trf', 'cfg_trf', 'grad');


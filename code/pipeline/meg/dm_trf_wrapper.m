function dm_trf_wrapper(sub, ses, cfg)

% written by JM to run a bunch of sessions' preprocessing+trf on the cluster

datadir = '/project/3011085.05/jansch';
if nargin<3
  cfg             = [];
  cfg.usehpfilter = 1;
  cfg.hpfreq      = 0.5;
  cfg.usebsfilter = 0;
  %cfg.bsfreq      = [49 51];
  cfg.uselpfilter = 1;
  cfg.lpfreq      = 30;
  cfg.fsample     = 120;
  cfg.dohilbert   = 0;
  cfg.removeics   = 1;%0;
  cfg.doaudio     = 1;
  cfg.doenvelope  = 1;
  cfg.channel     = 'MEG';
end

session       = sprintf('ses-%03d',ses);
cfg.session   = session;
[data,audio]  = dm_preprocessing(cfg, sub);


for k = 1:numel(data.trial)
  %data.trial{k} = ft_preproc_hilbert(data.trial{k},[],true,100);
  %data.trial{k} = ft_preproc_lowpassfilter(data.trial{k},1200,30,[],'firws');
  audio.trial{k} = audio.trial{k} - nanmean(audio.trial{k},2);
end

% cfg = [];
% cfg.resamplefs = 120;
% data  = ft_resampledata(cfg, data);
% audio = ft_resampledata(cfg, audio);

data  = ft_struct2single(data);
audio = ft_struct2single(audio);
audio = dm_wordonsets(audio, ses);

dt      = 1./data.fsample;
reflags = [-flip(dt:dt:0.05) 0:dt:0.8];

% build the cfg for the ridge regression
cfg             = [];
cfg.method      = 'mlrridge';
cfg.performance = 'r-squared';
cfg.channel     = 'MEG';
cfg.standardisedata = 1;
cfg.demeandata      = 1;
cfg.standardiserefdata = 1;
cfg.demeanrefdata   = 0; %-> do this for the audio (l.29), but not for the word onset regressor
cfg.reflags         = reflags; 
cfg.refchannel      = 'audio_avg'; 
cfg.threshold       = [.5 0];
cfg.testtrials      = mat2cell(1:numel(data.trial),1,ones(1,numel(data.trial)));
trf = ft_denoise_tsr(cfg, data, audio);

cfg.refchannel      = {'audio_avg';'wordonset'};
cfg.threshold       = [0 repmat([.5 0],[1 numel(reflags)])];
trf2 = ft_denoise_tsr(cfg, data, audio);

% run it once more, but now with the same regularisation parameter for both
% regressors
cfg.refchannel      = {'audio_avg';'wordonset'};
cfg.threshold       = [0 repmat([.5 .5],[1 numel(reflags)])];
trf3 = ft_denoise_tsr(cfg, data, audio);

label = trf.label;
cfg_trf = trf.cfg;
grad  = data.grad;
trf = trf.weights;
for k = 1:numel(trf)
  trf(k).label = label;
end

label = trf2.label;
cfg_trf2   = trf2.cfg;
trf2 = trf2.weights;
for k = 1:numel(trf2)
  trf2(k).label = label;
end

label = trf3.label;
cfg_trf3   = trf3.cfg;
trf3 = trf3.weights;
for k = 1:numel(trf3)
  trf3(k).label = label;
end

fname = fullfile(datadir, sprintf('%s_%s_trf',sub,session));
save(fname, 'trf', 'trf2', 'trf3', 'cfg_trf', 'cfg_trf2', 'cfg_trf3', 'grad');


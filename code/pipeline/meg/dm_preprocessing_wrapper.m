function dm_preprocessing_wrapper(sub, ses, cfg)

% written by JM to run a bunch of sessions' preprocessing+trf on the cluster

datadir = '/project/3011085.05/jansch/';
if nargin<3
  cfg             = [];
  cfg.usehpfilter = 1;
  cfg.hpfreq      = 0.5;
  cfg.usebsfilter = 1;
  cfg.bsfreq      = [49 51];
  cfg.uselpfilter = 1;
  cfg.lpfreq      = 30;
  cfg.fsample     = 120;
  cfg.dohilbert   = 0;
  cfg.removeics   = 1;%0;
  cfg.doaudio     = 1;
  cfg.doenvelope  = 1;
  cfg.channel     = 'MEG';
end

session   = sprintf('ses-%03d',ses);
cfg.session   = session;
[data,audio]  = dm_preprocessing(cfg, sub);


data  = ft_struct2single(data);
audio = ft_struct2single(audio);
audio = dm_wordonsets(audio, ses);

fname = fullfile(datadir, sprintf('%s_%s',sub,session));
save(fname, 'data', 'audio');


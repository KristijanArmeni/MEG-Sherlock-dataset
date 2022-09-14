function dm_tlck_wrapper(sub, ses, cfg)

% written by JM to run a bunch of sessions' preprocessing+trf on the cluster

datadir = '/project/3011085.05/jansch';
if nargin<3
  cfg = [];
  cfg.usehpfilter = 1;
  cfg.hpfreq      = 0.5;
  cfg.usebsfilter = 0;
  %cfg.bsfreq      = [49 51];
  cfg.uselpfilter = 1;
  cfg.lpfreq      = 30;
  cfg.fsample     = 120;
  cfg.dohilbert   = 0;
  cfg.removeics   = 0;
  cfg.doaudio     = 1;
  cfg.doenvelope  = 1;
  cfg.channel     = 'MEG'; % this overrides the bad channel definition in dm_preprocessing
end

session   = sprintf('ses-%03d',ses);
cfg.session   = session;
[data,audio]  = dm_preprocessing(cfg, sub);

% shortcut covariance computation, bypassing ft_timelockanalysis
for k = 1:numel(data.trial)
  dat        = data.trial{k};
  dat        = dat - nanmean(dat, 2);
  finitevals = isfinite(dat);
  n          = sum(finitevals,2);
  assert(all(n==n(1)));
  n          = n(1);
  dat(~finitevals) = 0;
  C(k,:,:) = (dat*dat')./(n-1);
  N(1,k)   = (n-1);
end
tlck = keepfields(data, {'grad' 'label'});
tlck.dimord = 'rpt_chan_time';
tlck.time   = 0;
tlck.trial  = zeros([size(C,1) numel(tlck.label) 1]);
tlck.cov    = C;
tlck.dof    = N(:);

audio       = ft_struct2single(audio);

fname = fullfile(datadir, sprintf('%s_%s_tlck',sub, session));
save(fname, 'tlck', 'audio');


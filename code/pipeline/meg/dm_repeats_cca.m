function [rho, perf, noverlap, fnames] = dm_repeats_cca(subj, sess1, sess2, lambda)

if nargin<4
  lambda = 0.5;
end

datadir = '/project/3011085.05/jansch';

fname1 = fullfile(datadir, sprintf('%s_ses-%03d_repeats.mat',subj, sess1));
fname2 = fullfile(datadir, sprintf('%s_ses-%03d_repeats.mat',subj, sess2));
fnames = {fname1 fname2};

load(fname1);
D{1} = data;
A{1} = audio;
N(1) = floor(numel(data.trial)/2);
load(fname2);
D{2} = data;
A{2} = audio;
N(2) = floor(numel(data.trial)/2);
clear data audio;

if isequal(subj, 'sub-003')
  % some of the data has bad channels removed in this subject, so before
  % appending, this should be equalised
  [D{:}] = ft_selectdata([], D{:});
end
data  = ft_appenddata([], D{:});
audio = ft_appenddata([], A{:});

for k = 1:numel(data.trial)
  t1(k,1) = data.time{k}(1);
  t2(k,1) = data.time{k}(end);

  sel = nearest(data.time{k}, [0 29]);
  data.time{k} = data.time{k}(sel(1):sel(2));
  data.trial{k} = data.trial{k}(:,sel(1):sel(2));
  audio.time{k} = audio.time{k}(sel(1):sel(2));
  audio.trial{k} = audio.trial{k}(:,sel(1):sel(2));
end

% build the cfg for the ridge regression
cfg             = [];
cfg.method      = 'ccaridge';
cfg.performance = 'pearson';
cfg.standardisedata = 1;
cfg.demeandata      = 1;
cfg.standardiserefdata = 1;
cfg.demeanrefdata   = 1;
cfg.reflags         = 0;
cfg.threshold       = [lambda lambda];
cfg.perchannel      = false;
cfg.covmethod       = 'overlapfinite';

cfgsel = [];
cfgsel.trials = 1;
tmp = ft_selectdata(cfgsel, data);
tmp.label = [tmp.label; strrep(tmp.label, 'M', 'R')];
cfg.reflags    = 0;
cfg.refchannel = tmp.label((numel(data.label)+1):end);
cfg.channel    = data.label;
cfg.testtrials = {1 2};

cnt = 0;
for kk = 1:N(1)
  for mm = 1:N(2)
    cnt = cnt+1;
    fprintf('computing CCA for combination %d-%d %d/%d\n', kk, mm, cnt, prod(N));
    
    k  = (kk-1)*2+1;
    m  = N(1)*2+(mm-1)*2+1;

    n1 = numel(data.time{k});
    n2 = numel(data.time{m});
    if n1>=n2
      tmp.time{1} = data.time{k};
    else
      tmp.time{1} = data.time{m};
    end
    tmp.trial{1} = nan(numel(tmp.label), max(n1,n2));
    tmp.trial{1}(1:numel(cfg.channel),1:n1) = data.trial{k};
    tmp.trial{1}((numel(cfg.channel)+1):end,1:n2) = data.trial{m};
    
    k = kk*2;
    m = N(1)*2+mm*2;
    
    n1 = numel(data.time{k});
    n2 = numel(data.time{m});
    if n1>=n2
      tmp.time{2} = data.time{k};
    else
      tmp.time{2} = data.time{m};
    end
    tmp.trial{2} = nan(numel(tmp.label), max(n1,n2));
    tmp.trial{2}(1:numel(cfg.channel),1:n1) = data.trial{k};
    tmp.trial{2}((numel(cfg.channel)+1):end,1:n2) = data.trial{m};
    
    x = ft_denoise_tsr(cfg, tmp);
    
    rho(kk,mm,1)  = x.weights(1).rho(1);
    perf(kk,mm,1) = x.weights(1).performance(1);
    noverlap(kk,mm,1) = sum(sum(isfinite(tmp.trial{1}))==numel(tmp.label));
    rho(kk,mm,2)  = x.weights(2).rho(1);
    perf(kk,mm,2) = x.weights(2).performance(1);
    noverlap(kk,mm,2) = sum(sum(isfinite(tmp.trial{2}))==numel(tmp.label));

  end
end
%fname = fullfile(datadir, sprintf('%s_ses-%03d_ses-%03d_repeats_cc.mat',subj, sess1, sess2));
fname = fullfile(datadir, sprintf('%s_ses-%03d_ses-%03d_repeats_cc_lambda%s.mat',subj, sess1, sess2, num2str(lambda)));
save(fname, 'rho', 'noverlap', 'perf', 'fnames', 'lambda');

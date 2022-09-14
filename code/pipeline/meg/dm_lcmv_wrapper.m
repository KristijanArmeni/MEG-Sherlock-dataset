function source = dm_lcmv_wrapper(sub)

datadir = '/project/3011085.05/jansch/';

% get the subject specific info
subj = dm_subjinfo(sub, 'ses-001');

% get the forward solution
load(subj.anatomy.headmodel); % headmodel variable
load(subj.anatomy.sourcemodel); % sourcemodel variable

% load in the covariance
cd(datadir);
d = dir(sprintf('%s*tlck.mat', sub));
for k = 1:numel(d)
  load(d(k).name, 'tlck');
  T(k) = tlck;
end
tlck.cov = cat(1,T.cov);
tlck.dof = cat(1,T.dof);
tlck.trial = cat(1,T.trial);
clear T;

headmodel   = ft_convert_units(headmodel,   'cm');
sourcemodel = ft_convert_units(sourcemodel, 'cm');

cfg = [];
cfg.headmodel = headmodel;
cfg.sourcemodel = sourcemodel;
cfg.singleshell.batchsize = 2000;
leadfield = ft_prepare_leadfield(cfg, tlck);

% compute spatial filters
cfg                   = [];
cfg.headmodel         = headmodel;
cfg.sourcemodel       = leadfield;
%cfg.sourcemodel.label = tlck.label;
cfg.method          = 'lcmv';
cfg.lcmv.keepfilter = 'yes';
cfg.lcmv.lambda     = '100%';
cfg.lcmv.fixedori   = 'yes';
source              = ft_sourceanalysis(cfg, tlck);
source.cfg.callinfo.usercfg = rmfield(source.cfg.callinfo.usercfg, 'sourcemodel');

clear headmodel leadfield cfg

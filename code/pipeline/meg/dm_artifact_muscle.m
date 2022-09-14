function cfg = dm_artifact_muscle(dataset, trl)

trltmp = dm_artifact_epochtrl(trl);

% Muscle artifacts
cfg                              = [];
cfg.trl                          = trltmp;
cfg.continuous                   = 'yes';
cfg.dataset                      = dataset;
cfg.memory                       = 'low';
cfg.artfctdef.zvalue.channel     = {'MEG'};
cfg.artfctdef.zvalue.bpfilter    = 'no';
cfg.artfctdef.zvalue.hilbert     = 'no';
cfg.artfctdef.zvalue.rectify     = 'yes';
cfg.artfctdef.zvalue.hpfilter    = 'yes';
cfg.artfctdef.zvalue.hpfreq      = 80;
cfg.artfctdef.zvalue.cutoff      = 10;
cfg.artfctdef.zvalue.demean      = 'yes';
cfg.artfctdef.zvalue.boxcar      = 0.5;
cfg.artfctdef.zvalue.fltpadding  = 0;
cfg.artfctdef.zvalue.trlpadding  = 0;
cfg.artfctdef.zvalue.artpadding  = 0.1; % .1 sec padding
cfg.artfctdef.zvalue.interactive = 'yes';
cfg.artfctdef.type               = 'zvalue';
cfg.artfctdef.reject             = 'nan';  % replace the selected epochs with nans

cfg = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfg = ft_artifact_zvalue(cfg);

end
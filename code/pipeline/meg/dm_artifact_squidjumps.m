function cfg = dm_artifact_squidjumps(dataset, trl)

trltmp = dm_artifact_epochtrl(trl);

% SQUID jumps
cfg                                = [];
cfg.trl                            = trltmp;
cfg.continuous                     = 'yes';
cfg.dataset                        = dataset;
cfg.memory                         = 'low';
cfg.artfctdef.zvalue.channel       = {'MEG'};
cfg.artfctdef.zvalue.medianfilter  = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.cutoff        = 100;
cfg.artfctdef.zvalue.absdiff       = 'yes';
cfg.artfctdef.zvalue.fltpadding    = 0;
cfg.artfctdef.zvalue.trlpadding    = 0.1;
cfg.artfctdef.zvalue.artpadding    = 0.1;
cfg.artfctdef.zvalue.interactive   = 'yes';
cfg.artfctdef.type                 = 'zvalue';
cfg.artfctdef.reject               = 'nan';   % replace the selected epochs with nans

cfg = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfg = ft_artifact_zvalue(cfg);


end
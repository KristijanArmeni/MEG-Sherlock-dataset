function [data, filt] = dm_lcmv(subject, session, suffix)
%
%
% [source, data] = dm_lcmv(inpcfg, subject)
% 
% INPUT ARGUMENTS:
%
% subject       = string, subject id as specified in subject.name
% 

%% Initialize
d           = dm_dir();
if ischar(subject) && exist('session', 'var')
    subject = dm_subjinfo(subject, session);
else
    subject = dm_subjinfo(subject);
end

for k = 1:numel(subject)
    
    % Load in data
    
    subtmp = subject(k);
    
    savedir = fullfile(d.derived, subtmp.sublabel, subtmp.seslabel, 'meg');
    
    if ~isempty(subtmp.preproc)
        load(subtmp.preproc);
        datatmp = data; clear data
    else
        error('No data specified in <subtmp.preproc.meg>');
    end

    % add the fsample field it is not there (should be 300 normally)
    if isfield(datatmp, 'fsample')
        fsample = datatmp.fsample;
    else
        fsample = datatmp.cfg.previous{1}.resamplefs;
    end

    % remove the elec field
    if isfield(datatmp, 'elec')
        datatmp = rmfield(datatmp, 'elec');
    end

    dataorig = datatmp;

    % Remove the nans
    for kk = 1:numel(datatmp.trial)
      datatmp.trial{kk}(:,~isfinite(datatmp.trial{kk}(1,:))) = [];
      datatmp.time{kk} = (0:(size(datatmp.trial{kk},2)-1))./fsample;
    end

    load(subtmp.anatomy.headmodel); % headmodel variable
    load(subtmp.anatomy.leadfield); % leadfield variable

    % Do dimension check
    
    if ~isequal(leadfield.labelorg, datatmp.label)
        sel = ismember(leadfield.labelorg, datatmp.label);
        leadfield.leadfield(leadfield.inside) = cellfun(@(x) x(sel, :), leadfield.leadfield(leadfield.inside), 'UniformOutput', false);
        leadfield.labelorg = datatmp.label;
    end
    
    % Load atlas

    f   = d.atlas{1}; % 1 == 374 Conte atlas, 2 == Glaser et al (2016, Nat neuro)
    load(f)

    %% Compute spatial filters

    cfg                 = [];
    cfg.vartrllength    = 2;
    %cfg.trials          = inpcfg.trials;
    cfg.covariance      = 'yes';
    tlck                = ft_timelockanalysis(cfg, datatmp);
    tlck.cov            = real(tlck.cov);

    cfg                   = [];
    cfg.headmodel         = headmodel;
    cfg.sourcemodel       = leadfield;
    cfg.sourcemodel.label = tlck.label;
    cfg.method          = 'lcmv';
    cfg.lcmv.fixedori   = 'yes';
    cfg.lcmv.keepfilter = 'yes';
    cfg.lcmv.lambda     = '100%';
    cfg.lcmv.weightnorm = 'unitnoisegain';
    source              = ft_sourceanalysis(cfg, tlck);
    clear headmodel leadfield cfg

    % take the spatial filters
    F                  = zeros(size(source.pos,1),numel(tlck.label)); % num sources by MEG channels matrix
    F(source.inside,:) = cat(1,source.avg.filter{:});

    clear source tlck
    
    %% Parcellate the source time courses

    % concatenate data across trials
    datatmp.trial  = {cat(2, datatmp.trial{:})};
    datatmp.time   = {(0:(size(datatmp.trial{1},2)-1))./fsample};
    datatmp.dimord = 'chan_time';

    selparcidx        = find(~contains(atlas.parcellationlabel, {'_???', '_MEDIAL.WALL_01'}));
    source_parc.label = atlas.parcellationlabel(~contains(atlas.parcellationlabel, {'_???', '_MEDIAL.WALL_01'}));
    
    % selparcidx        = unique(atlas.parcellation); % create column of indices 1-num parcels
    % source_parc.label = atlas.parcellationlabel; 

    source_parc.F     = cell(numel(source_parc.label),1);

    tmp     = rmfield(datatmp, {'grad', 'trialinfo'});

    cfg        = [];
    cfg.method = 'pca';

    for h = 1:numel(source_parc.label)

      tmpF      = F(atlas.parcellation==selparcidx(h),:); % select weights for kth parcel
      tmp.trial = {tmpF*datatmp.trial{1}};
      tmp.label = cellstr(string(1:size(tmpF, 1))');
      tmpcomp   = ft_componentanalysis(cfg, tmp);

      source_parc.F{h}     = tmpcomp.unmixing*tmpF;

    end

    clear datatmp tmp tmpcomp tmpF atlas
    %% Beam the sensor data
    cfg         = [];
    cfg.channel = 'MEG';
    data        = ft_selectdata(cfg, dataorig);

    % create now a 'spatial filter' that concatenates the first components for
    % each of the parcels 
    for i = 1:numel(source_parc.label)
        F_parc(i,:) = source_parc.F{i}(1,:);
    end

    % multiply the filter with the sensor data
    for j = 1:numel(data.trial)
        data.trial{j} = F_parc*dataorig.trial{j};
    end
    clear data_sensor

    data.label = source_parc.label;

    %% Save if specified

    %data_sensor = rmfield(data, 'cfg'); % remove the cfg which might be bulky
    
    save(fullfile(savedir, [num2str(subtmp.subnr) '-' num2str(subtmp.sesnr) '_lcmv-filt-orig_' suffix '.mat']), 'F', '-v7.3');
    save(fullfile(savedir, [num2str(subtmp.subnr) '-' num2str(subtmp.sesnr) '_lcmv-filt-parc_' suffix '.mat']), 'source_parc', '-v7.3');
    save(fullfile(savedir, [num2str(subtmp.subnr) '-' num2str(subtmp.sesnr) '_lcmv-data_' suffix '.mat']), 'data', '-v7.3');

end

end

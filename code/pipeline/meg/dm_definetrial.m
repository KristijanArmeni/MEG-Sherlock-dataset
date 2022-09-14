function trl = dm_definetrial(dataset, codes)
%
%       INPUTS
%       s       = struct, obtained from dm_subjinfo(subject_label)
%
%       OUTPUTS
%       trl     = cell array [num_sessions, 1], cell array of trial 
%                 matrices
%

% nses  = numel(s.dataset);  % number of datasets/sessions
% trl   = cell(nses, 1); % cell array for trl matrices
% codes = (1:9)*10;
% codes = [codes codes + 5];
% create trl matrix for each dataset/session
%for k = 1:nses
    
    %dataset = s.dataset{k};
    events  = ft_read_event(dataset);    % event struct (all events)
    
    % select only channel UPPT001
    type    = {events.type}';
    seltype = ismember(type, 'UPPT001'); % indices for UPPT001 channel
    events  = events(seltype); 
    
    % select onset relevant codes
    values    = {events.value}';
    selvalues = ismember([values{:}], codes);
    events    = events(selvalues);
    
    % remove duplicates in case of non-unique events TEMP(!)
    %if numel(unique([events.value])) ~= numel([events.value])
    %    [~, idxtmp, ~] = unique([events.value], 'first');
    %    events = events(idxtmp); % select only first occurences
    %end
    
    val = [events.value]';   % vector of event codes/values
    smp = [events.sample]';  % vector of corresponding sample points

    % Artificially place the missed onset (10) at sample point 0 
    if contains(dataset, 'sub003ses001') && sum(~ismember(codes, [100, 150]))

       val = [10; val];  
       % grab the sample nr. 2521, rather than 1, because dm_artifact_epochtrl() 
       % will grab some 2 secs worth of data before it.
       smp = [2521; smp];
       
    elseif contains(dataset, 'sub003ses008')
        
        % exclude the third section which was repeated
        sel = ~ismember(val, [30, 35]);
        val = val(sel);
        smp = smp(sel);
        
    end
    
    if ismember(codes, [100 150]) 
        onsets = val(1:2:end);
        offsets = val(2:2:end);
        trlvals = zeros(1, numel(onsets));
        trlvals(1:2:end) = 1:(numel(onsets)/2);
        trlvals(2:2:end) = 1:(numel(onsets)/2);
    else
        onsets  = val(1:2:end);  % code values used in Presentation script
        offsets = onsets + 5;
        trlvals = numel(onsets);
        nsec = numel(onsets); % number of sections (= number of onsets)
    end

    trloffsets    = zeros(numel(onsets), 1);
    
    begsmp = smp(ismember(val, onsets));
    endsmp = smp(ismember(val, offsets));
    
    if ~ismember(codes, [100 150])
        for h = 1:nsec
            onsettmp = int2str(onsets(h));
            trlvals(h) = str2double(onsettmp(1));
        end
        
    end
    
    trl = [begsmp endsmp trloffsets trlvals'];

%end
    
    
end


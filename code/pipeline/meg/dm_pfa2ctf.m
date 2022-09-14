function [ftab, orig, fstruct] = dm_pfa2ctf(txt, datatime, what)

[w, p, ~] = dm_readPFA2(txt);

switch what
    case 'word'
        dat = w; clear w
    case 'phone'
        dat = p; clear p
end

% Convert to numeric
%dat         = cell(size(dat));
%dat(:, 1)   = dat(:, 1);
dat(:, 2:3) = cellfun(@(x) {str2double(x)}, dat(:, 2:3));

% Time axes
notsilence = ~ismember(dat(:, 1), {'sp'});

lab = dat(notsilence, 1);
ons = [dat{notsilence, 2}];
off = [dat{notsilence, 3}];


% Structure for new timings
onsnew = nan(size(ons));
offnew = nan(size(off));

% Feature vector
fvec   = false(2, size(datatime, 2));
flabel = cell(2, size(datatime, 2))';

% Compute the onsets
for k = 1:numel(ons)
    
    onsmpl  = nearest(datatime, ons(k));
    offsmpl = nearest(datatime, off(k));
    
    onsnew(k) = datatime(onsmpl);
    offnew(k) = datatime(offsmpl);
    
end

% Create the data structure
for h = 1:numel(onsnew)
    onspl            = nearest(datatime, onsnew(h));
    offspl            = nearest(datatime, offnew(h));
    
    fvec(1, onspl) = 1;   % onset row
    fvec(2, offspl) = 1;  % offset row
    
    flabel{onspl, 1} = lab{h};
    flabel{offspl, 2} = lab{h};
end

fstruct.trial = fvec; 
fstruct.time  = datatime;
fstruct.label = flabel;

% create output table
ftab = table(dat(notsilence, 1), onsnew', offnew', ...
                'VariableNames', {what, 'onset', 'offset'});

orig = cell2table(dat(notsilence, :), ...
                 'VariableNames', {what, 'onset', 'offset'});
end




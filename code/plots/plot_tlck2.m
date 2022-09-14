
d = dm_dir;
load(d.atlas{1}, 'atlas');
load(d.atlas{3}, 'ctx');

close all

subject_id = 3;
subject = sprintf('sub-%03d', subject_id);

% load data structure
%data = load(fullfile(d.results, subject, sprintf('%s-erf-1_40.mat', subject)));
cd(fullfile(d.derived, subject));
dd = dir('ses*');
for k = 1:numel(dd)
  filename = fullfile(d.derived, subject, dd(k).name, 'meg', sprintf('%s-%d_lcmv-tlck_1-40.mat', subject(end), str2double(dd(k).name(end-2:end))));
  load(filename);
  data(k) = tlck;
end

% choose most suitable lags for each subjects
time = data(1).time;
s1 = nearest(time, [0.06 0.08]);%0.07);
s2 = nearest(time, [0.04 0.06]);
s3 = nearest(time, [0.04 0.06]);
best_lags = [s1(:), s2(:), s3(:)];

% select the time point
selectlag = best_lags(:, subject_id);

% do baseline subtraction, has already been done, but does not hurt to do
% again: subtract mean over the baseline (up until timepoint 0)

for k = 1:numel(data)
  end_smp  = nearest(data(k).time, 0); 
  baseline = mean(data(k).avg_n(:, 1:end_smp), 2);  

  % subtract and align the polarity: this works reasonably well for
  % subjects 1 and 2
  if ~subject_id==3
    data(k).avg_n = alignpolarity2(data(k).avg_n - baseline, [1 end_smp]); 
    refdat = mean(data(k).avg_n(:,selectlag(1):selectlag(2)),2);
    [~, indx] = max(abs(refdat));
    data(k).avg_n = data(k).avg_n .* sign(refdat(indx));
  else
    [tmp, tmps, tmpv] = alignpolarity2(data(k).avg_n(:, nearest(data(k).time, 0):nearest(data(k).time, 0.8)) - baseline, [1 end_smp]);
    data(k).avg_n = diag(prod(tmpv, 2))*(data(k).avg_n - baseline);
    refdat = mean(data(k).avg_n(:,selectlag(1):selectlag(2)),2);
    [~, indx] = max(abs(refdat));
    data(k).avg_n = data(k).avg_n .* sign(refdat(indx));
  end

  
end

% loop over sessions
for k = 1:numel(data)
  
  % map data onto source mesh
  % stat = dm_mask2atlas(atlas, data(k).avg_n(:, selectlag), data(k).label);
  dat   = mean(data(k).avg_n(:,selectlag(1):selectlag(2)),2);
  [a,b] = match_str(atlas.parcellationlabel, data(k).label);
  dat2  = zeros(numel(atlas.parcellationlabel),1);
  dat2(a) = dat(b);
  stat  = dat2(atlas.parcellation);
  

  % define the input data structure
  sp        = [];
  sp.stat   = abs(stat);
  sp.dimord = 'pos';
  sp.pos    = ctx.pos;
  sp.tri    = ctx.tri;

  % ft_sourceplot configuration
  cfg               = [];
  cfg.funparameter  = 'stat';
  cfg.maskparameter = 'stat';
  cfg.maskstyle     = 'colormix';
  cfg.method        = 'surface';
  cfg.funcolormap   = brewermap(65, 'OrRd');
  cfg.camlight      = 'no';
  cfg.colorbar      = 'no';

  ft_sourceplot(cfg, sp);
  view([90 20]); camlight; material dull;
  c = colorbar; colormap(cfg.funcolormap);
  c.Position = [0.8, 0.6, 0.03, 0.12];

  % save the source plot
  fig = gcf;
  set(fig, 'NumberTitle', 'off', 'Name', sprintf('%s-%d', subject, k));
  title(sprintf('%s-%d', subject, k));
  figname = fullfile(d.results, subject, 'figures', sprintf('%s-%d-erf-source.png', subject, k));
  % export_fig(figname, '-png', '-m8');

  % plot time courses
  figure;
  set(gcf, 'NumberTitle', 'off', 'Name', [subject '-' sprintf('ses-%d', k)])
  set(gcf, 'Position', [500, 500, 600, 200]);
  hax = axes;
  plot(data(k).time(1, :), data(k).avg_n(:, :), 'color', [0.4, 0.4, 0.4, 0.4]); 
  hold on;
  xline(data(k).time(1, selectlag(1)), '--r', 'LineWidth', 1.5);
  xline(data(k).time(1, selectlag(2)), '--r', 'LineWidth', 1.5);

  ylim = get(hax, 'Ylim');
  %text(0.4, 0.85*ylim(2), sprintf('N = %d', data.n(k)));
  text(data(k).time(selectlag(2))+0.01, 0.85*ylim(2), sprintf('t = %.2f s',  round(mean(data(k).time(selectlag)),2)));
  ylabel('source amplitude');
  xlabel('time (sec)');
  box off;
  
  % save time course
  fname = fullfile(d.results, subject, 'figures', sprintf('%s-%d-erf-time.svg', subject, k));
  % saveas(gcf, fname);
  

end
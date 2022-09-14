
sub = dm_subjinfo('sub-003');

% Pilot, 4 sessions
[hp_d1A, ~, hp_d1B] = dm_preproc_headmovement(sub, 1);
[hp_d2A, ~, hp_d2B] = dm_preproc_headmovement(sub, 2); % Head localizer updated here
[hp_d3A, ~, hp_d3B] = dm_preproc_headmovement(sub, 3);
[hp_d4A, ~, hp_d4B] = dm_preproc_headmovement(sub, 4);
[hp_d5A, ~, hp_d5B] = dm_preproc_headmovement(sub, 5);
[hp_d6A, ~, hp_d6B] = dm_preproc_headmovement(sub, 6);
[hp_d7A, ~, hp_d7B] = dm_preproc_headmovement(sub, 7); 
[hp_d8A, ~, hp_d8B] = dm_preproc_headmovement(sub, 8);
[hp_d9A, ~, hp_d9B] = dm_preproc_headmovement(sub, 9);
[hp_d10A, ~, hp_d10B] = dm_preproc_headmovement(sub, 10);


%% Plot

% plot translations
figure(); 
ax1 = subplot(5, 2, 1);
plot(hp_d1A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(1).sublabel, sub(1).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax2 = subplot(5, 2, 3);
plot(hp_d2A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(2).sublabel, sub(2).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax3 = subplot(5, 2, 5);
plot(hp_d3A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(3).sublabel, sub(3).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax4 = subplot(5, 2, 7);
plot(hp_d4A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(4).sublabel, sub(4).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax5 = subplot(5, 2, 9);
plot(hp_d5A(1:3, :)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(5).sublabel, sub(5).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax6 = subplot(5, 2, 2);
plot(hp_d6A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(6).sublabel, sub(6).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax7 = subplot(5, 2, 4);
plot(hp_d7A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(7).sublabel, sub(7).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax8 = subplot(5, 2, 6);
plot(hp_d8A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(8).sublabel, sub(8).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax9 = subplot(5, 2, 8);
plot(hp_d9A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(9).sublabel, sub(9).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

ax10 = subplot(5, 2, 10);
plot(hp_d10A(1:3,:)'*1000, '--o') % in mm
title(sprintf('%s-%s', sub(10).sublabel, sub(10).seslabel));
xlabel('time (min)')
ylabel('distance (mm)')
legend('x', 'y', 'z');

%linkaxes([ax1, ax2, ax3, ax4, ax5], 'xy');
%linkaxes([ax6, ax7, ax8, ax9, ax10], 'xy');
linkaxes([ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10], 'xy');
%ax1.YLim = [-1, 1];
set(gcf, 'Name', 'Translations', 'NumberTitle', 'off');
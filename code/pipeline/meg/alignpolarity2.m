function [y,s,V] = alignpolarity2(x, blwindow)

% ALIGNPOLARITY aims at aligning the polarity of the signals in the rows of
% input matrix X ...

y = x;

if nargin==1,
  blwindow = [1 size(x,2)];
end

for k = 1:20 % just a number
  %c   = cov(y');
  
  y = ft_preproc_polyremoval(y, 0, blwindow(1), blwindow(2));  
  
  [u,sx,v] = svd(y, 'econ');
  V(:,k)  = sign(y*v(:,1));
  y       = diag(sign(y*v(:,1)))*y;
  
  y = ft_preproc_polyremoval(y, 0, blwindow(1), blwindow(2)); 
  c = y*y';
  s(k,:) = sum(sign(c)<0);
end




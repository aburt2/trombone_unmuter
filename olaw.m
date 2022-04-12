function w = olaw( type, N)
% OLAW  Plot overlapping windows
%
%   OLAW( TYPE, N, OLAP, nWINDOWS) plots nWINDOWS, each of length N,
%   overlapped by the percentage OLAP.  The window type is
%   specified with the string variable TYPE, which can be either
%   'triangle', 'hann', 'hamm', or 'blackman'. Note that there may be
%   problems in achieving constant overlap due to even/odd values of N and
%   the values of the windows at boundaries.
%
%   By Gary P. Scavone, McGill University, 2007.

if ( nargin ~= 2 )
  error('Number of arguments is incorrect.');
  return
end

if strcmp( type, 'triangle' )
  w = window( @triang, N );
elseif strcmp( type, 'hann' )
  w = window( @hann, N );
elseif strcmp( type, 'hamm' )
  w = window( @hamming, N );
elseif strcmp( type, 'blackman' )
  w = window( @blackman, N );
else
  error('Window type argument is incorrect.');
  return;
end



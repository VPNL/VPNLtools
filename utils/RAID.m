function pth = RAID
% For Kalanit lab files:
%
% This returns the path for Kalanit's RAID partition on the local computer.
%
% 09/16/03 ras.

% sneaky alternate approach:
% if you're calling this file, then it must be somewhere in your path. This
% file is only saved on the RAID (generally in RAID/dataTools), so we know
% the RAID is the parent directory to wherever this file is. Simple! And
% uses wacky recursion. Yay. -ras
pth = fileparts(fileparts(which('RAID')));

return


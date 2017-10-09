function raid_path = RAID(varargin)
% Returns the path for the base RAID partition on local computer (five 
% directories above location where RAID.m function is stored/mounted. This 
% assumes that the RAID.m function is in your path and located at:
%   /[RAID partition]/projects/GitHub/VPNLtools/utils/
% 
% INPUTS (optional)
%   varargin: arguments specifying series subdirectories to append to path
% 
% OUTPUT
%   raid_path: platform-indpendent path to VPNL storage partition
% 
% 9/17 AS

% find location of RAID.m function on local computer/mount
raid_path = which('RAID');

% set base partition five directories above path to RAID.m
for ii = 1:5
    raid_path = fileparts(raid_path);
end

% append optional subdirectory arguements
for dd = 1:length(varargin)
    raid_path = fullfile(raid_path, varargin{dd});
end

end

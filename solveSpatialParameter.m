function out = solveSpatialParameter(out)
%SOLVESPATIALPARAMETER figures out how far or what size real and virtual
% objects are in relation to a point source (also arc angle)
% Just give either 3 parameters and it solves for the other two
% If only solving triangle can give 1 virtual and arc angle or both virtual 
%
% Parmeters:
% - arcAngle        = how much FoV the object covers of point source
% - realDistance    = how far the real life object is from source
% - realSize        = size of the real life object
% - virtualDistance = distance of the object dependent on virtual size
% - virtualSize     = size of the object dependent on virtual distance
%
% Written 07/27/2022 - Giann / Ryan
%
% Assumptions:
% _ works with radians
% - objects are straight ahead
% - dependent on accurate measurements
% - object is a flat plane
% - working in a 2d environment
%
%    _________ rs / rd
%    \   |   /
%     \-----/  vs / vd
%      \ | /
%       \|/    aa
%
% See also ATAN and TAN

%% Parse Input
arguments
    out.arcAngle        (1,1) double {mustBeRealAngle}  = nan
    out.realDistance    (1,1) double {mustBeRealLength} = nan
    out.realSize        (1,1) double {mustBeRealLength} = nan
    out.virtualDistance (1,1) double {mustBeRealLength} = nan
    out.virtualSize     (1,1) double {mustBeRealLength} = nan
end

% check enough inputs given to solve the problem
out = doingVirtualOnly(out);
checkExactly3Inputs(out)
check1Real1Virtual(out)

%% solve the triangle
% solve for arc angle first
if isnan(out.arcAngle)
    if isnan(out.realDistance + out.realSize) % have both virtual values
        out.arcAngle = 2 * atan(out.virtualSize / (2*out.virtualDistance));
    else % have both real values
        out.arcAngle = 2 * atan(out.realSize / (2*out.realDistance));
    end
end

% using arc angle solve for other missing parameters
if isnan(out.realDistance)
    out.realDistance = out.realSize / (2 * tan(out.arcAngle/2));
elseif isnan(out.realSize)
    out.realSize = 2 * out.realDistance * tan(out.arcAngle/2);
end
if isnan(out.virtualDistance)
    out.virtualDistance = out.virtualSize / (2 * tan(out.arcAngle/2));
elseif isnan(out.virtualSize)
    out.virtualSize = 2 * out.virtualDistance * tan(out.arcAngle/2);
end

% double check the math
if abs(out.realDistance/out.realSize - out.virtualDistance/out.virtualSize) > 10^-6
    error('Our math is wrong %f ~= %f', out.realDistance/out.realSize, out.virtualDistance/out.virtualSize)
end

%% helper funcitons
    function inputs = doingVirtualOnly(inputs)
        % if only given one virtual parameter and arc angle allow function
        % to continue to solve for the other virtual parameter
        if isnan(inputs.realDistance) && isnan(inputs.realSize) && ...
                (~isnan(inputs.arcAngle) || ~isnan(inputs.virtualDistance+inputs.virtualSize))
            inputs.realSize = 1;
            warning('Solving only virtual triangle.')
        end
    end

    function checkExactly3Inputs(inputs)
        % check 3 inputs were given
        parameters = fields(inputs)';
        argsIn = 0;
        for param = parameters
            if ~isnan(inputs.(param{1}))
                argsIn = argsIn + 1;
            end
        end
        if argsIn ~= 3
            errID  = 'solveSpatialParameter:badInputs';
            errMsg = 'Incorrect inputs given, check help.';
            throwAsCaller(MException(errID, errMsg))
        end
    end

    function check1Real1Virtual(inputs)
        % check 3 inputs were given
        parameters = fields(inputs)';
        realVariable = false;
        virtualVariable = false;
        for param = parameters
            if contains(param{1}, 'real') && ~isnan(inputs.(param{1}))
                realVariable = true;
            elseif contains(param{1}, 'virtual') && ~isnan(inputs.(param{1}))
                virtualVariable = true;
            end
        end
        if ~(realVariable && virtualVariable)
            errID  = 'solveSpatialParameter:badInputsl';
            errMsg = 'Incorrect inputs given, check help.';
            throwAsCaller(MException(errID, errMsg))
        end
    end

end

%% input validation
function mustBeRealAngle(val)
if ~isnan(val) && mod(val, 2*pi) > pi
    errID  = 'solveSpatialParameter:badArcAngle';
    errMsg = 'Arc angle must be between 0 and pi (object must exist in reality).';
    throwAsCaller(MException(errID, errMsg))
end
end

function mustBeRealLength(val)
if ~isnan(val) && val < 0
    errID  = 'solveSpatialParameter:badLength';
    errMsg = 'Length values (distance or size) must be positive (object must exist in reality).';
    throwAsCaller(MException(errID, errMsg))
end
end
% Asigning robot specification
param.g = 9.8;
param.d = 0.08;     % ball diameter
param.r = 0.3;      % spring rest length/ chi0
param.m = 3;        % hopper mass
param.k = 60;       % air spring eleastic constant
param.b = 6;        % damping constant
param.N = 3;     % air expand ratio
param.thrusttime = 0.005;  % duration of thrust

% Initial position Q0 = [q dq]
Q0 = [1 0];
tbegin = 0;
tfinal = 5;
phase = 4;

% ODE solving
T = tbegin;
Q = Q0;
while T(end) < tfinal
    if phase == 1
        % touch down, into stance phase
        [Ttemp, Qtemp, te, Qe, ie] = ...
            ode45(@(t, Q)EOMAirSpring(t, Q, param),[tbegin, tfinal], Q0,...
            odeset('Events',@(t, Q)EventBottom(t, Q, param)));
        phase = 2;
    elseif phase == 2
        % stance phase, injecting thrust
        [Ttemp, Qtemp] = ...
            ode45(@(t, Q)EOMAirSpringThrust(t, Q, param),...
            [tbegin, tbegin + param.thrusttime], Q0);
        phase = 3;
    elseif phase == 3
        % stance phase without thrust
        [Ttemp, Qtemp, te, Qe, ie] = ...
            ode45(@(t, Q)EOMAirSpring(t, Q, param),[tbegin, tfinal], Q0,...
            odeset('Events',@(t, Q)EventLiftOff(t, Q, param)));
        phase = 4;
    elseif phase == 4
        % lift off, into fly phase
        [Ttemp, Qtemp, te, Qe, ie] = ...
            ode45(@(t, Q)EOMFlight(t, Q, param),[tbegin, tfinal], Q0,...
            odeset('Events',@(t, Q)EventTouchDown(t, Q, param)));
        phase = 1;
    end
    nT= length(Ttemp);
    T = [T; Ttemp(2:nT)];
    Q = [Q; Qtemp(2:nT,:)];
    Q0 = Qtemp(nT,:);
    tbegin = Ttemp(nT);
end
    
% Interpolation of Times
T2 = [0: 1e-2: tfinal];
Q2 = interp1(T, Q, T2);

% Simulation Visualization
RunVerticalHopperSimulation(T2, Q2, param, 'none');

% Equations of motion ****************
function dQ = EOMFlight(t, Q, param)
    % Flight phase (from liftoff to touchdown)
    % insert your previous code here
    dQ = zeros(2,1);
    dQ(1) = Q(2);
    dQ(2) = -param.g;
end
function dQ = EOMAirSpring(t, Q, param)
    % write the equation of motion for the stance phase for an air-spring hopper
    dQ = zeros(2,1);
    dQ(1) = Q(2);
    dQ(2) = -param.g-param.b*Q(2)/param.m+param.k/Q(1)/param.m;;
end
function dQ = EOMAirSpringThrust(t,Q,param)
    % write the equation of motion for the thrust phase for an air-spring hopper
    dQ = zeros(2,1);
    dQ(1) = Q(2);
    dQ(2) = -param.g-param.b*Q(2)/param.m+param.N*param.k/Q(1)/param.m;
end

% Event function *********************
function [value,isterminal,direction] = EventTouchDown(t, Q, param)
    % insert your previous code here
    value = Q(1)-param.r;         % event point: touch down
    isterminal = 1;
    direction = -1;
end
function [value,isterminal,direction] = EventLiftOff(t, Q, param)
    % insert your previous code here
    value = param.r-Q(1);         % event point: touch down
    isterminal = 1;
    direction = -1;
    
end
function [value,isterminal,direction] = EventBottom(t, Q, param)
    % Define the lowest point
    value = Q(2);
    isterminal = 1;
    direction = 1;
end
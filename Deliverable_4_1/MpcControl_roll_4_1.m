classdef MpcControl_roll_4_1 < MpcControlBase

     methods
         % Design a YALMIP optimizer object that takes a steady-state state
         % and input (xs, us) and returns a control input
         function ctrl_opti = setup_controller(mpc, Ts, H)

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             % INPUTS
             %   X(:,1)       - initial state (estimate)
             %   x_ref, u_ref - reference state/input
             % OUTPUTS
             %   U(:,1)       - input to apply to the system
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             N_segs = ceil(H/Ts); % Horizon steps
             N = N_segs + 1;      % Last index in 1-based Matlab indexing

             [nx, nu] = size(mpc.B);

             % Steady-state targets (Ignore this before Todo 3.2)
             x_ref = sdpvar(nx, 1);
             u_ref = sdpvar(nu, 1);

             % Predicted state and input trajectories
             X = sdpvar(nx, N);
             U = sdpvar(nu, N-1);

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE

             % NOTE: The matrices mpc.A, mpc.B, mpc.C and mpc.D are
             %       the DISCRETE-TIME MODEL of your system

             % States: (wz, gamma) / Inputs: (Pdiff)
             Q = diag([60, 70]); 
             R = 0.001;
       
             PdiffMax = 20;

             F = [1; -1]; %constraints on U, abs(Pdiff) <= 20%
             f = [PdiffMax; PdiffMax];

             % MPT3 to get terminal sets/constraints             
             [~, Qf, ~] = dlqr(mpc.A,mpc.B,Q,R);

             % SET THE PROBLEM CONSTRAINTS con AND THE OBJECTIVE obj HERE
             obj = 0;
             con = [];

             for i = 1:N-1
                 obj = obj + (X(:,i)-x_ref)'*Q*(X(:,i)-x_ref) + (U(:,i)-u_ref)'*R*(U(:,i)-u_ref);
                 con = con + (X(:,i+1) == mpc.A*X(:,i) + mpc.B*U(:,i)) + (F*U(:,i) <= f);
             end
             obj = obj + (X(:,N)-x_ref)'*Qf*(X(:,N)-x_ref);

             % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             % Return YALMIP optimizer object
             ctrl_opti = optimizer(con, obj, sdpsettings('solver','gurobi'), ...
                 {X(:,1), x_ref, u_ref}, {U(:,1), X, U});
         end

         % Design a YALMIP optimizer object that takes a position reference
         % and returns a feasible steady-state state and input (xs, us)
         function target_opti = setup_steady_state_target(mpc)

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             % INPUTS
             %   ref    - reference to track
             % OUTPUTS
             %   xs, us - steady-state target
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             % Steady-state targets
             nx = size(mpc.A, 1);
             xs = sdpvar(nx, 1);
             us = sdpvar;

             % Reference position (Ignore this before Todo 3.2)
             ref = sdpvar;

             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE
             % You can use the matrices mpc.A, mpc.B, mpc.C and mpc.D
             PdiffMax = 20;

             F = [1; -1]; %constraints on U, abs(Pdiff) <= 20%
             f = [PdiffMax; PdiffMax];

             obj = us^2;

             con = [F*us <= f, ...
                     xs == mpc.A*xs + mpc.B*us, ...
                     ref == mpc.C*xs];

             % YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE YOUR CODE HERE
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             % Compute the steady-state target
             target_opti = optimizer(con, obj, sdpsettings('solver', 'gurobi'), ref, {xs, us});
         end
     end
 end
% This code was used in: Masquelier T (2017) STDP allows close-to-optimal spatiotemporal spike pattern detection by single coincidence detector neurons. Neuroscience.
% https://doi.org/10.1016/j.neuroscience.2017.06.032
% Jan 2017
% timothee.masquelier@cnrs.fr
%
% Several independent LIF neurons (which can differ by their
% threshold and dw_post, see param.m) integrate the same input spikes.
% A frozen input spike sequence (or several) repeat(s) perdiodically.
% Between these repetitions input spikes are random (homogeneous Poisson).
%
% All the numerical parameters are gathered in param.m
%
% This code is clock-driven.
% The LIF equation: tau_m*dV/dt = -V + I
% is integrated using forward Euler.
% The refractory period is ignored for simplicity.
%
% Synapses are equipped with spike timing-dependent plasticity (STDP).
% We will use the "classic" additive, all-to-all spikes with exponential
% windows proposed by Song, Miller & Abbott 2000 Nat Neurosc
%
% In addition, at each postsynaptic spike, all the synaptic weights are
% decreased by a fixed value dw_post (homeostatic mechanism), like in Kempter, Gerstner& van Hemmen 1999 Phys Rev E
%
% This script can be launched individually, with or without specifying a
% random seed (eg matlab  -r "seed=3;main")
% One can also launch multi threads with different random seeds using
% batch.py
%
% If ../data/pattern.mat exist, this/these pattern(s) will be used.
% Otherwise fresh ones are randomly generated.
%
% If ../data/w.mat exist, these weights will be used as initial weights (this can be useful to continue a simulation)
% Otherwise homogeneous initial weights are used.
%
% A convergence index is periodically stored ../data/conv.mat (unless in batch mode)
% If this file already exists, then new values are appended
% Otherwise a new file is created

if exist('seed','var') % in case a seed is already defined (for example by calling matlab  -r "seed=3;main")
    rng(seed)
    timedLog(['Setting random seed to ' num2str(seed)])
    batch_mode = true;
else
    batch_mode = false;
end

% function sequence(seed)
% batch_mode = true;
% rng(seed)
% timedLog(['Setting random seed to ' num2str(seed)])

tic

%clear all

param

%__________________________________________
% INITIALIZATIONS
if tau_s > 0
    V_unit = tau_s/(tau_m-tau_s) * ( (tau_s/tau_m)^(tau_s/(tau_m-tau_s)) - (tau_s/tau_m)^(tau_m/(tau_m-tau_s)) ); % Maximum height of the postsynaptic potential caused by a unitary dirac input current
end

a_post = zeros(n_post,1); % LTP variable
a_pre = zeros(1,n_pre); % LTD variable

V_post = zeros(n_post,round(n_period_record*period/dt)); % Postsynaptic potential. Only most recent values are stored. Old values are overwritten.
I_post = zeros(n_post,1); % Postsynaptic current

if exist('../data/w.mat','file')
    disp('Loading previous weights')
    load ../data/w.mat
else
    w = ones(n_post,n_pre); % Synaptic weights
    % w = intial_weight*2*rand(n_post,n_pre); % Synaptic weights
    %w = w_max*[ ones(3,1) ; zeros(4,1)];
    if tau_s==0
        w = w .* repmat(ones(n_post,1).*thr/(tau_m*n_pre*f)*1/(1+(2*tau_m*n_pre*f)^-.5*initial_distance_to_threshold),[1 n_pre]);
    else
        %w = w .* repmat(ones(n_post,1).*thr/60*10/f*1000/n_pre,[1 n_pre]);
        w = w .* repmat(ones(n_post,1).*thr/80*10/f*1000/n_pre,[1 n_pre]);
    end
    if max(w(:))>1
        warning('Some initial weights are > 1')
    end
end

if exist('../data/pattern.mat','file')
    disp('Loading previous pattern(s)')
    load ../data/pattern.mat
else
    clear pattern
    pattern{n_pattern}={};
    for p=1:n_pattern
        pattern{p} = sparse( rand(n_involved,round(pattern_duration/dt))<dt*f );
    end
    if ~batch_mode
        save ../data/pattern pattern
    end
end

 
% disp('*** Learn pattern by cheating *** ')
% w = 0*w;
% w(:,sum(pattern{1},2)>2) = 1;
% w(:,sum(pattern{1}(:,round(40e-3/dt+(1:tau_pre/dt))),2)>0) = 1;

count = 0; % Postsynaptic spike counter


% record output spikes
spike_list = zeros(n_period_record_spike*10*n_post,2);
cursor = 1;

%__________________________________________
% INTEGRATION (FORWARD EULER)
for i=2:n_period*period/dt
    
    if ~batch_mode
        if mod(i*dt,100*period)==0
            disp(['Period ' int2str(i*dt/period)])
            
            if exist('../data/conv.mat','file')
                load('../data/conv.mat');
            else
                conv = [];
            end
            conv = [conv;mean(mean(abs((w-(w>.5)))))];
            save ../data/conv.mat conv
        end
    end
    
    % Presynaptic spikes
    j = round( mod(i,round(period/dt)) - (period-pattern_duration-2*jitter)/dt );
    if j>0 % inside pattern
        if j==1 % first time in pattern
            pattern_idx = 1+mod(floor((i-1)/(period/dt)),n_pattern);
            jittered_pattern = jitter_pattern(pattern{pattern_idx},jitter,f,dt);
        end
        pre_spikes = [ jittered_pattern(:,j) ; sparse( rand(n_pre-n_involved,1) < dt*f ) ] ;
    else
        pre_spikes =  sparse( rand(n_pre,1) < dt*f );
    end
    
    if tau_s > 0
        I_post = I_post*(1-dt/tau_s) + w * pre_spikes / V_unit;
    else
        I_post =  w * pre_spikes * tau_m/dt;
    end
   
    % Postsynaptic integration step
    V_post(:,mod(i-1,size(V_post,2))+1) = V_post(:,mod(i-2,size(V_post,2))+1) + dt/tau_m * ( -V_post(:,mod(i-2,size(V_post,2))+1) + I_post )  ;
    
%     % adaptive_thr
%     V_thr = V_thr + dt/tau_thr * ( -V_thr + V_post(i) )  ;

    % STDP
    if da_post(1)>0
        a_post = a_post*(1-dt/tau_post);
        % presynaptic spikes
        w(:,pre_spikes) = w(:,pre_spikes) - repmat(a_post,[1 sum(pre_spikes)]); % LTD
        w(:,pre_spikes) = max(w(:,pre_spikes),0); % Hard bounds
    end
    if da_pre(1)>0
        a_pre = a_pre*(1-dt/tau_pre);
        % presynaptic spikes
        a_pre(pre_spikes) = a_pre(pre_spikes)+da_pre; % update presynaptic traces
    end
    
    
    % postsynaptic spikes
    post_spikes = find(V_post(:,mod(i-1,size(V_post,2))+1)>=thr);
    if ~isempty(post_spikes)
        if i*dt >= (n_period-n_period_record_spike)*period
            spike_list(cursor:cursor+length(post_spikes)-1,:) = [ i*dt*ones(size(post_spikes)) post_spikes ];
            cursor = cursor+length(post_spikes);
        end
        if da_post(1)>0
            a_post(post_spikes) = a_post(post_spikes)+da_post(post_spikes); % update postsynaptic traces
        end
        if da_pre(1)>0
            w(post_spikes,:) = w(post_spikes,:) + repmat(a_pre,[length(post_spikes),1]); % LTP
            w(post_spikes,:) = min(w(post_spikes,:),1); % Hard bounds
            
            % Soft bounds
            %w(post_spikes,:) = w(post_spikes,:) + w(post_spikes,:).*(1-w(post_spikes,:)).*repmat(a_pre,[length(post_spikes),1]); % LTP
        end
        if dw_post(1)>0
            % coef = min(1,.01+i/((n_period-n_period_record)*period/dt)*.99);
            %w(post_spikes,:) = w(post_spikes,:) - repmat((dw_post_final-dw_post(post_spikes))*min(1,i/(500*period/dt))+dw_post(post_spikes),[1 n_pre]); % Homeostatic
            
            w(post_spikes,:) = w(post_spikes,:) - repmat(dw_post(post_spikes),[1 n_pre]); % Homeostatic
            w(post_spikes,:) = max(w(post_spikes,:),0); % Hard bounds
            
            % Soft bounds
            %w(post_spikes,:) = w(post_spikes,:) -  w(post_spikes,:).*(1-w(post_spikes,:)).*repmat(dw_post(post_spikes),[1 n_pre]); % Homeostatic
        end

        V_post(post_spikes,mod(i-1,size(V_post,2))+1)=0;
        count = count+length(post_spikes);
    end
    
end

% Put V_post in correct order
V_post = [ V_post(:,mod(i-1,size(V_post,2))+2:end) V_post(:,1:mod(i-1,size(V_post,2))+1)];

if cursor == length(spike_list)+1
    warning('Increase initial size for spike_list array')
end
spike_list(cursor:end,:) = []; % remove unused values

if ~batch_mode
    save ../data/w w
end

disp([num2str(count/n_post) ' postsynaptic spikes per neuron (' num2str(count/n_period/period/n_post,'%.1f') 'Hz)'])

% if n_post==1
%     disp(['Expected V_noise = ' num2str( tau_m*sum(w)*f ) ])
%     disp(['Estimated peak 1 = ' num2str( tau_m*sum(w)*f + (1-exp(-tau_pre/tau_m))*( tau_m*sum(sum(pattern{1}(:,round(10e-3/dt+(1:tau_pre/dt)))))/tau_pre - tau_m*sum(w)*f ) )])
%     %disp(['Estimated peak 2 = ' num2str( tau_m*sum(w)*f + (1-exp(-tau_pre/tau_m))*( tau_m*sum(sum(pattern{1}(:,round(80e-3/dt+(1:tau_pre/dt)))))/tau_pre - tau_m*sum(w)*f ) )])
% end


perf % computes hit rates, false alarm rate etc.
% estimate_SNR

toc

if batch_mode
    exit
end

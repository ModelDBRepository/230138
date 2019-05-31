% This code was used in: Masquelier T (2017) STDP allows close-to-optimal spatiotemporal spike pattern detection by single coincidence detector neurons. Neuroscience.
% https://doi.org/10.1016/j.neuroscience.2017.06.032
% Jan 2017
% timothee.masquelier@cnrs.fr
%__________________________________________
% PARAMETERS

% Note: a period contains some Poisson activity followed by the
% presentation of (one of) the pattern(s).
%

% stimulation
f = 3.2; % mean rate in Hz
n_pattern = 1; % number of patterns
n_period_record = 1*n_pattern; % number of periods to record potential (for plotting)
n_period_record_spike = 100*n_pattern; % number of periods to estimate performance (hit rate and false alarm rate, ...)
n_period = 500*n_pattern + max(n_period_record_spike,n_period_record); % total number of periods
period = 4*2*50e-3; % period duration
pattern_duration = 2*50e-3; % pattern duration
n_pre = 1e4; % nb of presynaptic neurons
n_involved = n_pre; % number of afferents involved in the pattern(s)
delta_t = 23e-3; % expected duration of the reinforced subsequence
jitter = 3.2e-3; % each pattern spike is shifted by a random lag uniformly distributed in [-jitter,jitter]

n_thr = 9; % Nb of different threshold values (for parameter search)
n_dw_post = 17; % Nb of different dw_post values (for parameter search)
n_post = n_thr*n_dw_post; % nb of postynaptic neurons
%n_post = 2;

% Spike timing-dependent plasticity (STDP). See Song, Miller & Abbott 2000 Nat Neurosc
tau_pre = 20e-3; % LTP time constant
tau_post = 10e-3; % LTD time constant

da_pre = 1e-2; % LTP variable increase (at each presynatpic spike)
%da_post = 0*1.0*exp(log(1.1)*floor((0:n_post-1)/n_thr))'*da_pre; % LTD variable increase (at each postsynaptic spike)
da_post = zeros(n_post,1); % LTD variable increase (at each postsynaptic spike)

% Homeostatic (at each postsynaptic spike, all the synaptic weights are decreased by this value. Use an array of different values for parameter seach)
dw_post = 1.1^-2*da_pre*exp(-delta_t/tau_pre)*exp(log(1.1)*floor((0:n_thr*n_dw_post-1)/n_thr-(n_dw_post-1)/2))'; 
%dw_post = 1.1.^[1 -7]'*da_pre*exp(-delta_t/tau_pre); % (the two values used in the paper)

% Neurons
tau_m = 18e-3; % Membrane time constant
tau_s = 0*5e-3; % Synapse time constant. Put 0 for instantaneous synapse.
dt = .1e-3; % Time step
if jitter==0
    coef = (1-exp(-delta_t/tau_m));
else
    coef = min(1,delta_t/(2*jitter))-tau_m/(2*jitter)*log(1-exp(-max(2*jitter,delta_t)/tau_m)+exp(-abs(2*jitter-delta_t)/tau_m));
end
% Threshold. Use an array of different values for parameter seach.
thr =  1.1^-3*(tau_m*n_involved*f*(1-exp(-f*delta_t))+coef*tau_m*n_involved*f*exp(-delta_t*f))*repmat( exp(log(1.1)*(-(n_thr-1)/2:(n_thr-1)/2))',n_dw_post,1); 
%thr =  1.1.^[-1 -5]'*(tau_m*n_involved*f*(1-exp(-f*delta_t))+coef*tau_m*n_involved*f*exp(-delta_t*f)); % (the two values used in the paper)

initial_distance_to_threshold = -2; % distance between E(V) and thr divided by std(V) (negative <=> mean driven regime; positive <=> fluctuation driven regime)

disp(['E(n_selected)=' num2str(n_involved*(1-exp(-f*delta_t))) ])
disp(['E(V_noise)=' num2str(tau_m*n_involved*f*(1-exp(-f*delta_t))) ])
disp(['thr=' num2str(thr(round((length(thr)+1)/2)))])
%disp(['thr=' num2str(thr(end))])


% % Rapidly adapting thr (Fontaine et al PCB 2014)
% tau_thr = Inf; % put Inf not to use
% V_thr = 0;
% if tau_thr < Inf
%     exp_filter = exp(-(0:dt:5*tau_thr)/tau_thr);
%     epsp = exp(-(0:dt:5*tau_m)/tau_m)-exp(-(0:dt:5*tau_m)/tau_s);
%     epsp = epsp/max(epsp);
%     effective_epsp = epsp-filter(exp_filter,sum(exp_filter),epsp);
%     coef = mean(effective_epsp)/mean(epsp);
%     coef = .019;
% else
%     coef = 1;
% end

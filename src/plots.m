%__________________________________________
% PLOTTING
T = min(20*n_pattern*period,n_period_record*period)-dt;
%T = (n_period_record-1)*period;
n = round(T/dt)-1;

neuron_subset = 1:n_post;
%neuron_subset = 5*11+6;

stop = size(V_post,2);

figure
co = brighten(get(gcf,'DefaultAxesColorOrder'),.8);

subplot(2,1,1)
for i=1:T/period
    rectangle('Position',[(n_period_record+1-i)*period-pattern_duration-jitter,0,pattern_duration,max(thr)],'FaceColor',co(mod(i-1,n_pattern)+1,:),'EdgeColor','none')
    hold on
end
plot(dt*(max(stop-n,1):stop),V_post(neuron_subset,max(stop-n,1):stop)')
xlabel('t (s)')
ylabel('Postsynaptic potentials')
xlim(dt*[max(stop-n,1) stop])
legend([ int2str(thr(neuron_subset)) repmat('-',length(thr(neuron_subset)),1) num2str(dw_post(neuron_subset)/da_pre,2) ])

subplot(2,1,2)
for i=1:n_post
    spike = dt*(max(stop-n,1)-1+find(V_post(i,max(stop-n,1):stop)==0 & V_post(i,(max(stop-n,1):stop)-1)));
    plot(spike,i*ones(size(spike)),'.')
    hold on
end
xlim(dt*[max(stop-n,1) stop])



figure
hist(w(neuron_subset,:)',20)
xlim([0 1])
ylabel('#')
xlabel('Normalized synaptic weights')



if length(neuron_subset)<=3
    for i=1:length(neuron_subset)
        figure('Name',['Neuron #' int2str(neuron_subset(i))],'Position',[1 1 n_pattern+2 4]*200,'Units','centimeters')
        for p=1:n_pattern
            subplot(1,n_pattern,p)
            %im = pattern{p} .* repmat(w',1,size(pattern{p},2));
            %imagesc(im);
            for a=1:n_pre
                spike_time = find(pattern{p}(a,:))*dt;
                plot(spike_time,a*ones(size(spike_time)),'.','Color',w(neuron_subset(i),a)*[1 0 0]+(1-w(neuron_subset(i),a))*[0 0 1],'MarkerSize',12)
                hold on
            end
            
        end
    end
end

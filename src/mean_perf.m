% Computes the mean performance of several simulations (with different
% random seeds), for example produced using batch.py

path = '../data/';
%path = [ path 'thr_70_ltd_0.16/' ];
%path = [ path 'thr_40_ltd_0.15_ts_0/' ];

optimal_n_w = 710;

list = dir([path 'perf-*.mat']);
disp(['Displaying mean of ' int2str(length(list)) ' perf files' ])
for l=1:length(list)
    load([ path list(l).name ])
    if l==1
        miss_ = miss;
        false_alarm_ = false_alarm;
        hit_ = (hit>=90 & hit<=110);
        w_ = abs((n_w-optimal_n_w)/optimal_n_w)<.1;
    else
        miss_ = miss_ + miss;
        false_alarm_ = false_alarm_ + false_alarm;
        %hit_ = hit_ + (hit>=2*90 & hit<=2*110);
        hit_ = hit_ + hit;
        w_ = w_ + ( abs((n_w-optimal_n_w)/optimal_n_w)<.1 & miss<=90);
    end
    if l<=0
        figure('Name',list(l).name)
        imagesc(reshape(1-( (hit>=95 & hit<=105) ),n_thr,n_dw_post),[0 1])
    end
end
miss_ = miss_/length(list);
false_alarm_ = false_alarm_/length(list);
hit_ = hit_/length(list);
w_ = w_/length(list);

max_miss = n_period_record_spike/n_pattern;
max_fa = n_period_record_spike;

figure('Position',[10 10 30 25]*20,'Units','centimeters')

subplot(2,2,1)
imagesc(reshape(false_alarm_,n_thr,n_dw_post),[0 max_fa])
colorbar
ylabel('thr')
xlabel('LTD')
title('False alarms')

subplot(2,2,2)
imagesc(reshape(sum(miss_,2),n_thr,n_dw_post),[0 max_miss])
colorbar
ylabel('thr')
xlabel('LTD')
title('Misses')

% subplot(2,2,3)
% imagesc(reshape(min(max_miss,sum(miss_,2))/max_miss+min(max_fa,false_alarm_')/max_fa,n_thr,n_dw_post),[0 1])
% colorbar
% ylabel('thr')
% xlabel('LTD')
% title('Combined score')
subplot(2,2,3)
imagesc(reshape(1-w_,n_thr,n_dw_post),[0 1])
%imagesc(reshape(w_,n_thr,n_dw_post),[300 400])
colorbar
ylabel('thr')
xlabel('LTD')
title('Optimal n_w')


subplot(2,2,4)
%imagesc(reshape(1-sum(hit_,2),n_thr,n_dw_post),[0 1])
imagesc(reshape(sum(hit_,2),n_thr,n_dw_post))
colorbar
ylabel('thr')
xlabel('LTD')
title('Hits')

colormap jet

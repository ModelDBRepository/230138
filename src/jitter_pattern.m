function jittered_pattern = jitter_pattern(pattern,jitter,f,dt)

n = size(pattern,1);
extended_pattern = [ sparse( rand(n,2*jitter/dt)<dt*f ) pattern sparse( rand(n,2*jitter/dt)<dt*f ) ];
m = size(extended_pattern,2);
jittered_pattern = logical(sparse(n,m));

for s = find(extended_pattern)'
    [current_line, current_col] = ind2sub([n,m],s);
    new_col = current_col + round(2*(rand-.5)*jitter/dt);
    if new_col>0 && new_col<=m
%         if jittered_pattern(current_line,new_col)
%             warning('Overwriting a spike')
%         end
        jittered_pattern(current_line,new_col) = true;
    end
end

jittered_pattern = jittered_pattern(:,jitter/dt+1:end-jitter/dt);

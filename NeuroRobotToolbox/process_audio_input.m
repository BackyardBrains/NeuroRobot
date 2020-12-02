
if rak_only
    
    % Get audio data from RAK
    this_audio = double(rak_cam.readAudio());
%     disp(num2str(length(this_audio)))

    if isempty(this_audio)
        max_freq = 0;
        max_amp = 0;
        
        % rak_cam.readAudio sometimes returns an empty this_audio, but
        % somehow then returns a full this_audio in the same step. if a
        % full audio array is not eventally returned the RAK has to be
        % reset (rak_fail = 1);
        audio_empty_flag = audio_empty_flag + 1;
    elseif length(this_audio) >= 500

        max_freq = 0;
        max_amp = 0;   
        
        if length(this_audio) < 1000
            while length(this_audio) < 1000
                this_audio = [this_audio this_audio];
            end
            this_audio = this_audio(1:1000);
        end
        if xstep == 1
            this_audio = zeros(1, 1000);
        end        
        audx_flips = 0;
        if length(this_audio) >= 1000
            audx_flips = floor(length(this_audio)/1000);
            audx_pws = zeros(audx, audx_flips);
            for audx_flip = 1:audx_flips
                x = this_audio((1:1000) + ((audx_flip - 1) * 1000));
                
                % Get spectrum
                x(isnan(x)) = 0;        
                n = length(x);
                if hd_camera
                    fs = 32000;
                    dt = 1/fs;
                    t = (0:n-1)/fs;
                    y = fft(x);
                    pw = (abs(y).^2)/fs;
                else
                    fs = 8000;
                    dt = 1/fs;
                    t = (0:n-1)/fs;
                    y = fft(x);
                    pw = (abs(y).^2)/fs;          
                end
                if ~isempty(pw)
                    audx_pws(:,audx_flip) = pw(1:audx);
                end
                
            end
        
        end

        if audx_flips > 1
            pw = max(audx_pws, [], 2);
        else
            pw = audx_pws;
        end
        audio_empty_flag = 0;


        
%         %%% new audio stuff
        monkey_base = mean(pw(1:20));   
        temp436(:,nstep) = pw(1:audx);
        temp332(1, nstep) = mean(temp436(5:10, nstep));
        temp332(2, nstep) = mean(temp436(62:64, nstep));
        temp332(3, nstep) = mean(temp436(:, nstep));
        if nstep == nsteps_per_loop
%             figure(10); clf; set(gcf, 'position', [100 100 1720 880]); plot(temp332(1,:), 'r'); hold on; plot(temp332(2,:), 'k'); plot(temp332(3,:), 'b'); set(gca, 'ylim', [0 10^-4]);
%             figure(10); clf; set(gcf, 'position', [100 100 1720 880]); imagesc(temp436(:, :), [0 (10^-5) * 0.7]);
%             disp(horzcat('Infrasonic 5th percentile: ', num2str(prctile(temp332, 5))))
        end
%         %%%
        
        pw = (pw - mean(pw)) / std(pw);
        pw(1:10) = 0;
        [max_amp, j] = max(pw(1:audx));
        fx = linspace(0, 5000, audx);
        max_freq = fx(j);
        if max_amp < 8
            max_amp = 0;
            max_freq = 0;
        end
        
%         disp(horzcat('max_amp: ', num2str(max_amp), ', max_freq: ', num2str(max_freq)))
        
    else
        
        if ~rem(nstep, 40)
            disp(horzcat('this_audio has unexpected length (showing 1 of 40 errors)'))
            disp(horzcat('= ', num2str(length(this_audio))))
        end        
        max_freq = 0;
        max_amp = 0;
    end
    
    audio_max_freq = max_freq;

else % Implement audio toolbox record here 
    
    if audio_test
        
        tim1 = tic;
        
        recordblocking(audio_recObj,0.1)
        this_audio = getaudiodata(audio_recObj);       
        audx_flips = 0;
        audx_pws = zeros(audx, 1);
        if length(this_audio) >= 1000
            audx_flips = floor(length(this_audio)/1000);
            audx_pws = zeros(audx, audx_flips);
            for audx_flip = 1:audx_flips
                x = this_audio((1:1000) + ((audx_flip - 1) * 1000));
                
                % Get spectrum
                x(isnan(x)) = 0;        
                n = length(x);
                fs = 16000;
                dt = 1/fs;
                t = (0:n-1)/fs;
                y = fft(x);
                pw = (abs(y).^2)/fs;
                if ~isempty(pw)
                    audx_pws(:,audx_flip) = pw(1:audx);
                end
                
            end
        
        end

        if audx_flips > 1
            pw = max(audx_pws, [], 2);
%             pw = mean(audx_pws, 2);
        else
            pw = audx_pws;
        end
        
        temp436(:,nstep) = pw(1:audx);
        
%         disp(horzcat('Webcam sound aquired and processed in ', num2str(toc(tim1)), ' seconds'))
        
    end
end


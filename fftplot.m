function fftplot(y,fs,type,graphTitle)
    %%% Plot fft of signal with normalized magnitude
    N = length(y);
    f = fs*(0:N-1)/N; %frequency range
    yfft = fft(y);
    if strcmp(type,'mag')
        normfft = abs(yfft)./max(abs(yfft));
        plot(f,normfft); %plot
        ylabel('Normalized Magnitude');
    elseif strcmp(type,'phase')
        plot(f,angle(yfft));
        ylabel('Angle (rad)');
    else
        error('invalid type')
    end
    xlim([0 1000]); %limit to half
    xlabel('Frequency (Hz)');
    title(graphTitle);
end
function fftplot(y,fs,graphTitle)
    %%% plot fft of signal
    N = length(y);
    f = fs*(0:N-1)/N; %frequency range
    yfft = abs(fft(y));
    plot(f,yfft); %plot
    xlim([0 1000]); %limit to half
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    title(graphTitle);
end
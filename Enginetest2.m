clear all; clear variables; clc; close all
dbstop if warning

%noiseLevel  =  randi([0 20]);

% Sampling freq for specgram
    Fs = 120e4;

for noiseLevel = 0:20
    clearvars -global;
sumForSpec = [];
total1 = 0;
total2 = 0;
for i = 1:15
   
    % Transmitters
    
    [sig1,bits1, gain1] = txBridgeKat();
    [sig2,bits2, gain2] = tx1();
    
    sum = sig1 + sig2;
    sumNoisy = awgn(sum, noiseLevel, 1);
 
    
    % append;
    sumForSpec =  [sumForSpec, sumNoisy];
    
    
    % check the SER
   total1 = total1 + rxBridgeKat(sumNoisy,bits1, gain1);
   total2 = total2 + rx1(sumNoisy,bits2, gain2);
end

noiseLevel
[total1, total2]
%figure(noiseLevel +1);
spectrogram(sumForSpec,64,[],[],Fs,'yaxis')
end



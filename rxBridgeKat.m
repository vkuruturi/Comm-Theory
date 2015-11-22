function [numCorrect] = rxBridgeKat(sig, bits, gain)
%% Receive input sig, compute BER relative to bits

% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;
%M = 4; fsep = 8; nsamp = 8; Fs = 32;

% THE ABOVE CODE IS PURE EVIL


numCorrect = 0; % initialize the # of correct Rx bits

% Global variable for feedback
global alpacas;
global last_snr
global prev_try     %state val to keep track of last attempt's success
if isempty(prev_try)
    prev_try = 1;
end

uint8(alpacas);

% in this example, just using feedback to set the freq index
tonecoeff = alpacas;

%% I don't recommend touching the code below
% Generate a carrier
carrier = fskmod(tonecoeff*ones(1,1024),M,fsep,nsamp,Fs);
rx = sig.*conj(carrier).*gain;
rx = intdump(rx,nsamp);
%% Recover your signal here
success = 0;

if prev_try < 2
    BCH_n = 1023;
    QAM_BCH_values = {[4 1003],[8 758],[8 903],[8 953],[16 848],[16 893],[16 943], [16 973],...
         [32 883],[32 903],[32 903], [32 933], [32, 943], [64 903], [64 933], [64 943], ...
         [64 973],[64 993],[64 1013],[64 1013], [64 1013]};
    SNR_values = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
    bitrate_select = containers.Map(SNR_values, QAM_BCH_values);
    if isempty(last_snr)
        snr = 0;
    else
        snr = mode(last_snr);
        if snr >20
            snr  = 20;
        end
    end
    bitrate = bitrate_select(snr);

    msgM = bitrate(1);
    BCH_k = bitrate(2);

    k = log2(msgM);

    rxMsg = qamdemod(rx,msgM,0,'gray');
    rx1 = de2bi(rxMsg,'left-msb');
    rx1_resh = reshape(rx1.',[],1);
    rx1_bits = rx1_resh(1024*k-(floor(1024*k/BCH_n)*BCH_n)+1:end);
    rx1_bits_dec = bchdec(gf(reshape(rx1_bits,BCH_n,[])).',BCH_n,BCH_k);
    rx1_bits_final = reshape(double(rx1_bits_dec.x).',[],1);


    % Check the BER. If zero BER, output the # of correctly received bits.
    ber = biterr(rx1_bits_final, bits);

    if ber == 0
        %disp('Sucessful frame User 2')
        numCorrect = length(bits);
        success = 1;
    else
        success = 0;
       % scatterplot(rx)
    end

    SNR_val = (round(-10*log10(abs(var(sig)-2))+1));
    if SNR_val >= 20
        SNR_val = 20;
    end
    last_snr = [last_snr SNR_val];
end
% check if you should switch to a new frequency
switch_chan = 0;
if success == 0
    if prev_try == 0
        switch_chan = 1;
        prev_try = 2;
    else
        prev_try = prev_try - 1;
    end
else
    prev_try = 1;
end
        
    
SNR_tx = mode(last_snr);
alpacas = (SNR_tx + (success)*2^6 + switch_chan*2^5);
% set the new value for the feedback here
% You probably want to do somehting more intelligent


end
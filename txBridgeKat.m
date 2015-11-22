function [tx, bits, gain] = txBridgeKat()
% Example Transmitter. Outputs modulated data tx, and original data stream
% data for checking error rate at receiver.
% Your team will be assigned a number, rename your function txNUM.m
% Also rename the global variable tofeedbackNUM

% Global variable for feedback
% you may use the following uint8 for whatever feedback purposes you want
global prev_tone;
global transmit;            %flag to test whether we can transmit or not
global alpacas;             %b0-b4 are SNR, b5 is a flag for whether we switch channels or not
                            %b6 is a flag for if the receiver encountered
                            %errors
uint8(alpacas);



% DO NOT TOUCH BELOW
fsep = 8e4;
nsamp = 16;
Fs = 120e4;
M = 16;   % THIS IS THE M-ARY # for the FSK MOD.  You have 16 channels available
% THE ABOVE CODE IS PURE EVIL



% initialize, will be set by rx after 1st transmission
if isempty(alpacas)
    alpacas = 0;
    tonecoeff = 5;              %use channel 5 at the start
    transmit = 1;
else
    tonecoeff = prev_tone;      %use the same tone as the last transmission
end



%% You should edit the code starting here
% Tone to transmit the data on
% SELECT QAM BASED ON SNR
BCH_n = 1023;                   %codeword length for BCH encoding 
feedback_b = de2bi(alpacas, 8);

if feedback_b(6) == 1;
    tonecoeff = randi(15);
    transmit = 0;
end


% hashtable containing what QAM and message lengths should be used at each SNR
QAM_BCH_values = {[4 1003],[8 758],[8 903],[8 953],[16 848],[16 893],[16 943], [16 973],...
     [32 883],[32 903],[32 903], [32 933], [32, 943], [64 903], [64 933], [64 943], ...
     [64 973],[64 993],[64 1013],[64 1013], [64 1013]};
SNR_values = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20};
bitrate_select = containers.Map(SNR_values, QAM_BCH_values);

bleh = [1 2 4 8 16];
snr = sum(bleh.*feedback_b([1:5]));
bitrate = bitrate_select(snr);

msgM = bitrate(1);
BCH_k = bitrate(2);


k = log2(msgM);


bits = randi([0 1],BCH_k/BCH_n*(floor(1024*k/BCH_n)*BCH_n),1);
bits_reshaped = reshape(bits, BCH_k, []).';
bits_enc_1 = bchenc(gf(bits_reshaped),BCH_n, BCH_k);
bits_enc = [ ones(1024*k - (floor(1024*k/BCH_n)*BCH_n), 1); reshape(double(bits_enc_1.x).',[],1);];

syms = bi2de(reshape(bits_enc,k,length(bits_enc)/k).','left-msb')';
% Random 4-QAM Signal
msg = qammod(syms,msgM,0, 'gray');
msglength = length(msg);

if(msglength ~= 1024)
    error('You smurfed up')
end




%% You should stop editing code starting here

%% Serioulsy, Stop.

% Generate a carrier
% don't mess with this code either, just pick a tonecoeff above from 0-15.
carrier = fskmod(tonecoeff*ones(1,msglength),M,fsep,nsamp,Fs);
%size(carrier); % Should always equal 16484
% upsample the msg to be the same length as the carrier
msgUp = rectpulse(msg,nsamp);

% multiply upsample message by carrier  to get transmitted signal
tx = msgUp.*carrier;

gain = std(tx);
if(transmit ==0) % if i'm not allowed to transmit, just set bits to all 0
  tx = zeros(size(tx));
  size(tx)
  gain = 1;
  transmit = 1;
end
% scale the output
tx = tx./gain;
alpacas = tonecoeff;
prev_tone = tonecoeff;

end
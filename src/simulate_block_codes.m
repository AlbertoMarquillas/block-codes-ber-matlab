% simulate_block_codes.m
% BER simulation for Linear Block Code and Hamming Code over a BSC channel

% CONSTANTS
% Define the number of bits to simulate per value of channel error probability p.
% The total (4e5) is divided into packets of 100,000 bits to make the simulation more efficient and modular.

nbitsPacket = 100000;          % Number of bits per packet
nbitsTotal = 4e5;              % Minimum number of bits to simulate per p value
nPackets = ceil(nbitsTotal / nbitsPacket); % Number of packets to simulate

% TRANSITION PROBABILITIES (from 0.1 to 0.01, 9 values)
% Compute the 9 values of the BSC channel error probability. They are logarithmically 
% distributed between 0.01 and 0.1. This p will be used to simulate transmission errors.

k_vec = 0:8;
p = 10.^((k_vec - 16)/8);

% CODE PARAMETERS
% Define encoding parameters (k, n) for each of the two codes:
% Linear code (5,2)
% Hamming code (7,4)

k_lin = 2;
n_lin = 5;
k_ham = 4;
n_ham = 7;

% CODE MATRICES
% G_linear is the generator matrix of the general linear code provided in the assignment.
% G_hamming is obtained with the hammgen(3) function, which generates the matrix for a Hamming code with parameter m=3 (thus (7,4)).

G_linear = [1 0 1 1 0; 1 1 1 0 1]; % given generator matrix
[~, G_hamming] = hammgen(3);      % Hamming code (7,4)

% SYNDROME TABLE (only for linear code)
% Compute the syndrome table for the linear code from its generator matrix.
% This table optimizes decoding by making it faster (direct lookup).

synd_linear = syndtable(gen2par(G_linear));

% BER RESULTS
% Initialize vectors to store the BER (bit error rate) of each code for each value of p.
BER_hamming = zeros(1, length(p));
BER_linear = zeros(1, length(p));

% START SIMULATION
% Begin the main simulation loop. Iterate over each value of channel error probability p(i).
% Initialize error counters to zero for this value of p.
for i = 1:length(p)
    errH = 0;
    errL = 0;
    % Create as many words as needed to reach nbitsPacket in each packet.
    % Each row of mH and mL is a message word of k bits.
    for j = 1:nPackets
        % MESSAGE GENERATION
        mH = randi([0 1], ceil(nbitsPacket / k_ham), k_ham);
        mL = randi([0 1], ceil(nbitsPacket / k_lin), k_lin);

        % ENCODING
        % Encode each word using the corresponding code.
        % encode returns a matrix where each row is a codeword of n bits.
        % For the linear code the generator matrix is specified manually.
        cH = encode(mH, n_ham, k_ham, 'hamming/binary');
        cL = encode(mL, n_lin, k_lin, 'linear/binary', G_linear);

        % TRANSMISSION THROUGH BSC CHANNEL
        % Simulate the BSC channel: each bit has a probability p(i) of being flipped.
        % Obtain the received codewords (with errors) rH and rL.
        rH = bsc(cH, p(i));
        rL = bsc(cL, p(i));

        % DECODING
        % Decode the received codewords.
        % For Hamming, MATLAB already knows the syndrome table.
        % For the linear code, explicitly pass the syndrome table (synd_linear) to improve speed.
        dH = decode(rH, n_ham, k_ham, 'hamming/binary');
        dL = decode(rL, n_lin, k_lin, 'linear/binary', G_linear, synd_linear);

        % ERROR COUNTING
        % Count how many decoded bits do not match the original bits.
        % biterr compares the matrices and returns the total number of errors.
        errH = errH + biterr(mH, dH);
        errL = errL + biterr(mL, dL);
    end

    % FINAL BER FOR THIS p VALUE
    % Compute BER by dividing accumulated errors by total number of transmitted bits.
    % BER_hamming(i) and BER_linear(i) store the result for this p(i).
    bits_H = ceil(nbitsPacket / k_ham) * k_ham * nPackets;
    bits_L = ceil(nbitsPacket / k_lin) * k_lin * nPackets;

    BER_hamming(i) = errH / bits_H;
    BER_linear(i) = errL / bits_L;
end

% FINAL PLOT
% Plot BER in a log-log graph.
% Display the two curves with different colors.
% Allows visual comparison of the performance of both codes as channel error increases.
figure;
loglog(p, BER_hamming, '-ob', p, BER_linear, '-or', 'LineWidth', 2);
xlabel('Channel error probability (p)');
ylabel('Bit Error Rate (BER) after decoding');
legend('Hamming (7,4)', 'Linear (5,2)', 'Location', 'southwest');
title('BER Simulation for Block Codes over BSC Channel');
grid on;

disp('BER Hamming:');
disp(BER_hamming);
disp('BER Linear:');
disp(BER_linear);

saveas(gcf, 'docs/assets/grafica_BER_AC2.png');
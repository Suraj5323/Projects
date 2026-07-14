%% ============================================================
%% FIR Filter Design, Signal Generation & Verilog Verification
%% Sampling Freq = 10000 Hz | Cutoff = 1000 Hz | Taps = 100
%% Q(2,14) Fixed Point Format
%% ============================================================

clear; clc; close all;

%% ---- PARAMETERS ----
fs  = 10000;   % Sampling frequency (Hz)
fc  = 1000;    % Cutoff frequency (Hz)
N   = 100;     % Number of taps
Q   = 14;      % Fractional bits in Q(2,14)
dur = 0.1;     % Signal duration (seconds) = 1000 samples

%% ============================================================
%% PART 1: DESIGN FIR FILTER USING fir1()
%% ============================================================

% fir1(order, normalized_cutoff)
% order = N-1 = 99
% normalized cutoff = fc / (fs/2) = 1000/5000 = 0.2
h = fir1(N-1, fc/(fs/2));

fprintf('=== FIR Filter Designed ===\n');
fprintf('Taps         : %d\n', N);
fprintf('Cutoff       : %d Hz\n', fc);
fprintf('Sampling Freq: %d Hz\n', fs);
fprintf('Coeff range  : [%.6f, %.6f]\n', min(h), max(h));

%% ---- Convert coefficients to Q(2,14) fixed point ----
h_fixed = round(h * 2^Q);
fprintf('Q(2,14) range: [%d, %d]\n', min(h_fixed), max(h_fixed));

% Save all 100 coefficients (used by Direct Form and genvar)
fid = fopen('coeffs.txt', 'w');
for i = 1:N
    fprintf(fid, '%d\n', h_fixed(i));
end
fclose(fid);

% Save first 50 coefficients only (used by Optimized/Symmetric Form)
fid = fopen('coeffs_half.txt', 'w');
for i = 1:N/2
    fprintf(fid, '%d\n', h_fixed(i));
end
fclose(fid);

fprintf('Saved: coeffs.txt (100 values), coeffs_half.txt (50 values)\n\n');

%% ============================================================
%% PART 2: GENERATE 3 SINEWAVES AND CONVERT TO Q(2,14)
%% ============================================================

t = (0 : 1/fs : dur - 1/fs);    % Time vector: 1000 samples

s1 = sin(2*pi*950 *t);   %  950 Hz -> BELOW cutoff -> should PASS
s2 = sin(2*pi*1100*t);   % 1100 Hz -> ABOVE cutoff -> should be ATTENUATED
s3 = sin(2*pi*2000*t);   % 2000 Hz -> WELL ABOVE   -> should be BLOCKED

% Convert to Q(2,14) integers
s1_fixed = round(s1 * 2^Q);
s2_fixed = round(s2 * 2^Q);
s3_fixed = round(s3 * 2^Q);

signals_fixed = {s1_fixed, s2_fixed, s3_fixed};
freqs = [950, 1100, 2000];

% Save signal files
for i = 1:3
    fid = fopen(sprintf('signal%d.txt', i), 'w');
    fprintf(fid, '%d\n', signals_fixed{i});
    fclose(fid);
    fprintf('Saved signal%d.txt (%d Hz, %d samples)\n', i, freqs(i), length(t));
end

fprintf('\nQ(2,14) signal range: [%d, %d]\n\n', min(s1_fixed), max(s1_fixed));

%% ============================================================
%% PART 3: FILTER SIGNALS IN MATLAB (REFERENCE OUTPUT)
%% ============================================================

y1_matlab = filter(h, 1, s1);
y2_matlab = filter(h, 1, s2);
y3_matlab = filter(h, 1, s3);

fprintf('=== MATLAB Reference Filtering Done ===\n');
fprintf('Signal 1 (950 Hz)  output amplitude: %.4f\n', max(abs(y1_matlab(end-100:end))));
fprintf('Signal 2 (1100 Hz) output amplitude: %.4f\n', max(abs(y2_matlab(end-100:end))));
fprintf('Signal 3 (2000 Hz) output amplitude: %.4f\n', max(abs(y3_matlab(end-100:end))));

%% ---- Plot MATLAB Filter Outputs ----
figure('Name', 'MATLAB FIR Filter Output (Reference)', 'Position', [100 100 1000 700]);

subplot(3,1,1);
plot(t, s1, 'b--', 'LineWidth', 0.8); hold on;
plot(t, y1_matlab, 'r', 'LineWidth', 1.5);
title('Signal 1: 950 Hz  [BELOW Cutoff -> Should PASS]');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Input s1', 'Filtered y1'); grid on;
ylim([-1.2 1.2]);

subplot(3,1,2);
plot(t, s2, 'b--', 'LineWidth', 0.8); hold on;
plot(t, y2_matlab, 'r', 'LineWidth', 1.5);
title('Signal 2: 1100 Hz [ABOVE Cutoff -> Should be ATTENUATED]');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Input s2', 'Filtered y2'); grid on;
ylim([-1.2 1.2]);

subplot(3,1,3);
plot(t, s3, 'b--', 'LineWidth', 0.8); hold on;
plot(t, y3_matlab, 'r', 'LineWidth', 1.5);
title('Signal 3: 2000 Hz [WELL ABOVE Cutoff -> Should be BLOCKED]');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Input s3', 'Filtered y3'); grid on;
ylim([-1.2 1.2]);

sgtitle('MATLAB FIR Filter Output (Reference)', 'FontSize', 14, 'FontWeight', 'bold');



%% ============================================================
%% PART 4: VERILOG OUTPUT VERIFICATION (SEPARATE PLOTS)
%% ============================================================

methods     = {'direct', 'optimized', 'genvar'};
y_ref       = {y1_matlab, y2_matlab, y3_matlab};
freq_labels = {'950 Hz (Pass)', '1100 Hz (Atten)', '2000 Hz (Block)'};

fprintf('=== Verilog Output Verification ===\n');

all_match = true;

for m = 1:3
    
    figure('Name', upper(methods{m}), 'Position', [200 100 1000 900]);

    for s = 1:3
        
        fname = sprintf('output_%s_s%d.txt', methods{m}, s);

        if exist(fname, 'file')

            y_veri_raw   = load(fname);

            % Convert Q(4,28) -> float
            y_veri_float = double(y_veri_raw) / 2^28;

            n_pts = min(length(y_veri_float), length(y_ref{s}));

            mse = mean((y_ref{s}(1:n_pts) - y_veri_float(1:n_pts)').^2);
            snr_db = 10*log10(mean(y_ref{s}(1:n_pts).^2) / (mse + eps));

            % MATLAB output plot
            subplot(6,1,2*s-1)
            plot(t(1:n_pts), y_ref{s}(1:n_pts), 'b', 'LineWidth', 1.5);
            title(sprintf('MATLAB Output | %s', freq_labels{s}));
            ylabel('Amplitude');
            grid on;

            % Verilog output plot
            subplot(6,1,2*s)
            plot(t(1:n_pts), y_veri_float(1:n_pts), 'r', 'LineWidth', 1.5);
            title(sprintf('Verilog Output | %s | MSE=%.2e | SNR=%.1f dB', ...
                  freq_labels{s}, mse, snr_db));
            xlabel('Time (s)');
            ylabel('Amplitude');
            grid on;

            fprintf('%-12s | %s | MSE=%.3e | SNR=%.1f dB\n', ...
                    methods{m}, freq_labels{s}, mse, snr_db);

        else

            subplot(6,1,2*s-1)
            title(sprintf('%s | %s [File Not Found]', ...
                  upper(methods{m}), freq_labels{s}));

            text(0.5,0.5,sprintf('Run Verilog sim\n%s',fname), ...
                 'HorizontalAlignment','center','Units','normalized');

            all_match = false;

        end
    end

    sgtitle(sprintf('MATLAB vs Verilog Outputs (%s Method)', upper(methods{m})));

    % Save figure
    saveas(gcf, sprintf('comparison_%s.png', methods{m}));

end

if all_match
    fprintf('\n=== ALL VERILOG OUTPUTS VERIFIED SUCCESSFULLY ===\n');
else
    fprintf('\nSome output files not found. Run Verilog simulation first.\n');
end

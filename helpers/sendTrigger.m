function sendTrigger(triggerCode, config)
% SENDTRIGGER  Emit an event marker for fNIRS acquisition.
%
%   sendTrigger(triggerCode, config)
%
% For this pilot version the trigger is printed to the MATLAB console and,
% if config.trigger.writeToLog is true, appended to a text log file. The
% code blocks below are PLACEHOLDERS showing where to add real hardware
% output (LSL, serial, parallel port) for the NIRSport2 or a wearable NIRS.
%
% NOTE: triggerCode is a small positive integer (see per-task config.tN.trig).

t = GetSecs;

% Seconds since the session sync anchor (NaN before it is taken).
if isfield(config, 'sync')
    tRel = t - config.sync.tZeroGetSecs;
else
    tRel = NaN;
end

% ---- Always: console print (human-readable audit trail) ----------------
fprintf('[TRIGGER] code=%3d  t=%.4f  t_rel=%.4f\n', triggerCode, t, tRel);

% ---- Optional: append to a text log file -------------------------------
% Columns: getSecs, secondsSinceT0, triggerCode.
if isfield(config, 'trigger') && config.trigger.writeToLog
    try
        fid = fopen(config.trigger.logFile, 'a');
        if fid > 0
            fprintf(fid, '%.6f\t%.6f\t%d\n', t, tRel, triggerCode);
            fclose(fid);
        end
    catch
        % Never let logging break the experiment.
    end
end

% ---- Hardware output (enable one of these later) -----------------------
switch lower(config.trigger.method)
    case 'console'
        % Nothing more to do (default for the pilot).

    case 'lsl'
        % ---------------------------------------------------------------
        % LAB STREAMING LAYER (recommended for NIRSport2 via Aurora/LSL).
        % Requires the liblsl MATLAB wrapper on the path. Create the
        % outlet ONCE (e.g. in main) and reuse it; a persistent is shown
        % here for a self-contained example:
        %
        %   persistent outlet
        %   if isempty(outlet)
        %       lib = lsl_loadlib();
        %       info = lsl_streaminfo(lib, config.trigger.lslStreamName, ...
        %                             'Markers', 1, 0, 'cf_int32', 'lm_uid1234');
        %       outlet = lsl_outlet(info);
        %   end
        %   outlet.push_sample(int32(triggerCode));
        % ---------------------------------------------------------------

    case 'serial'
        % ---------------------------------------------------------------
        % SERIAL PORT (USB-serial trigger box / Arduino).
        %   persistent sp
        %   if isempty(sp)
        %       sp = serialport(config.trigger.serialPort, config.trigger.serialBaud);
        %   end
        %   write(sp, uint8(triggerCode), 'uint8');
        % ---------------------------------------------------------------

    case 'parallel'
        % ---------------------------------------------------------------
        % PARALLEL PORT (classic 8-bit TTL trigger; Windows + io64/io32).
        %   persistent ioObj address
        %   if isempty(ioObj)
        %       ioObj = io64(); io64(ioObj);
        %       address = config.trigger.parallelAddr;
        %   end
        %   io64(ioObj, address, triggerCode);   % raise
        %   WaitSecs(0.005);
        %   io64(ioObj, address, 0);             % clear
        % ---------------------------------------------------------------

    otherwise
        warning('sendTrigger:method', 'Unknown trigger method "%s".', config.trigger.method);
end
end

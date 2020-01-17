function niTClk_LoadLibrary()
    if (~libisloaded('niTClk'))
		prog_files_dir = getenv('ProgramFiles');
		visa_base_dir = fullfile(prog_files_dir, 'IVI Foundation\VISA');
		if strcmp(computer('arch'), 'win64')
            lib_name = 'niTClk_64.dll';
            visa_include_dir = fullfile(visa_base_dir, 'Win64\Include');
        else
            lib_name = 'niTClk.dll';
            visa_include_dir = fullfile(visa_base_dir, 'WinNT\Include');
        end
        loadlibrary(lib_name, 'niTClkml.h', ...
            'includepath', visa_include_dir, ...
            'alias', 'niTClk');

        %% Load Relevant Attributes, uncomment if needed
        % NITCLK_ATTR_SYNC_PULSE_SOURCE                                                = 1;
        % NITCLK_ATTR_EXPORTED_SYNC_PULSE_OUTPUT_TERMINAL                              = 2;
        % NITCLK_ATTR_START_TRIGGER_MASTER_SESSION                                     = 3;
        % NITCLK_ATTR_REF_TRIGGER_MASTER_SESSION                                       = 4;
        % NITCLK_ATTR_SCRIPT_TRIGGER_MASTER_SESSION                                    = 5;
        % NITCLK_ATTR_PAUSE_TRIGGER_MASTER_SESSION                                     = 6;
        % NITCLK_ATTR_TCLK_ACTUAL_PERIOD                                               = 8;
        % NITCLK_ATTR_EXPORTED_TCLK_OUTPUT_TERMINAL                                    = 9;
        % NITCLK_ATTR_SYNC_PULSE_CLOCK_SOURCE                                          = 10;
        % NITCLK_ATTR_SAMPLE_CLOCK_DELAY                                               = 11;
        % NITCLK_ATTR_SYNC_PULSE_SENDER_SYNC_PULSE_SOURCE                              = 13;
        % NITCLK_ATTR_SEQUENCER_FLAG_MASTER_SESSION                                    = 16;
        % NITCLK_VAL_SYNCHRONIZE_OPTIONS_NONE                                          = 0;
        % NITCLK_VAL_SYNCHRONIZE_OPTIONS_ALLOW_TCLK_DRIFT                              = 1;
        % NITCLK_VAL_ADJUSTMENT_TYPE_AUTO                                              = 0;
        % NITCLK_VAL_ADJUSTMENT_TYPE_TCLK_DIVISOR                                      = 1;
        % NITCLK_VAL_ADJUSTMENT_TYPE_TCLK_TIMEBASE                                     = 2;
        % NITCLK_VAL_ADJUSTMENT_TYPE_NONE                                              = 3;
        % NITCLK_SUCCESS                                                               = 0;
    end
end

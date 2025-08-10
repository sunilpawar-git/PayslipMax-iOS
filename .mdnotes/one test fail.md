Running tests...
    t =      nans Interface orientation changed to Portrait
Test Suite 'Selected tests' started at 2025-08-10 18:46:41.154.
Test Suite 'PayslipMaxUITests.xctest' started at 2025-08-10 18:46:41.154.
Test Suite 'BackupChecksumErrorUITests' started at 2025-08-10 18:46:41.154.
Test Case '-[PayslipMaxUITests.BackupChecksumErrorUITests testImportingBadChecksum_ShowsHelpfulErrorAndNoDataChange]' started.
    t =     0.00s Start Test at 2025-08-10 18:46:41.154
    t =     0.05s Set Up
    t =     0.05s Open com.app.payslipmax.PayslipMax
    t =     0.05s     Launch com.app.payslipmax.PayslipMax
    t =     1.27s         Setting up automation session
    t =     2.12s         Wait for com.app.payslipmax.PayslipMax to idle
    t =     3.50s Tap "Settings" Button
    t =     3.50s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     3.51s     Find the "Settings" Button
    t =     3.71s     Check for interrupting elements affecting "Settings" Button
    t =     3.73s     Synthesize event
    t =     4.02s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     4.06s Waiting 5.0s for "settings_row_button_Backup & Restore" Button to exist
    t =     5.09s     Checking `Expect predicate `existsNoRetry == 1` for object "settings_row_button_Backup & Restore" Button`
    t =     5.09s         Checking existence of `"settings_row_button_Backup & Restore" Button`
    t =     5.17s Tap "settings_row_button_Backup & Restore" Button
    t =     5.17s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     5.18s     Find the "settings_row_button_Backup & Restore" Button
    t =     5.22s     Check for interrupting elements affecting "settings_row_button_Backup & Restore" Button
    t =     5.26s     Synthesize event
    t =     5.55s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     5.55s Waiting 15.0s for "backup_sheet" Other to exist
    t =     6.57s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_sheet" Other`
    t =     6.57s         Checking existence of `"backup_sheet" Other`
    t =     6.68s Waiting 15.0s for "Import Data" StaticText to exist
    t =     7.70s     Checking `Expect predicate `existsNoRetry == 1` for object "Import Data" StaticText`
    t =     7.70s         Checking existence of `"Import Data" StaticText`
    t =     7.80s Waiting 5.0s for "backup_import_container" Other to exist
    t =     8.83s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_import_container" Other`
    t =     8.84s         Checking existence of `"backup_import_container" Other`
    t =     8.95s         Capturing element debug description
    t =     9.86s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_import_container" Other`
    t =     9.87s         Checking existence of `"backup_import_container" Other`
    t =     9.96s         Capturing element debug description
    t =    10.89s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_import_container" Other`
    t =    10.89s         Checking existence of `"backup_import_container" Other`
    t =    10.98s         Capturing element debug description
    t =    11.80s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_import_container" Other`
    t =    11.80s         Checking existence of `"backup_import_container" Other`
    t =    11.90s         Capturing element debug description
    t =    12.80s     Checking `Expect predicate `existsNoRetry == 1` for object "backup_import_container" Other`
    t =    12.80s         Checking existence of `"backup_import_container" Other`
    t =    12.86s         Capturing element debug description
    t =    12.87s     Checking existence of `"backup_import_container" Other`
    t =    12.93s Collecting debug information to assist test failure triage
    t =    12.93s     Requesting snapshot of accessibility hierarchy for app with pid 97022
/Users/sunil/Downloads/PayslipMax/PayslipMaxUITests/Critical/BackupChecksumErrorUITests.swift:29: error: -[PayslipMaxUITests.BackupChecksumErrorUITests testImportingBadChecksum_ShowsHelpfulErrorAndNoDataChange] : XCTAssertTrue failed
    t =    13.13s Tear Down
Test Case '-[PayslipMaxUITests.BackupChecksumErrorUITests testImportingBadChecksum_ShowsHelpfulErrorAndNoDataChange]' failed (13.358 seconds).
Test Suite 'BackupChecksumErrorUITests' failed at 2025-08-10 18:46:54.513.
	 Executed 1 test, with 1 failure (0 unexpected) in 13.358 (13.359) seconds
Test Suite 'PayslipMaxUITests.xctest' failed at 2025-08-10 18:46:54.514.
	 Executed 1 test, with 1 failure (0 unexpected) in 13.358 (13.360) seconds
Test Suite 'Selected tests' failed at 2025-08-10 18:46:54.515.
	 Executed 1 test, with 1 failure (0 unexpected) in 13.358 (13.361) seconds
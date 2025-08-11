Running tests...
Failed to send CA Event for app launch measurements for ca_event_type: 0 event_name: com.apple.app_launch_measurement.FirstFramePresentationMetric
Failed to send CA Event for app launch measurements for ca_event_type: 1 event_name: com.apple.app_launch_measurement.ExtendedLaunchMetrics
    t =      nans Interface orientation changed to Portrait
Test Suite 'Selected tests' started at 2025-08-11 15:09:18.462.
Test Suite 'PayslipMaxUITests.xctest' started at 2025-08-11 15:09:18.462.
Test Suite 'DiagnosticsExportFlowTests' started at 2025-08-11 15:09:18.462.
Test Case '-[PayslipMaxUITests.DiagnosticsExportFlowTests testExportDiagnosticsBundleFlow]' started.
    t =     0.00s Start Test at 2025-08-11 15:09:18.463
    t =     0.23s Set Up
    t =     0.23s Open com.app.payslipmax.PayslipMax
    t =     0.23s     Launch com.app.payslipmax.PayslipMax
    t =     1.57s         Setting up automation session
    t =     2.41s         Wait for com.app.payslipmax.PayslipMax to idle
    t =     4.22s Waiting 10.0s for "Settings" Button to exist
    t =     5.25s     Checking `Expect predicate `existsNoRetry == 1` for object "Settings" Button`
    t =     5.25s         Checking existence of `"Settings" Button`
    t =     5.38s Tap "Settings" Button
    t =     5.38s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     5.39s     Find the "Settings" Button
    t =     5.41s     Check for interrupting elements affecting "Settings" Button
    t =     5.44s     Synthesize event
    t =     5.84s     Wait for com.app.payslipmax.PayslipMax to idle
    t =     5.85s Waiting 10.0s for "Open Debug Menu" Button to exist
    t =     6.87s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =     6.87s         Checking existence of `"Open Debug Menu" Button`
    t =     6.95s         Capturing element debug description
    t =     7.87s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =     7.87s         Checking existence of `"Open Debug Menu" Button`
    t =     7.94s         Capturing element debug description
    t =     8.87s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =     8.87s         Checking existence of `"Open Debug Menu" Button`
    t =     8.93s         Capturing element debug description
    t =     9.86s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =     9.86s         Checking existence of `"Open Debug Menu" Button`
    t =     9.94s         Capturing element debug description
    t =    10.86s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    10.86s         Checking existence of `"Open Debug Menu" Button`
    t =    10.93s         Capturing element debug description
    t =    11.85s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    11.85s         Checking existence of `"Open Debug Menu" Button`
    t =    11.89s         Capturing element debug description
    t =    12.92s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    12.92s         Checking existence of `"Open Debug Menu" Button`
    t =    12.99s         Capturing element debug description
    t =    13.91s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    13.91s         Checking existence of `"Open Debug Menu" Button`
    t =    13.98s         Capturing element debug description
    t =    14.91s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    14.91s         Checking existence of `"Open Debug Menu" Button`
    t =    14.98s         Capturing element debug description
    t =    15.85s     Checking `Expect predicate `existsNoRetry == 1` for object "Open Debug Menu" Button`
    t =    15.85s         Checking existence of `"Open Debug Menu" Button`
    t =    15.92s         Capturing element debug description
    t =    15.92s     Checking existence of `"Open Debug Menu" Button`
    t =    15.98s Collecting debug information to assist test failure triage
    t =    15.98s     Requesting snapshot of accessibility hierarchy for app with pid 28082
/Users/sunil/Downloads/PayslipMax/PayslipMaxUITests/High/DiagnosticsExportFlowTests.swift:20: error: -[PayslipMaxUITests.DiagnosticsExportFlowTests testExportDiagnosticsBundleFlow] : XCTAssertTrue failed
    t =    16.29s Tear Down
Test Case '-[PayslipMaxUITests.DiagnosticsExportFlowTests testExportDiagnosticsBundleFlow]' failed (16.539 seconds).
Test Suite 'DiagnosticsExportFlowTests' failed at 2025-08-11 15:09:35.002.
	 Executed 1 test, with 1 failure (0 unexpected) in 16.539 (16.540) seconds
Test Suite 'PayslipMaxUITests.xctest' failed at 2025-08-11 15:09:35.003.
	 Executed 1 test, with 1 failure (0 unexpected) in 16.539 (16.541) seconds
Test Suite 'Selected tests' failed at 2025-08-11 15:09:35.004.
	 Executed 1 test, with 1 failure (0 unexpected) in 16.539 (16.542) seconds
# Podfile for PayslipMax - Phase 1B: ML Runtime Integration
# TensorFlow Lite for Edge AI Integration

platform :ios, '15.0'

target 'PayslipMax' do
  use_frameworks!

  # TensorFlow Lite for ML model inference
  pod 'TensorFlowLiteC', '~> 2.17.0'
  pod 'TensorFlowLiteSwift', '~> 2.17.0'

  target 'PayslipMaxTests' do
    inherit! :search_paths
    # Test-specific pods can be added here
  end

  target 'PayslipMaxUITests' do
    inherit! :search_paths
    # UI test-specific pods can be added here
  end
end

# Enable modular headers for better compatibility
use_modular_headers!

# Post-install configuration for TensorFlow Lite
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Enable bitcode for production builds (only for iOS < 17)
      if config.name == 'Release'
        config.build_settings['ENABLE_BITCODE'] = 'YES'
      end

      # TensorFlow Lite specific optimizations
      if target.name.include?('TensorFlow')
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'TFLITE_USE_ACCELERATE=1'

        # Ensure framework is built for both simulator and device
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

        # Suppress deprecated API warnings in TensorFlow Lite Swift
        if target.name.include?('TensorFlowLiteSwift')
          config.build_settings['OTHER_SWIFT_FLAGS'] ||= ['$(inherited)']
          config.build_settings['OTHER_SWIFT_FLAGS'] << '-Xcc -Wno-deprecated-declarations'
        end

        # Ensure proper header search paths for TensorFlow Lite C API
        config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
        config.build_settings['HEADER_SEARCH_PATHS'] << '"${PODS_ROOT}/TensorFlowLiteC/Frameworks/TensorFlowLiteC.xcframework/ios-arm64/TensorFlowLiteC.framework/Headers"'
        config.build_settings['HEADER_SEARCH_PATHS'] << '"${PODS_ROOT}/TensorFlowLiteC/Frameworks/TensorFlowLiteC.xcframework/ios-arm64_x86_64-simulator/TensorFlowLiteC.framework/Headers"'
      end

      # iOS deployment target consistency
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'

      # Main target iOS deployment target
      if target.name == 'PayslipMax'
        # Bridging header will be configured in Xcode project settings
      end
    end
  end
end

# Define platform version to match your project
platform :ios, '18.0'

target 'PayslipMax' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for PayslipMax
  pod 'Firebase/Auth'
  pod 'Firebase/Functions'
  pod 'Firebase/Firestore'

  target 'PayslipMaxTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'PayslipMaxUITests' do
    # Pods for testing
  end

end

# Fix for CocoaPods framework header issues with iOS 18+ / Xcode strict verification
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Disable modules for pods with structural header issues
      if ['leveldb-library', 'nanopb'].include?(target.name)
        config.build_settings['CLANG_ENABLE_MODULES'] = 'NO'
        config.build_settings['DEFINES_MODULE'] = 'NO'
      end

      # Suppress double-quote framework header warnings for all pods
      # This is a known Firebase/CocoaPods issue with iOS 18
      config.build_settings['WARNING_CFLAGS'] ||= ['$(inherited)']
      config.build_settings['WARNING_CFLAGS'] << '-Wno-error=quoted-include-in-framework-header'

      # Prevent warnings from being treated as errors
      config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'NO'
    end
  end
end

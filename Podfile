# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'AreaBook' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Firebase pods
  pod 'Firebase/Analytics'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  
  # Additional useful pods for the AreaBook app
  pod 'SDWebImageSwiftUI'  # For image loading
  
  target 'AreaBookTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'AreaBookUITests' do
    # Pods for testing
  end

end

# Post-install script to fix warnings
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
    end
  end
end
Pod::Spec.new do |s|
  s.name             = 'Blaink'
  s.version          = '1.1.6'
  s.summary          = 'Blaink iOS SDK for push notifications and messaging'
  s.description      = <<-DESC
    Blaink iOS SDK provides push notification and messaging capabilities 
    for iOS applications with advanced targeting and analytics features.
  DESC
  
  s.homepage         = 'https://github.com/Rashidium/blaink-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Rashidium' => 'support@blaink.com' }
  s.source           = { :git => 'https://github.com/Rashidium/blaink-ios.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '16.0'
  s.swift_version = '6.0'

  # Source files from the Swift Package structure
  s.source_files = 'Sources/Blaink/**/*.{swift}'
  
  # Framework dependencies
  s.frameworks = 'Foundation', 'UIKit', 'UserNotifications'
  
  # If there are any system dependencies
  # s.dependency 'SomeOtherFramework'
end

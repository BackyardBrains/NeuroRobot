#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nativec.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nativec'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.', :path => '../macos' }
  s.source_files     = ['Classes/**/*', '../macos/Classes/**/*']
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  # https://github.com/CocoaPods/CocoaPods/issues/7082
  # https://docs.google.com/document/d/1JdgBrMXV0a6fnVoooILNTQB8dNCvLloT4D4TBkECQ6c/edit?resourcekey=0-iPL3CzwOjUquabkMiucaHA

  # s.public_header_files = 'Classes/**/*.h'
  # s.pod_target_xcconfig = { 
  #   #...other settings...
  #   'OTHER_LDFLAGS' => '-lxyz'
  # }  
end

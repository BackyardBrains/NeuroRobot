#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint winaudio.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'winaudio'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # s.osx.vendored_frameworks = 'opencv2.framework'
  # s.public_header_files = 'Classes/bridging-header.h'

  
  s.source_files          = [
    'Classes/**/*',
    'Classes/*',
  ]
  # s.public_header_files   = [
  #     'Classes/*.h',
  #     'Classes/**/*.h',
  # ]

  # s.xcconfig              = {
  #   'HEADER_SEARCH_PATHS' => [
  #       '"${PODS_TARGET_SRCROOT}/shared_c/"'
  #   ],
  #   'GCC_PREPROCESSOR_DEFINITIONS' => 'SOME_SYMBOL_FOR_THIRD_PARTY_CODE=1 SOME_OTHER_SYMBOL=1'
  # }  

  s.osx.vendored_libraries = "libbass.dylib"
  # s.public_header_files = 'Classes/bass.h'
end

#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_opencv.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_opencv'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  # s.source_files     = 'Classes/**/*'
  s.source_files     = ['Classes/NativeOpencvPlugin.swift','Classes/include/*', 'Classes/native_opencv.cpp']
  # s.source_files     = ['Classes/NativeOpencvPlugin.swift','Classes/include/*', 'Classes/NeuronPrototype.h', 'Classes/NeuronPrototype.cpp', 'Classes/native_opencv.cpp']
  # s.source_files     = ['Classes/NativeOpencvPlugin.swift','Classes/include/*', 'Classes/NeuronPrototypeHeader.cpp', 'Classes/NeuronPrototype.cpp', 'Classes/native_opencv.cpp']
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # telling CocoaPods not to remove framework
  s.preserve_paths = 'opencv2.xcframework'
  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2' }
  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.xcframework'
  # including native framework
  s.frameworks = 'AVFoundation', 'Accelerate', 'OpenCL'
  # including C++ library
  s.library = 'c++'  
end

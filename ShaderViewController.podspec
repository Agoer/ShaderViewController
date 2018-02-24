#
# Be sure to run `pod lib lint ShaderViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ShaderViewController'
  s.version          = '0.1.0'
  s.summary          = 'Example how to add a nice shader to the background of a view'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Example how to add a nice shader to the background of a view.
                       DESC

  s.homepage         = 'https://bitbucket.org/rhinoid/shaderviewcontroller'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rhinoid' => 'rhino@finished.nl' }
  s.source           = { :git => 'https://bitbucket.org/rhinoid/shaderviewcontroller.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'ShaderViewController/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ShaderViewController' => ['ShaderViewController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

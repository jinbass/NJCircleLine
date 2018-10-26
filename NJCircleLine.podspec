#
# Be sure to run `pod lib lint NJCircleLine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'NJCircleLine'
  s.version          = '1.0.0'
  s.summary          = 'A library that draws dot line with given points or polyline.'

  s.description      = <<-DESC
This simple library draws a dotted line with a given start point and end point on Google Map.
                       DESC

  s.homepage         = 'https://github.com/jinbass/NJCircleLine'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Jin Nagumo' => 'hojinkojin@yahoo.co.jp' }
  s.source           = { :git => 'https://github.com/jinbass/NJCircleLine.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/dog_jin'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'
  s.static_framework = true
  s.source_files = 'NJCircleLine/Classes/**/*'
  s.dependency 'GoogleMaps'

end

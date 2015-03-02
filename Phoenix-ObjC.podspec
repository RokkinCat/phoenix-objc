#
# Be sure to run `pod lib lint Phoenix-ObjC.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Phoenix-ObjC"
  s.version          = "0.2.0"
  s.summary          = "Objective-C client for Phoenix."
  s.description      = <<-DESC
                       Objective-C client for Phoenix Framework
                       DESC
  s.homepage         = "https://github.com/RokkinCat/phoenix-objc"
  s.license          = 'MIT'
  s.author           = { "Josh Holtz" => "josh@rokkincat.com" }
  s.source           = { :git => "https://github.com/RokkinCat/phoenix-objc.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'Phoenix-ObjC' => ['Pod/Assets/*.png']
  }

  s.dependency 'SocketRocket', '~> 0.3.1-beta2'
end

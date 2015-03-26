Pod::Spec.new do |s|
  s.name             = "Phoenix-ObjC"
  s.version          = "0.2.1"
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

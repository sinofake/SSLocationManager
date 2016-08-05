Pod::Spec.new do |s|
  s.name         = "SSLocationManager"
  s.version      = "0.1.1"
  s.summary      = "获取当前位置，反地理解析"
  #s.description = <<-DESC    DESC
  s.homepage     = "https://github.com/sinofake/SSLocationManager"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "Sinofake Sinep" => "sinuofake@gmail.com" }
  s.social_media_url   = "https://twitter.com/sinofake"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/sinofake/SSLocationManager.git", :tag => s.version }
  s.source_files = "MapDemo/SSLocationManager/*.{h,m,c}"
  s.public_header_files = "MapDemo/SSLocationManager/*.{h}"
  s.requires_arc = true
  s.dependency "INTULocationManager", "~> 4.2.0"
  s.dependency "APOfflineReverseGeocoding", "~> 0.0.2"

end
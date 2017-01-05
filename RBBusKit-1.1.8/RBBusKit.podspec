Pod::Spec.new do |s|
  s.name = "RBBusKit"
  s.version = "1.1.8"
  s.summary = "RBBusKit \u{516c}\u{5171}\u{7ec4}\u{4ef6}."
  s.license = {"type"=>"MIT", "file"=>"LICENSE"}
  s.authors = {"zhikuiyu"=>"zhikuiyu@roobo.com"}
  s.homepage = "https://github.com/zhiyu330691038/RBBusKit"
  s.description = "TODO: Add long description of the pod here."
  s.frameworks = ["UIKit", "MapKit"]
  s.source = { :path => '.' }

  s.ios.deployment_target    = '7.0'
  s.ios.vendored_framework   = 'ios/RBBusKit.framework'
end

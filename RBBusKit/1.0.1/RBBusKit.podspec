Pod::Spec.new do |s|
  s.name             = 'RBBusKit'
  s.version          = '1.0.1'
  s.summary          = 'RBBusKit 公共组件.'
  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.platform = :ios, "9.0"

  s.homepage         = 'https://git.365jiating.com/zhikuiyu/Pudding_RBBusKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zhikuiyu' => 'zhikuiyu@roobo.com' }
  s.source           = { :git => 'git@git.365jiating.com:zhikuiyu/Pudding_RBBusKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '7.0'

  s.source_files = 'RBBusKit/Classes/**/*'
  


#  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'FMDB', '~> 2.6'
end

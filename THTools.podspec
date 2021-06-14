Pod::Spec.new do |s|
  s.name         = "THTools"                #名称
  s.version      = "1.0.3"                #版本号
  s.summary      = "Swift little tools"        #简短介绍
  s.description  = "私有pod測試 It's a swift little tools from TH"

  # s.screenshots  = "www.example.com/screenshots_1.gif"
  s.license      = "MIT"                #开源协议
  s.author       = { "TimHo" => "softapprentice@gmail.com" }

  s.homepage     = "http://google.com/"
  s.source       = { :git => "https://github.com/Sulatim/THTools.git", :tag => s.version }

  s.platform     = :ios, "11.0"            #支持的平台及版本，这里我们呢用swift，直接上9.0
  s.requires_arc = true                    #是否使用ARC

  s.swift_versions = "5.0"
  s.source_files  = "THTools/*.swift"    #OC可以使用类似这样"Classes/**/*.{h,m}"

  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation'    #所需的framework,多个用逗号隔开
  s.module_name = 'THTools'                #模块名称

  #s.dependency "KRProgressHUD"    #依赖关系，该项目所依赖的其他库，如果有多个可以写多个 s.dependency

end

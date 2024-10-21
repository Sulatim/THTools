Pod::Spec.new do |s|
  s.name         = "THTools"
  s.version      = "1.0.7"
  s.summary      = "Swift little tools"
  s.description  = "私有pod測試 It's a swift little tools from TH"

  # s.screenshots  = "www.example.com/screenshots_1.gif"
  s.license      = "MIT"                #开源协议
  s.author       = { "TimHo" => "softapprentice@gmail.com" }

  s.homepage     = "http://google.com/"
  s.source       = { :git => "https://github.com/Sulatim/THTools.git", :tag => s.version }

  s.platform     = :ios, "11.0"
  s.requires_arc = true                    #是否使用ARC

  s.swift_versions = "5.0"
  s.source_files  = "Code/THTools/*.swift"

  s.module_name = 'THTools'                #模块名称
  s.dependency "KRProgressHUD"

end

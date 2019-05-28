Pod::Spec.new do |s|
s.name = 'HDWindowLogger'
s.version = '1.0.0'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'iOS端将输出日志log悬浮显示在屏幕上，便于在真机调试信息'
s.homepage = 'https://github.com/DamonHu/HDNetTools'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/HDWindowLogger.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '9.0'
s.source_files = "HDWindowLogger/HDWindowLogger/*.{h,m}"
s.frameworks = 'UIKit'
# s.documentation_url = 'http://www.hudongdong.com/ios/758.html'
end
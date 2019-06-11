Pod::Spec.new do |s|
s.name = 'HDWindowLogger'
s.version = '1.6.0'
s.license= { :type => "MIT", :file => "LICENSE" }
s.summary = 'The iOS side displays the output log log on the screen, and can generate log file sharing, which is convenient for debugging information'
s.homepage = 'https://github.com/DamonHu/HDNetTools'
s.authors = { 'DamonHu' => 'dong765@qq.com' }
s.source = { :git => "https://github.com/DamonHu/HDWindowLogger.git", :tag => s.version}
s.requires_arc = true
s.ios.deployment_target = '9.0'
s.source_files = "HDWindowLogger/HDWindowLogger/*.{h,m}","HDWindowLogger/HDWindowLogger/**/*.strings"
s.frameworks = 'UIKit'
s.documentation_url = 'http://blog.hudongdong.com/ios/952.html'
end
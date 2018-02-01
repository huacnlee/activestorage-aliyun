$:.push File.expand_path("lib", __dir__)

require File.expand_path('lib/active_storage_aliyun/version')

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "activestorage-aliyun"
  s.version     = ActiveStorageAliyun::VERSION
  s.date        = '2018-02-01'
  s.homepage    = 'https://github.com/huacnlee/activestorage-aliyun'
  s.summary     = "Wraps the Aliyun OSS as an Active Storage service"
  s.description = "Wraps the Aliyun OSS as an Active Storage service."
  s.authors     = ["Jason Lee"]
  s.email       = 'huacnlee@gmail.com'
  s.files       = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md', 'CHANGELOG.md']
  s.license     = 'MIT'

  s.add_dependency 'rails', '>= 5.2.0.rc'
  s.add_dependency 'aliyun-sdk', '>= 0.6.0'
end

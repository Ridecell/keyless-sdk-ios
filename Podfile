# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

inhibit_all_warnings!

target 'CarSharePOC' do
  use_frameworks!

  pod 'Swinject'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'SwiftyBeaver'
  pod 'SwiftLint'
  pod 'SwiftFormat/CLI'

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
    end
end

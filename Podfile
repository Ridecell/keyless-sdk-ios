# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

inhibit_all_warnings!

target 'CarShare' do
  use_frameworks!

  pod 'Swinject'
  pod 'SwinjectStoryboard'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'SwiftLint'
  pod 'SwiftFormat/CLI'

  target 'CarShareTests' do
    inherit! :search_paths
    pod 'RxTest'
    pod 'RxBlocking'
  end

  target 'CarShareUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
    end
end

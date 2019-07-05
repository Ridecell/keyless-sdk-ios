Pod::Spec.new do |s|

# 1 You first specify basic information about the pod.
s.platform = :ios
s.ios.deployment_target = '12.0'
s.name = "CarShareFramework"
s.summary = "The CarShareFramework helps facilitate BLE communication between mobile devices and Geotab connected vehicles."
s.requires_arc = true

# 2 A Podspec is essentially a snapshot in time of your CocoaPod as denoted by a version number. When you update a pod, you’ll also need to update the Podspec’s version. All CocoaPods are highly encouraged to follow Semantic Versioning. If you’re not familiar with Semantic Versioning, see How to Use CocoaPods with Swift for more information.
s.version = "0.1.0"

# 3 All pods must specify a license. If you don’t, CocoaPods will present a warning when you try to install the pod, and you won’t be able to upload it to CocoaPods trunk — the master specs repo.
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address - Here, you specify information about yourself, the pod author. Enter your name and email address instead of the placeholder text.
s.author = { "Marc Maguire" => "marc.maguire@bsmtechnologies.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar) - Here, you need to specify the URL for your pod’s homepage. It’s OK to simply copy and paste the GitHub homepage from your browser’s address bar to use here.
s.homepage = "https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-ios/CarShareFramework"

# 6 - Replace this URL with your own Git URL from "Quick Setup" - Replace this URL with the Git download URL from the “Quick Setup” section of the first repo you created above. In general, it’s best to use either a http: or https: URL to make it easier for other users to consume. You can use an SSH URL if you want, but you’ll need to make sure that everyone on your team — and whoever else needs access to the CocoaPod — already has their public/private key pairs set up with your Git host.
s.source = { :git => "https://gitlab.voffice.bsmtechnologies.com/bsm/illuminate/mobile/car-share-ios/CarShareFramework.git",
:tag => "#{s.version}" }

# 7 - Here, you specify the framework and any pod dependencies. CocoaPods will make sure that these dependencies are installed and usable by your app.
#s.framework = "UIKit"
#s.dependency 'MBProgressHUD', '~> 1.1.0'
s.dependency 'SwiftLint'

# 8 - Not all files in your repository will be installed when someone installs your pod. Here, you specify the public source files based on file extensions; in this case, you specify .swift as the extension. We can keep files private by omitting them here
s.source_files = "CarShareFramework/**/*.{swift}"

# 9 - Here, you specify the resources based on their file extensions.
s.resources = "CarShareFramework/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10 - Finally, specify 4.2 as the version of Swift used in the pod.
s.swift_version = "4.2"

end


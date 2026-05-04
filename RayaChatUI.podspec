Pod::Spec.new do |s|
  s.name         = "RayaChatUI"
  s.version      = "0.1.1"
  s.summary      = "Raya AI Chat SDK — packaged SwiftUI/UIKit widget for iOS"
  s.description  = "Drop-in SwiftUI View, UIKit ViewController, and Sheet wrappers for the Raya AI chat widget. Includes the full intro/form/chat UI. Depends on RayaChatCore."
  s.homepage     = "https://github.com/UktobAI/raya-chat-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Teammates AI" => "dev@teammates.ai" }
  s.source       = { :git => "https://github.com/UktobAI/raya-chat-ios.git", :tag => s.version }
  s.ios.deployment_target = "15.0"
  s.swift_version = "5.9"

  s.source_files     = "Sources/RayaChatUI/**/*.swift"
  s.resource_bundles = { "RayaChatUI" => ["Sources/RayaChatUI/Resources/Media.xcassets"] }
  s.frameworks       = "SwiftUI"
  s.dependency "RayaChatCore", "= 0.1.1"
end

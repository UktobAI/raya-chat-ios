Pod::Spec.new do |s|
  s.name         = "RayaChat"
  s.version      = "0.1.0"
  s.summary      = "Raya AI Chat SDK for iOS"
  s.description  = "Native iOS SDK for embedding the Raya AI chat widget. SwiftUI + UIKit. Zero third-party dependencies."
  s.homepage     = "https://github.com/teammates-ai/raya-chat-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Teammates AI" => "dev@teammates.ai" }
  s.source       = { :git => "https://github.com/teammates-ai/raya-chat-ios.git", :tag => s.version }
  s.ios.deployment_target = "15.0"
  s.swift_version = "5.9"

  s.subspec "Core" do |core|
    core.source_files = "Sources/RayaChatCore/**/*.swift"
    core.frameworks = "Foundation", "CoreData", "Network", "Security", "Combine"
  end

  s.subspec "UI" do |ui|
    ui.source_files = "Sources/RayaChatUI/**/*.swift"
    ui.dependency "RayaChat/Core"
    ui.frameworks = "SwiftUI"
  end

  s.default_subspecs = "UI"
end

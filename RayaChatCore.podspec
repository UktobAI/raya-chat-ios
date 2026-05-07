Pod::Spec.new do |s|
  s.name         = "RayaChatCore"
  s.version      = "0.1.2"
  s.summary      = "Raya AI Chat SDK — headless engine for iOS"
  s.description  = "Headless chat engine for the Raya AI chat widget — WebSocket, reconnection, persistence, state management. Use this directly to build a fully custom UI, or pair with RayaChatUI for a drop-in widget."
  s.homepage     = "https://github.com/UktobAI/raya-chat-ios"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Teammates AI" => "dev@teammates.ai" }
  s.source       = { :git => "https://github.com/UktobAI/raya-chat-ios.git", :tag => s.version }
  s.ios.deployment_target = "15.0"
  s.swift_version = "5.9"

  s.source_files = "Sources/RayaChatCore/**/*.swift"
  s.frameworks   = "Foundation", "CoreData", "Network", "Security", "Combine"
end

Pod::Spec.new do |s|
  s.name         = "WorldMatrix"
  s.version      = "3.0.1"
  s.summary      = "create a view with a dotted world map in Swift 3.0"

  s.description  = <<-DESC
                  `WorldMatrix` is an iOS library writen in Swift 3 which allows you to draw a map with dots.
                   DESC

  s.homepage     = "https://github.com/KiloKilo/WorldMatrix"
  s.screenshots  = "https://raw.github.com/KiloKilo/WorldMatrix/master/screenshot.png"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Alexandre Joly" => "alexandre.joly@kilokilo.ch" }
  s.social_media_url   = "http://twitter.com/jolyAlexandre"

  s.platform     = :ios, "8.1"
  s.swift_version = '3.3'

  s.source       = { :git => "https://github.com/KiloKilo/WorldMatrix.git", :tag => s.version.to_s }

  s.requires_arc = true

  s.default_subspec = 'Base'

  s.subspec 'Base' do |ss|
    ss.source_files = 'WorldMatrix/Matrix.swift', 'WorldMatrix/WorldMatrixView.swift'
  end

  s.subspec 'Generator' do |ss|
    ss.source_files = 'WorldMatrix/WorldMatrixGenerator.swift'
    ss.dependency 'WorldMatrix/Base'
  end

end

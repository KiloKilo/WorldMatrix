Pod::Spec.new do |s|
  s.name         = "WorldMatrix"
  s.version      = "1.0.1"
  s.summary      = "create a view with a dotted world map in Swift 2.0"

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                  `WorldMatrix` is an iOS library writen in Swift 2 which allows you to draw a map with dots.
                   DESC

  s.homepage     = "https://github.com/KiloKilo/WorldMatrix"
  s.screenshots  = "https://raw.github.com/KiloKilo/WorldMatrix/master/screenshot.png"

  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Alexandre Joly" => "alexandre.joly@kilokilo.ch" }
  s.social_media_url   = "http://twitter.com/jolyAlexandre"

  s.platform     = :ios, "8.1"

  # s.source       = { :git => "https://github.com/KiloKilo/WorldMatrix.git", :commit => "bb0cc75aa3563feff1eed99d7e3966050ddf6184" }
  s.source       = { :git => "git@git.kilokilo.ch:kilokilo/WorldMatrix.git", :tag => s.version.to_s }
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

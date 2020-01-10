# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name = 'CarShare'
  s.version = '0.0.8-preview1'
  s.summary = 'An iOS framework for car share clients.'
  s.description = <<~DESC
    An iOS framework that communicates with Geotab Go9 devices for car share clients.
  DESC
  s.homepage = 'https://https://github.com/FleetCarma/carshare-sdk-ios'
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.author = { 'msnow-bsm' => 'matt.snow@bsmtechnologies.com' }
  s.source = {
    git: 'https://github.com/FleetCarma/carshare-sdk-ios.git',
    tag: "v#{s.version}"
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'CarShare/Classes/**/*.swift'
  s.frameworks = 'Foundation', 'CoreBluetooth'
  s.dependency 'SwiftProtobuf', '~> 1.0'
end

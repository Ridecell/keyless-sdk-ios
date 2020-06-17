# frozen_string_literal: true

Pod::Spec.new do |s|
  s.name = 'Keyless'
  s.version = '0.0.13'
  s.summary = 'An iOS framework for keyless clients.'
  s.description = <<~DESC
    An iOS framework that communicates with Geotab Go9 devices for keyless clients.
  DESC
  s.homepage = 'https://github.com/Geotab/keyless-sdk-ios'
  s.license = { type: 'MIT', file: 'LICENSE' }
  s.author = { 'matthewsnow' => 'matthewsnow@geotab.com' }
  s.source = {
    git: 'git@github.com:Geotab/keyless-sdk-ios.git',
    tag: "v#{s.version}"
  }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'
  s.source_files = 'Source/*.swift', 'Source/**/*.swift'
  s.frameworks = 'Foundation', 'CoreBluetooth'
  s.dependency 'SwiftProtobuf', '~> 1.9'
end

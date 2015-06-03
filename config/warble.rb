Warbler::Config.new do |config|
  config.features   = %w(compiled)
  config.dirs       = %w(bin lib)
  config.gems = %w(eidolon)
  config.jar_name   = 'demiurge'
  config.pathmaps.application << "%{^editor/,}X%x"
  config.executable = 'bin/main.rb'
end

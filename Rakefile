require 'fileutils'

desc 'Build the program.'
task :build do
  FileUtils.mkdir_p('demiurgeBase')
  java = Dir.glob('java/**/*.java').join(' ')
  system("javac -d demiurgeBase #{java}")
  FileUtils.rm_f('lib/java/demiurgeBase.jar')
  FileUtils.cd('demiurgeBase')
  system('jar cf ../lib/java/demiurgeBase.jar *')
  FileUtils.cd('..')
  FileUtils.rm_rf('demiurgeBase')
  system('warble')
end

desc 'Compile the demiurgeBase.jar file.'
task :javac do
  FileUtils.mkdir_p('demiurgeBase')
  java = Dir.glob('java/**/*.java').join(' ')
  system("javac -d demiurgeBase #{java}")
  FileUtils.rm_f('lib/java/demiurgeBase.jar')
  FileUtils.cd('demiurgeBase')
  system('jar cf ../lib/java/demiurgeBase.jar *')
  FileUtils.cd('..')
  FileUtils.rm_rf('demiurgeBase')
end

desc 'Run the program.'
task :run do
  system('java -jar demiurge.jar')
end

desc 'Build and run.'
task :test do
  FileUtils.mkdir_p('demiurgeBase')
  java = Dir.glob('java/**/*.java').join(' ')
  system("javac -d demiurgeBase #{java}")
  FileUtils.rm_f('lib/java/demiurgeBase.jar')
  FileUtils.cd('demiurgeBase')
  system('jar cf ../lib/java/demiurgeBase.jar *')
  FileUtils.cd('..')
  FileUtils.rm_rf('demiurgeBase')
  system('warble; java -jar demiurge.jar')
end

# Default to build and run.
task :default => :test

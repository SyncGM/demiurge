desc 'Build the program.'
task :build => :javac do
  sh 'warble'
end

directory 'demiurgeBase'

desc 'Compile the demiurgeBase.jar file.'
task :javac => 'demiurgeBase' do
  sh "javac -d demiurgeBase #{Dir['java/**/*.java'].join(' ')}"
  rm_f('lib/java/demiurgeBase.jar')
  cd('demiurgeBase')
  sh 'jar cf ../lib/java/demiurgeBase.jar *'
  cd('..')
  rm_rf('demiurgeBase')
end

directory 'plugins'

desc 'Run the program.'
task :run => 'plugins' do
  sh 'java -jar demiurge.jar'
end

desc 'Build and run.'
task :test => [:build, :run]

# Default to build and run.
task :default => :test

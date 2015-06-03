desc 'Build the program.'
task :build do
  system('warble')
end

desc 'Run the program.'
task :run do
  system('java -jar demiurge.jar')
end

desc 'Build and run.'
task :test do
  system('warble; java -jar demiurge.jar')
end

# Default to build and run.
task :default => :test

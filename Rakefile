# Path to your installation of Java 7. Required for building an update package.
JAVA_17 = '$HOME/.jenv/candidates/java/1.7.0_79'

# Path to your installation of Java 8. Required for building an update package.
JAVA_18 = '$HOME/.jenv/candidates/java/1.8.0_45'

RELEASE_CONTENTS = ['LICENSE', 'loader.rb', 'updates/', 'settings/', 'plugins/']

desc 'Build the program.'
task :build => :javac do
  sh 'warble'
  rm_rf('lib/java')
end

directory 'demiurgeBase'

desc 'Compile the demiurgeBase.jar file.'
task :javac => 'demiurgeBase' do
  sh "javac -d demiurgeBase #{Dir['java/**/*.java'].join(' ')}"
  rm_f('lib/java/demiurgeBase.jar')
  mkdir_p('lib/java')
  cd('demiurgeBase')
  sh 'jar cf ../lib/java/demiurgeBase.jar *'
  cd('..')
  rm_rf('demiurgeBase')
end

def build_release_zip(java_version)
  java_import java.io.FileOutputStream
  java_import java.nio.file.Files
  java_import java.nio.file.FileSystems
  java_import java.nio.file.Paths
  java_import java.util.zip.ZipEntry
  java_import java.util.zip.ZipOutputStream
  name = "demiurge.v#{SES::Demiurge::VERSION}-release#{java_version}.zip"
  file = java.io.File.new(name)
  output = ZipOutputStream.new(FileOutputStream.new(file))
  output.put_next_entry(ZipEntry.new('demiurge.jar'))
  File.open('demiurge.jar') do |f|
    file_data = f.readlines.join.to_java_bytes
    output.write(file_data, 0, file_data.length)
  end
  output.close_entry
  dirs = []
  RELEASE_CONTENTS.each do |f|
    entry = ZipEntry.new(f)
    output.put_next_entry(entry)
    unless !FileTest.exist?(f) || FileTest.directory?(f)
      File.open(f) do |f|
        file_data = f.readlines.join.to_java_bytes
        output.write(file_data, 0, file_data.length)
      end
    end
    output.close_entry
  end
  output.close
  zip = FileSystems.newFileSystem(Paths.get("#{Dir.pwd}/#{name}"), nil)
  dirs.each { |d| Files.createDirectory(zip.getPath(d)) }
end

# Builds release zip files for Java 7 and Java 8.
task :build_releases do
  require 'lib/version.rb'
  rm_f("demiurge.v#{SES::Demiurge::VERSION}-release_java17.zip")
  rm_f("demiurge.v#{SES::Demiurge::VERSION}-release_java18.zip")
  mkdir_p('demiurgeBase')
  mkdir_p('lib/java')
  sh "PATH=#{JAVA_17}/bin && JAVA_HOME=#{JAVA_17} && 
      javac -d demiurgeBase #{Dir['java/**/*.java'].join(' ')} && 
      cd demiurgeBase && jar cf ../lib/java/demiurgeBase.jar *"
  rm_rf('demiurgeBase')
  sh 'warble'
  build_release_zip('_java17')
  mkdir_p('demiurgeBase')
  sh "PATH=#{JAVA_18}/bin && JAVA_HOME=#{JAVA_18} && 
      javac -d demiurgeBase #{Dir['java/**/*.java'].join(' ')} && 
      cd demiurgeBase && jar cf ../lib/java/demiurgeBase.jar *"
  rm_rf('demiurgeBase')
  sh 'warble'
  build_release_zip('_java18')
  rm_f('demiurge.jar')
  rm_rf('lib/java')
end

directory 'updates'

desc 'Creates an update package. Requires JAVA_17 and JAVA_18 to be set.'
task :build_update => 'updates' do
  java_import java.io.FileOutputStream
  java_import java.util.zip.ZipEntry
  java_import java.util.zip.ZipOutputStream
  require 'lib/version.rb'
  rm_f("demiurge-#{SES::Demiurge::VERSION}-update.zip")
  mkdir_p('updates/java/1.7')
  sh "PATH=#{JAVA_17}/bin && JAVA_HOME=#{JAVA_17} && 
      javac -d updates/java/1.7 #{Dir['java/**/*.java'].join(' ')}"
  mkdir_p('updates/java/1.8')
  sh "PATH=#{JAVA_18}/bin && JAVA_HOME=#{JAVA_18} && 
      javac -d updates/java/1.8 #{Dir['java/**/*.java'].join(' ')}"
  Dir['lib/**/*.rb'].each do |f|
    cp(f, f.sub('lib', 'updates'))
  end
  file = java.io.File.new("demiurge-#{SES::Demiurge::VERSION}-update.zip")
  output = ZipOutputStream.new(FileOutputStream.new(file))
  Dir.glob('updates/**/*').each do |f|
    next if FileTest.directory?(f)
    entry = ZipEntry.new(f)
    output.put_next_entry(entry)
    File.open(f) do |f|
      file_data = f.readlines.join.to_java_bytes
      output.write(file_data, 0, file_data.length)
    end
    output.close_entry
  end
  output.close
  rm_rf('updates')
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

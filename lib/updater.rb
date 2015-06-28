require 'fileutils'
require 'version'
require 'rubygems/package'
require 'zlib'

# Updater
# -----------------------------------------------------------------------------
# Performs automatic updates of Demiurge.
module Updater
  
  # Checks if an update is necessary.
  #
  # @return [void]
  def self.need_update?
    u = java.net.URL.new('https://raw.githubusercontent.com/sesvxace/' <<
                                             'demiurge/master/lib/version.rb')
    file = java.io.BufferedReader.new(java.io.InputStreamReader.new(
                                          u.open_connection.get_input_stream))
    version = '0.0.0'
    update_file = ''
    while (line = file.read_line) 
      if line[/VERSION = '([\d\.]+)'/]
        version = $1
      elsif line[/UPDATE_FILE = '(.+?)'/]
        update_file = $1
      end
    end
    file.close
    require './updates/version.rb' if FileTest.exist?('updates/version.rb')
    
    return [version, update_file] if SES::Demiurge::VERSION < version
    return false
  end
  
  # Upgrades (or downgrades) to a given version of Demiurge.
  #
  # @param version [String] the version to which Demiurge should change
  # @return [void]
  def self.update(version, file = nil)
    file = "#{version}.tar.gz" unless file
    u = java.net.URL.new('https://github.com/sesvxace/demiurge/' << file)
    is = u.open_connection.get_input_stream.to_io
    File.open(file, 'w+b') do |f|
      IO.copy_stream(is, f)
    end
    is.close
    unpack_files(file)
    FileUtils.rm(file)
  end
  
  # Unpacks an installs an update archive.
  #
  # @param file [String] the name of the update archive
  # @return [void]
  def self.unpack_files(file)
    e = Gem::Package::TarReader.new(Zlib::GzipReader.open(file))
    e.rewind
    e.each do |entry|
      if entry.directory?
        n = entry.full_name.sub("#{file}/") { '' }
        FileUtils.mkdir_p(n)
      elsif entry.file?
        n = entry.full_name.sub("#{file}/") { '' }
        File.open(n, 'w+') do |f|
          f.write(entry.read)
        end
      end
    end
    e.close
  end
end

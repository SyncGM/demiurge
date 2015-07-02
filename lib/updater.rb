require 'fileutils'
require 'version'

java_import java.io.FileInputStream
java_import java.io.FileOutputStream
java_import java.util.zip.ZipInputStream

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
  def self.update(version, file)
    local = file[/(demiurge.v[\w\.]+-update.zip)/, 1]
    u = java.net.URL.new(file)
    is = u.open_connection.get_input_stream.to_io
    File.open(local, 'w+b') do |f|
      IO.copy_stream(is, f)
    end
    is.close
    unpack_files(local)
    FileUtils.rm_f(local)
  end
  
  # Unpacks an installs an update archive.
  #
  # @param file [String] the name of the update archive
  # @return [void]
  def self.unpack_files(file)
    file_name = /#{file.sub(/\.\w+$/, '')}\/(.+)/
    buffer = ('0' * 1024).to_java_bytes
    zip_contents = ZipInputStream.new(FileInputStream.new(file))
    entry = zip_contents.next_entry
    while entry
      zip_file = entry.name[file_name, 1] || entry.name
      unless zip_file[/\.\w+$/]
        FileUtils.mkdir_p(zip_file)
        entry = zip_contents.next_entry
        next
      end
      FileUtils.mkdir_p(zip_file[/(.+?)\/[^\/]+\.\w+$/, 1])
      output = FileOutputStream.new(zip_file)  
      while ((i = zip_contents.read(buffer, 0, 1024)) > -1)
        output.write(buffer, 0, i)
      end
      output.close
      zip_contents.close_entry
      entry = zip_contents.next_entry
    end
  end
end

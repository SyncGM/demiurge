# Adds the lib folder to the Ruby load path.
$ROOT_DIR = File.expand_path('../..', __FILE__)
$LOAD_PATH.unshift($ROOT_DIR + '/lib')

# If Java updates have been released, use those. Otherwise, use the packaged
# versions.
if FileTest.directory?('updates/java') then $CLASSPATH << 'updates/java'
else require 'java/demiurgeBase.jar' end

# Require some basic necessities.
require 'eidolon/rgss3'
require 'string'
require 'register'

# Import all of the Java classes that Demiurge uses.
java_import java.awt.GridBagConstraints
java_import java.awt.GridBagLayout
java_import java.awt.Insets
java_import java.awt.event.ActionListener
java_import java.awt.event.ItemListener
java_import java.awt.event.MouseListener
java_import java.nio.file.FileSystems
java_import java.nio.file.Paths
java_import java.nio.file.StandardWatchEventKinds 
java_import java.nio.file.WatchService
java_import javax.swing.JButton
java_import javax.swing.JComboBox
java_import javax.swing.DefaultComboBoxModel
java_import javax.swing.DefaultListModel
java_import javax.swing.ListSelectionModel
java_import javax.swing.JCheckBox 
java_import javax.swing.JLabel
java_import javax.swing.JList
java_import javax.swing.JPanel
java_import javax.swing.JScrollPane
java_import javax.swing.JSplitPane
java_import javax.swing.JTabbedPane
java_import javax.swing.JTable
java_import javax.swing.JTextField
java_import javax.swing.JTextArea
java_import javax.swing.KeyStroke 
java_import javax.swing.event.DocumentListener
java_import javax.swing.event.ListDataListener
java_import javax.swing.event.ListSelectionListener
java_import javax.swing.event.UndoableEditListener
java_import javax.swing.undo.UndoManager
java_import com.github.sesvxace.demiurge.DataSplitPane
java_import com.github.sesvxace.demiurge.ListCopyAction
java_import com.github.sesvxace.demiurge.ListDeleteAction
java_import com.github.sesvxace.demiurge.ListPasteAction
java_import com.github.sesvxace.demiurge.PluginTableModel
java_import com.github.sesvxace.demiurge.TextField
java_import com.github.sesvxace.demiurge.ListBackground
java_import com.github.sesvxace.demiurge.RedoAction
java_import com.github.sesvxace.demiurge.UndoAction

# Import Demiurge's GUI materials.
require 'data_tab.rb'
require 'tag_tab.rb'
require 'uncategorized_tab.rb'
require 'demiurge_window.rb'


module SES
  module Demiurge
    # Iterates through each file in a directory chain and runs a block on them.
    #
    # @param dir [String] the top of the directory chain
    # @yield [file] the path to a file so that it can be operated on
    def self.each_file(dir, &block)
      Dir.new(dir).entries.each do |file|
        next if file[/^\.+$/]
        if FileTest.directory?("#{dir}/#{file}")
          each_file("#{dir}/#{file}", &block)
        else
          yield "#{dir}/#{file}"
        end
      end
    end

    # Iterates through each directory in a directory chain and performs runs a
    # block on them.
    #
    # @param dir [String] the top of the directory chain
    # @yield [directory] the path to a directory so that it can be operated on
    def self.each_dir(dir, &block)
      Dir.new(dir).entries.each do |directory|
        next if directory[/^\.+$/]
        if FileTest.directory?("#{dir}/#{directory}")
          yield "#{dir}/#{directory}"
          each_dir("#{dir}/#{directory}", &block)
        end
      end
    end
  end
end
# Adds plugin dirs to the Java classpath if they exist. Allows loading of Java
# plugins.
if FileTest.directory?('plugins')
  SES::Demiurge.each_dir('plugins') do |d|
    next if d[/(?:com|org)$/]
    $CLASSPATH << d if FileTest.directory?(d)
  end
end

# Loads all of the files in the updates directory, if it exists.
if FileTest.directory?('updates')
  SES::Demiurge.each_file('updates') do |f|
    next unless f[/\.rb$/]
    require "./#{f}"
  end
end

# Creates the main frame and sets it to visible.
$editor_window = DemiurgeWindow.new
$editor_window.visible = true
$saving = false

# Performs file monitoring and keeps the program alive until the window is
# closed.
path = nil
service = nil
ignore = Paths.get('Demiurge.rvdata2')
context = ''
need_refresh = false
while true
  if $editor_window.loaded
    $editor_window.loaded = false
    path = Paths.get("#{$editor_window.project}/Data")
    service = FileSystems.getDefault().newWatchService
    path.register(service, StandardWatchEventKinds::ENTRY_MODIFY,
                                        StandardWatchEventKinds::ENTRY_CREATE)
  elsif $editor_window.closed
    $editor_window.closed = false
    if path
      path = nil
      service.close
      service = nil
    end
  elsif service
    key = service.take
    key.poll_events.each do |e|
      need_refresh = true unless e.context.equals(ignore)
    end
    if need_refresh
      $editor_window.reload
      need_refresh = false
    end
    key.reset
  end
end

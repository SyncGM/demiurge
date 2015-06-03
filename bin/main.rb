# Simplifies the loading of Java classes.
require 'java'
java_import javax.swing.JOptionPane

if FileTest.exist?('updates/updater.rb') then require './updates/updater'
else require 'updater' end

# Updates the program, if the auto-updater is enabled.
if FileTest.exist?('settings/Options.dsl')
  File.open('settings/Options.dsl', 'r:BOM|UTF-8') do |file|
    if Marshal.load(file)[:auto_update]
      begin
        if (version = Updater.need_update?)
          Updater.update(*version)
        end
      rescue
        JOptionPane.show_message_dialog(nil, 
           'Unable to locate update archive. Skipping update.', 'Update Failed',
                                                     JOptionPane::ERROR_MESSAGE)
      end
    end
  end
end

# Start the program.
if FileTest.exist?('updates/load_all.rb') then require './updates/load_all'
else require 'load_all' end

# DemiurgeWindow
# -----------------------------------------------------------------------------
# The main frame of the program. Contains all of Demiurge's other GUI objects
# and manages saving/loading. Not strictly the job of a window, but for v1.0 I'm
# more interested in a functional product than a fully standards-compliant one.
# Future updates will see this restructured.
class DemiurgeWindow < com.github.sesvxace.demiurge.MainWindow
  
  # @return [Boolean] whether or not Demiurge has just loaded a project
  attr_accessor :loaded
  
  # @return [Boolean] whether or not Demiurge has just closed a project
  attr_accessor :closed
  
  # @return [Hash] the game data of the loaded project
  attr_reader :data
  
  # @return [Hash] the Demiurge data of the loaded project
  attr_reader :demi_data
  
  # @return [Hash] all edits made to the Demiurge data of the loaded project
  attr_reader :modified_data
  
  # Creates a new instance of DemiurgeWindow.
  #
  # @return [DemiurgeWindow] a new instance of DemiurgeWindow
  def initialize
    super
    @data = {}
    @demi_data = {}
    @known_plugins = {}
    @loading = false
    @modified_data = {}
    @options = { auto_update: false }
    if FileTest.exist?('settings/Options.dsl')
      File.open('settings/Options.dsl', 'r:BOM|UTF-8') do |file|
        @options.merge!(Marshal.load(file))
      end
    end
    self.project_directory = (@options[:last_dir] ||= Dir.home)
    menu_item_auto_update.state = @options[:auto_update]
    @plugins_for_projects = {}
    @tabs = []
    create_dialogs
    prepare_known_plugins
    get_plugins_for_projects
    if !self.project || self.project.empty?
      menu_item_save.enabled = false
      menu_item_close.enabled = false
      menu_item_select_plugins.enabled = false
    end
  end
  
  # Adds the Data_ constants that replicates the $data_ variables from RPG
  # Maker.
  #
  # @return [void]
  def add_constants
    @data.each_pair do |k,v|
      if k[/^Map(\d+)$/]
        v.instance_variable_set(:@id, $1.to_i)
        RPG::Map.send(:define_method, :id) do
          @id
        end
        v.instance_variable_set(:@name, @data[:MapInfos][v.id].name)
        RPG::Map.send(:define_method, :name) do
          @name
        end
        unless Object.const_defined?(:Data_Maps)
          @demi_data[:Maps] ||= []
          @modified_data[:Maps] ||= []
          @demi_data[:Events] ||= {}
          @modified_data[:Events] ||= {}
          Object.const_set(:Data_Maps, [])
          unless Object.const_defined?(:Data_Events)
            Object.const_set(:Data_Events, {})
          end
        end
        Data_Maps[v.id] = v
        @demi_data[:Maps][v.id] ||= v.note
        @demi_data[:Events][v.id] ||= {}
        Data_Events[v.id] = {}
        v.events.each_pair do |k,e|
          e.instance_variable_set(:@id, "#{v.id}_#{e.id}")
          Data_Events[e.id] = e
          @demi_data[:Events][e.id] ||= []
          e.pages.each_with_index do |p,i|
            @demi_data[:Events][e.id][i] ||= get_comments(p)
          end
        end
      else
        @demi_data[k] ||= []
        @modified_data[k] ||= []
        Object.const_set("Data_#{k}", v)
        if v.respond_to?(:'[]') && v[1] && v[1].respond_to?(:id) &&
                                                         v[1].respond_to?(:note)
          v.each { |i| @demi_data[k][i.id] ||= i.note if i }
        end
      end
    end
  end
  
  # Adds tabs for the given data.
  #
  # @param data [Array] the data to pass to the tab.
  def add_tab(data)
    @tabs << DataTab.new(self, *data)
    tab_container.add(data[0], @tabs.last)
  end
  
  # Closes the open project.
  #
  # @return [void]
  def closeProject
    return unless self.project
    if self.modified
      r = JOptionPane.showConfirmDialog(self, "Save changes to #{projectName}?",
                                  "Demiurge", JOptionPane::YES_NO_CANCEL_OPTION)
      return if r == JOptionPane::CANCEL_OPTION
      saveProject if r == JOptionPane::YES_OPTION
    end
    remove_tabs
    menu_item_save.enabled = false
    menu_item_close.enabled = false
    menu_item_select_plugins.enabled = false
    self.project = nil
    @closed = true
    self.title = 'Demiurge'
    remove_constants
    @data.clear
    @demi_data.clear
    @modified_data.clear
    @tabs.each do |tab|
      recursive_component_iterate(tab) do |t|
        t.disable if t.respond_to?(:disable)
      end
      tab.repaint
      tab.reset_all
    end
    unload_plugins
    self.modified = false
  end
  
  # Creates the dialog used for making ComboBox selections from a list.
  #
  # @return [void]
  def create_choice_dialog
    @choice_dialog = [JOptionPane.new]
    p = JPanel.new(GridBagLayout.new)
    c = GridBagConstraints.new
    c.gridx = 0
    c.gridy = 0
    c.anchor = GridBagConstraints::WEST
    c.fill = GridBagConstraints::HORIZONTAL
    c.gridwidth = 2
    c.weightx = 1
    @choice_entry = JComboBox.new
    p.add(@choice_entry, c)
    c.insets = Insets.new(4, 4, 4, 4)
    c.ipadx = 4
    c.ipady = 4
    c.anchor = GridBagConstraints::CENTER
    c.gridwidth = 1
    c.gridy = 1
    c.weightx = 0
    c.fill = GridBagConstraints::NONE
    ok = JButton.new('OK')
    p.add(ok, c)
    cancel = JButton.new('Cancel')
    c.gridx = 1
    p.add(cancel, c)
    @choice_dialog[0].options = [p].to_java
    ok.add_action_listener(ActionListener.impl { 
      @choice_dialog[0].value = @choice_entry.selected_item
      @choice_dialog[1].visible = false
    })
    cancel.add_action_listener(ActionListener.impl {
      @choice_dialog[0].value = nil
      @choice_dialog[1].visible = false
    })
  end
  
  # Creates the dialogs used by the program.
  #
  # @return [void]
  def create_dialogs
    create_choice_dialog
    create_input_dialog
    create_plugin_dialog
  end
  
  # Creates the dialog used for entering text into a list.
  #
  # @return [void]
  def create_input_dialog
    @input_dialog = [JOptionPane.new]
    p = JPanel.new(GridBagLayout.new)
    c = GridBagConstraints.new
    c.gridx = 0
    c.gridy = 0
    c.anchor = GridBagConstraints::WEST
    c.fill = GridBagConstraints::HORIZONTAL
    c.gridwidth = 2
    c.weightx = 1
    @input_entry = TextField.new
    p.add(@input_entry, c)
    c.insets = Insets.new(4, 4, 4, 4)
    c.ipadx = 4
    c.ipady = 4
    c.anchor = GridBagConstraints::CENTER
    c.gridwidth = 1
    c.gridy = 1
    c.weightx = 0
    c.fill = GridBagConstraints::NONE
    ok = JButton.new('OK')
    p.add(ok, c)
    cancel = JButton.new('Cancel')
    c.gridx = 1
    p.add(cancel, c)
    @input_dialog[0].options = [p].to_java
    ok.add_action_listener(ActionListener.impl { 
      @input_dialog[0].value = @input_entry.text
      @input_dialog[1].visible = false
    })
    cancel.add_action_listener(ActionListener.impl {
      @input_dialog[0].value = nil
      @input_dialog[1].visible = false
    })
  end
  
  # Creates a plugin based on data from the Plugin Creator dialog.
  #
  # @param data [Array] an array of data used to create the plugin
  # @return [void]
  def createPlugin(data)
    a = data[0].downcase
    s = data[1].downcase.gsub(/\W/) { '' }
    p = "# Name: #{data[1]}\n# Author: #{data[0]}\n# URL: #{data[2]}\n#\n# "
    p << data[3].gsub(/[\r\n]+/) { "\n# " }
    p << "\n\nRegister.notify(%q{#{data[0]}}, %q{#{data[1]}})"
    tags = data[4]
    params = []
    i = 0
    tags.values.each do |tag|
      params.clear
      j = 0
      paramlist = tag[3]
      paramlist.values.each { |par| params << par }
      param_names = params.collect do |p|
        p[0].downcase.gsub(/\s+/) { '_' }.gsub(/\W/) { '' }
      end
      klasses = tag[2].split(/,\s*/)
      klasses.each { |k| k.prepend(':') unless k[0] == ':' }
      tag[2].prepend(':') unless tag[2][0] == ':'
      p << "\n\n[#{klasses.join(', ')}].each do |klass|\n  Register.add(klass)"
      p << " do |#{a}_#{s}_#{tag[0].downcase.gsub(/\W/) { '' }}, " <<
                               "#{param_names.join(', ')}|\n    self.name = " <<
      "%q{#{tag[0]}}\n    self.description = %q{#{tag[1]}}\n    self.type = " <<
                                                      "%q{#{tag[7]}}.to_sym\n  "
      if tag[6] then p << "  self.repeatable = true\n    "
      else p << '  ' end
      params.each_with_index do |par,i|
        i = ':rest' if par[2]
        p << "self.params[#{i}] = [\n      #{par[1]},\n      %q{#{par[0]}}," <<
                                                         "\n      %q{#{par[3]}}"
        p << ",\n      proc { #{par[4]} }" unless par[4].empty?
        unless par[5].empty?
          p << ",\n      proc { |v| #{par[5].gsub('$v') { 'v' }} }"
        end
        p << "\n    ]\n    "
      end
      convert = tag[4].gsub(/\$(\d+)/) { "\#{#{param_names[$1.to_i - 1]}}" }
      p << "\n    [proc { |#{param_names.join(', ')}| #{convert} },\n     " <<
                                                        "#{tag[5]}]\n  end\nend"
    end
    FileUtils.mkdir_p("plugins/#{a}")
    File.open("plugins/#{a}/#{a}_#{s}.rb", 'w+') { |f| f.write(p) }
  end
  
  # Creates the dialog used for selecting the plugins used by a project.
  #
  # @return [void]
  def create_plugin_dialog
    @plugin_dialog = [JOptionPane.new]
    @plugin_dialog[0].message = 'Please select the plugins that you are ' <<
                                                       'using for this project.'
    @plugin_panel = JPanel.new(GridBagLayout.new)
    c = GridBagConstraints.new
    c.gridx = 0
    c.gridy = 0
    c.anchor = GridBagConstraints::CENTER
    c.fill = GridBagConstraints::BOTH
    c.gridheight = 1
    c.weightx = 1
    c.weighty = 0.6
    @plugin_table = JTable.new
    @plugin_panel.add(JScrollPane.new(@plugin_table), c)
    c.gridy = 1
    c.weighty = 0.4
    @plugin_description = JTextArea.new
    @plugin_panel.add(JScrollPane.new(@plugin_description), c)
    @plugin_dialog[0].add(@plugin_panel)
  end
  
  # Creates all of the top-level tabs used by the program.
  #
  # @return [void]
  def create_tabs
    tabs.sort_by { |t| t[0] }.each { |tab| add_tab(tab) }
  end
  
  # Gets a list of the comments on an event page. Will be moved to an
  # event-specific tab in the future. Serves no purpose in v1.0. Groundwork for
  # future updates.
  #
  # @param event [RPG::Event::Page] the event page that should be trawled for
  #   comments
  # @return [String] all of the event's comments as a string
  def get_comments(event)
    event.list.select { |c| c.code == 108 || c.code == 408 }.map! do |comment|
      comment.parameters.first
    end.join("\n")
  end
  
  # Gets a list of projects and the plugins that they use.
  #
  # @return [void]
  def get_plugins_for_projects
    @plugins_for_projects.clear
    if FileTest.exist?('settings/ProjectData.dpl')
      File.open('settings/ProjectData.dpl', 'r:BOM|UTF-8') do |f|
        @plugins_for_projects.merge!(Marshal.load(f))
      end
    end
  end
  
  # Loads a project's plugins.
  #
  # @param first_load [Boolean] whether or not it's the first time a project has
  #   been loaded in Demiurge
  # @return [void]
  def load_plugins(first_load = false)
    Register.clear_data
    if (@plugins_for_projects[self.project] ||= []).empty? && first_load
      show_plugin_dialog
    else
      if first_load
        missing_plugins = []
        @plugins_for_projects[self.project].each do |p|
          if (pl = @known_plugins[p]) && FileTest.exist?(file = pl[1])
            load "./#{file}"
          else
            file = p unless file
            JOptionPane.show_message_dialog(nil, 
                  "Unable to locate plugin #{file}. It will be skipped. If " <<
                   'you have renamed or moved the plugin, please reselect it' <<
                                                         'from the Tools menu.',
                                    'Update Failed', JOptionPane::ERROR_MESSAGE)
            missing_plugins << p
          end
        end
        @plugins_for_projects[self.project] -= missing_plugins
      else
        @known_plugins.keys.sort.each_with_index do |k,i|
          if @plugin_table.model.get_value_at(i, 0)
            load "./#{@known_plugins[k][1]}"
            (@plugins_for_projects[self.project] ||= []) << k
          else
            (@plugins_for_projects[self.project] ||= []).delete(k)
          end
        end
      end
      remove_tabs
      create_tabs
      @tabs.each do |tab|
        tab.repaint
        tab.reload
      end
    end
  end
  
  # Loads a project.
  #
  # @return [void]
  def loadProject
    p = self.project
    closeProject
    self.project = p
    @loaded = true
    @demi_data.clear
    @modified_data.clear
    self.title = "#{project[/([^\/\\]+)$/, 1]} - Demiurge"
    load_project_files
    add_constants
    load_plugins(true)
    @tabs.each do |tab|
      recursive_component_iterate(tab) do |t|
        t.enable if t.respond_to?(:enable)
      end
    end
    menu_item_save.enabled = true
    menu_item_close.enabled = true
    menu_item_select_plugins.enabled = true
    self.modified = false
    @options[:last_dir] = self.project
    File.open('settings/Options.dsl', 'w+:BOM|UTF-8') do |file|
      Marshal.dump(@options, file)
    end
  end
  
  # Loads a project's .rvdata2 files.
  #
  # @param skip_demiurge [Boolean] whether or not the Demiurge.rvdata2 file
  #   should be loaded -- true when reloading in-editor due to changes made in
  #   RPG Maker
  # @return [void]
  def load_project_files(skip_demiurge = false)
    @data.clear
    Dir.new("#{project}/Data").entries.each do |e|
      next if FileTest.directory?("#{project}/#{e}") || !e[/^\w+\.rvdata2$/]
      name = e[/(.+)\.rvdata2/, 1].to_sym
      File.open("#{project}/Data/#{e}", 'rb') do |data|
        if e == 'Demiurge.rvdata2'
          @demi_data = Marshal.load(data) unless skip_demiurge
        else @data[name] = Marshal.load(data) end
      end
    end
  end
  
  # Sets up a hash of information about available plugins.
  #
  # @return [void]
  def prepare_known_plugins
    @known_plugins.clear
    SES::Demiurge.each_file('plugins') do |f|
      next unless f[/\.rb$/]
      File.open(f, 'r:BOM|UTF-8') do |file|
        lines = file.readlines
        if lines[0][/^#\s*Name:\s*(.+)/]
          key = $1
          value = ['', f]
          lines.each do |line|
            case line
            when /^\s*Name:\s*(.+)/i; value[0] << "Name: #{$1.strip}\n"
            when /^#\s*Author:\s*(.+)/i; value[0] << "\nAuthor: #{$1.strip}\n"
            when /^#\s*$/; next
            when /^#\s*URL:\s*(.+)/i; value[0] << "URL: #{$1.strip}\n\n"
            when /^#\s*(.+)/; value[0] << "#{$1.strip} "
            else break
            end
          end
          @known_plugins[key] = value
        end
      end
    end
  end
  
  # Gets the name of the current project.
  #
  # @return [String] the name of the current project
  def projectName
    self.title[/(.+?) - Demiurge/, 1]
  end
  
  # Calls a block on every component in a chain.
  #
  # @param component [Component] the top of the chain
  # @yieldparam component [Component] a component on which to perform the block
  # @return [void]
  def recursive_component_iterate(component, &block)
    component.components.each { |c| recursive_component_iterate(c, &block) }
    yield component
  end
  
  # Calls a method on every component in a chain.
  #
  # @param component [Component] the top of the chain
  # @return [void]
  def recursive_component_send(component, method)
    component.components.each { |c| recursive_component_send(c, method) }
    component.send(method) if component.respond_to?(method)
  end
  
  # Reloads the current project. Called when the .rvdata2 files in the project's
  # directory are changed.
  #
  # @return [void]
  def reload
    return if $saving
    remove_constants
    load_project_files(true)
    add_constants
    @tabs.each { |t| t.reset_list(true) }
  end
  
  # Removes the Data_ constants in preparation for loading new ones.
  #
  # @return [void]
  def remove_constants
    @data.each_pair do |k,v|
      next unless Object.const_defined?("Data_#{k}")
      Object.send(:remove_const, "Data_#{k}")
    end
    Object.send(:remove_const, :Data_Maps) if Object.const_defined?(:Data_Maps)
  end
  
  # Removes all tabs in preparation for loading new ones.
  #
  # @return [void]
  def remove_tabs
    recursive_component_iterate(tab_container) do |c|
     c.removeAll if c.respond_to?(:removeAll)
     c.dispose if c.respond_to?(:dispose)
    end
    @tabs.clear
  end
  
  # Saves the current project.
  #
  # @return [void]
  def saveProject
    return unless self.project
    unsorted_data = {}
    @demi_data.each_pair do |k,v|
      send("save_#{k.downcase}") if respond_to?("save_#{k.downcase}")
    end
    File.open("#{project}/Data/Demiurge.rvdata2", 'wb') do |file|
      Marshal.dump(@demi_data, file)
    end
    File.open('settings/ProjectData.dpl', 'w+:BOM|UTF-8') do |f|
      Marshal.dump(@plugins_for_projects, f)
    end
    self.modified = false
  end
  
  # Calls the plugin selection dialog. Here for Java compatibility.
  #
  # @return [void]
  def selectPlugins
    show_plugin_dialog
  end
  
  # Turns automatic updates on or off.
  #
  # @return [void]
  def setAutoUpdate
    @options[:auto_update] = !@options[:auto_update]
    File.open('settings/Options.dsl', 'w+:BOM|UTF-8') do |file|
      Marshal.dump(@options, file)
    end
  end
  
  # Sets up the list of available plugins.
  #
  # @return [void]
  def set_up_plugin_list
    model = PluginTableModel.new(['Enabled', 'Script'].to_java)
    list = (@plugins_for_projects[self.project] ||= [])
    @known_plugins.keys.sort.each do |k|
      model.add_row([list.include?(k), k].to_java)
    end
    @plugin_table.model = model
    @plugin_table.setColumnSelectionAllowed(false)
    listener = ListSelectionListener.impl { |m,e|
      r = @plugin_table.selected_row
      if r > -1
        script = @plugin_table.model.get_value_at(r, 1)
        @plugin_description.line_wrap = false
        @plugin_description.text = @known_plugins[script][0]
        @plugin_description.line_wrap = true
      end
    }
    @plugin_table.selection_model.add_list_selection_listener(listener)
    @plugin_table.set_row_selection_interval(0, 0)
    @plugin_description.text = @known_plugins[@known_plugins.keys.sort[0]][0]
    @plugin_description.line_wrap = true
    @plugin_description.wrap_style_word = true
    @plugin_table.revalidate
  end
  
  # Shows the choice dialog for a list.
  #
  # @param title [String] the title for the dialog
  # @param prompt [String] the dialog's message prompt
  # @param list [Array<String>] the dialog's choices
  # @return [String] the user's selection
  def show_choice_dialog(title, prompt, list)
    @choice_entry.model = DefaultComboBoxModel.new(list.to_java)
    @choice_dialog[0].message = prompt
    @choice_dialog[1] = @choice_dialog[0].create_dialog(self, title)
    @choice_dialog[1].visible = true
    @choice_dialog[1] = nil
    @choice_dialog[0].value
  end
  
  # Shows the text entry dialog for a list.
  #
  # @param title [String] the title for the dialog
  # @param prompt [String] the dialog's message prompt
  # @param mode [Integer, String] the input mode
  # @return [String] the text entered by the user
  def show_input_dialog(title, prompt, mode = 0)
    case mode
    when /string/i; mode = 0
    when /integer/i; mode = 1
    when /float/i; mode = 2
    else mode = 0 unless mode.is_a?(Integer)
    end
    @input_entry.mode = mode
    @input_dialog[0].message = prompt
    @input_dialog[1] = @input_dialog[0].create_dialog(self, title)
    @input_dialog[1].visible = true
    @input_dialog[1] = nil
    @input_dialog[0].value
  end
  
  # Aliased by plugins that add to the GUI to remove their additions.
  #
  # @return [void]
  def unload_plugins
  end
  
  # Shows the plugin selection dialog.
  #
  # @return [void]
  def show_plugin_dialog
    prepare_known_plugins
    set_up_plugin_list
    @plugin_dialog[1] = @plugin_dialog[0].create_dialog(self, 'Select Plugins')
    @plugin_dialog[1].visible = true
    load_plugins
  end
  
  # The list of tab data used when creating top-level tabs.
  #
  # @return [Array] an array of tab data
  def tabs
    Register::Data.collect { |k,v| ["#{k}".pluralize, v] }
  end
end

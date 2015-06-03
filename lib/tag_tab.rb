# TagTab
# -----------------------------------------------------------------------------
# A tab that builds its contents based on the tags that it's given to manage.
class TagTab < JPanel
  
  # @return [String] the name of the category of tags managed by this tab
  attr_reader :name
  
  # Creates a new instance of TagTab.
  #
  # @param parent [JFrame] the parent frame of the program
  # @param owner [DataTab] the data tab that manages the tab
  # @param name [Symbol,String] the name of category of tags for the tab
  # @param values [Hash] a hash of tags to be managed by the tab
  # @return [TagTab] a new instance of TagTab
  def initialize(parent, owner, name, values)
    super(GridBagLayout.new)
    @parent = parent
    @owner = owner
    @name = name
    @values = values
    @contents = {}
    @to_init = []
    @constraints = GridBagConstraints.new
    reset_constraints(@constraints)
    @constraints.fill = GridBagConstraints::BOTH
    @constraints.gridwidth = GridBagConstraints::REMAINDER
    @constraints.weightx = 1
    @delete_item = ListDeleteAction.new
    @undo_actions = {}
    @redo_actions = {}
    @undo_managers = {}
    @undo_listener = UndoableEditListener.impl { |m,e|
      s = e.source
      @undo_managers[s].add_edit(e.edit)
      @undo_actions[s].update
      @redo_actions[s].update
    }
    build_contents
  end
  
  # Adds a listener to a given combo box to update a tag's values based on the
  # user's selection.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular combo box in the tag's
  #   parameters list
  # @param box [JComboBox] the combo box that the listener will be added to
  # @return [void]
  def add_combo_box_listener_to(key, index, box)
    i = (@contents[key] ? @contents[key][3][index] += 1 : 1) - 1
    box.add_action_listener(ActionListener.impl { |m,e|
      unless @setting_data
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = ((h1[@owner.selection] ||= {})[key.to_sym] ||= [])
        h3 = (h2[i] ||= [])
        if box.selected_index == 0 && box.selected_item == ' '
          h3[index] = nil
          h2.delete_at(i) if h3.compact.empty?
          h1[@owner.selection].delete(key.to_sym) if h2.empty?
        else
          if (block = @values[key][1][:params][4])
            h3[index] = block.call(box.get_selected_item)
          else h3[index] = box.get_selected_item end
        end
        @owner.update_demi_data
        @parent.modified = true unless @first_run
      end
    })
  end
  
  # Adds a listener to a text input field to update a tag's values based on the
  # user's input. Also adds undo/redo functionality to the field.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular text field in the tag's
  #   parameters list
  # @param box [JTextComponent] the text input field that the listener will be
  #   added to
  # @return [void]
  def add_document_listener_to(key, index, field)
    i = (@contents[key] ? @contents[key][3][index] += 1 : 1) - 1
    field.document.add_document_listener(DocumentListener.impl { |m,e|
      unless @setting_data
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = ((h1[@owner.selection] ||= {})[key.to_sym] ||= [])
        h3 = (h2[i] ||= [])
        if m == :removeUpdate && field.get_text.empty?
          h3[index] = nil
          h2.delete_at(i) if h3.compact.empty?
          h1[@owner.selection].delete(key.to_sym) if h2.empty?
        else
          if (block = @values[key][1][:params][4])
            h3[index] = block.call(field.get_text)
          else h3[index] = field.get_text end
        end
        @owner.update_demi_data
        @parent.modified = true unless @first_run
      end
    })
    manager = UndoManager.new
    u = UndoAction.new(manager)
    r = RedoAction.new(manager)
    @undo_managers[field.document] = manager
    @undo_actions[field.document] = u
    @redo_actions[field.document] = r
    u.redo_action = r 
    r.undo_action = u
    field.input_map.put(KeyStroke.getKeyStroke("control Z"), 'undo')
    field.input_map.put(KeyStroke.getKeyStroke("control Y"), 'redo')
    field.action_map.put('undo', u)
    field.action_map.put('redo', r)
    field.document.add_undoable_edit_listener(@undo_listener)
  end
  
  # Adds the proper component for a given parameter of a tag.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param panel [JPanel] the panel to which the component should be added
  # @param v [Array] an array of data about the particular parameter
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param c [GridBagConstraints] the passed panel's constraints object
  # @return [void]
  def add_variable_component(key, index, panel, v, variable_data, c)
    case v[0]
    when :Boolean
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_bool_entry(key, index, v, variable_data[1][:script]), c)
    when :Float
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_float_entry(key, index, v, variable_data[1][:script]), c)
    when :Integer
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_integer_entry(key, index, v, variable_data[1][:script]),
                                                                              c)
    when :Paragraph
      c.gridheight = 5
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_paragraph_entry(key, index, v,
                                                  variable_data[1][:script]), c)
      c.gridheight = 1
    when :String
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_string_entry(key, index, v, variable_data[1][:script]), c)
    when :FloatArray, :IntegerArray, :StringArray
      c.gridheight = 5
      add_label(panel, "#{v[1]} ", v[2], variable_data[1][:script], c)
      panel.add(build_variable_list(key, index, v, variable_data[1][:script]),
                                                                              c)
      c.gridheight = 1
    end
    c.gridy += 1
  end
  
  # Adds the label for a parameter of a tag.
  #
  # @param panel [JPanel] the panel to which the label should be added
  # @param name [String] the name of the parameter
  # @param help [String] the parameter's help text
  # @param author_data [Array<String>] the tag's author data
  # @param constraints [GridBagConstraints] the passed panel's constraints
  #   object
  # @return [void]
  def add_label(panel, name, help, author_data, constraints)
    constraints.anchor = GridBagConstraints::CENTER
    constraints.fill = GridBagConstraints::NONE
    constraints.gridwidth = 1
    constraints.gridx = 0
    constraints.weightx = 0
    label = JLabel.new(name)
    label.tool_tip_text = make_tool_tip(help, author_data)
    panel.add(label, constraints)
    constraints.gridx = 1
    constraints.fill = GridBagConstraints::BOTH
    constraints.gridwidth = GridBagConstraints::REMAINDER
    constraints.anchor = GridBagConstraints::WEST
    constraints.weightx = 1.0
    constraints.weighty = 1.0
  end
  
  # Builds the contents of the tab based on its managed tags.
  #
  # @return [void]
  def build_contents
    # Sorts the tags alphabetically by their display names for the sake of an
    # ordered tab.
    @values.sort_by { |k,v| v[1][:name] }.each do |k,v|
      # Make a panel for the tag.
      panel = JPanel.new(GridBagLayout.new)
      c = GridBagConstraints.new
      reset_constraints(c)
      c.anchor = GridBagConstraints::CENTER
      # Creates the label for the tag.
      text = JLabel.new("#{v[1][:name]} ")
      text.tool_tip_text = make_tool_tip(v[1][:description], v[1][:script])
      panel.add(text, c)
      # If the tag is repeatable, we need to let the user add more, so we create
      # a button and set it to create a new copy of the panel's contents.
      if v[1][:repeatable]
        button = JButton.new('Add')
        button.tool_tip_text = 'Adds a copy of the tag.'
        button.add_action_listener(ActionListener.impl { |m,e|
          @contents[k][2].fill = GridBagConstraints::BOTH
          @contents[k][0].add(build_variable_panel(k, @contents[k][1]),
                                                                @contents[k][2])
          init_all
          @contents[k][2].gridy += 1
          @owner.scroll_panes[self].revalidate
        })
        c.gridy = 1
        c.anchor = GridBagConstraints::NORTH
        c.ipady = 0
        c.insets = Insets.new(-2, 0, 0, 0)
        panel.add(button, c)
        c.gridy = 0
        c.ipady = 4
        c.insets = Insets.new(2, 2, 2, 2)
        c.anchor = GridBagConstraints::CENTER
      end
      c.gridx = 1
      c.weightx = 1
      c.gridwidth = GridBagConstraints::REMAINDER
      c.fill = GridBagConstraints::BOTH
      # Build the rest of the panel's content.
      panel.add(build_variable_panel(k, v), c)
      c.gridy += 1
      i = [1] * v[1][:params].keys.size
      @contents[k] = [panel, v, c, i]
      # Wrap the panel in a scroll pane and add it to the tab.
      self.add(JScrollPane.new(panel), @constraints)
      @constraints.gridy += 1
    end
  end
  
  # Creates a checkbox for tags that use a boolean parameter.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [JCheckBox] a checkbox component keyed to the tag
  def build_bool_entry(key, index, variable_data, author_data)
    entry = JCheckBox.new
    entry.add_item_listener(ItemListener.impl {
      unless @setting_data
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = (h1[@owner.selection] ||= {})
        if entry.selected then h2[key.to_sym] = [[true]]
        else h2.delete(key.to_sym) end
        @owner.update_demi_data
        @parent.modified = true unless @first_run
      end
    })
    entry.tool_tip_text = make_tool_tip(variable_data[2], author_data)
    entry
  end
  
  # Creates a combo box for users to choose an option from.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [JComboBox] a combo box containing the given data
  def build_combo_box(key, index, variable_data, author_data)
    entry = JComboBox.new
    add_combo_box_listener_to(key, index, entry)
    @to_init << [entry, variable_data[3], variable_data[5]]
    entry.tool_tip_text = make_tool_tip(variable_data[2], author_data)
    entry
  end
  
  # Creates a decimal entry field for parameters that require float values.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [TextField] a TextField in double mode keyed to the tag
  def build_float_entry(key, index, variable_data, author_data)
    if variable_data[3]
      build_combo_box(key, index, variable_data, author_data)
    else
      field = TextField.new
      field.mode = 2
      add_document_listener_to(key, index, field)
      field.tool_tip_text = make_tool_tip(variable_data[2], author_data)
      field
    end
  end
  
  # Creates an integer entry field for parameters that require integer values.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [TextField] a TextField in integer mode keyed to the tag
  def build_integer_entry(key, index, variable_data, author_data)
    if variable_data[3]
      build_combo_box(key, index, variable_data, author_data)
    else
      field = TextField.new
      field.mode = 1
      add_document_listener_to(key, index, field)
      field.tool_tip_text = make_tool_tip(variable_data[2], author_data)
      field
    end
  end
  
  # Creates a multiline text entry field for parameters that require long text
  # values.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [JTextArea] a multiline JTextArea keyed to the tag
  def build_paragraph_entry(key, index, variable_data, author_data)
    field = JTextArea.new
    field.line_wrap = true
    field.wrap_style_word = true
    field.rows = 5
    add_document_listener_to(key, index, field)
    field.tool_tip_text = make_tool_tip(variable_data[2], author_data)
    field
  end
  
  # Creates a single-line text entry field for parameters that require short
  # text values.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [TextField] a TextField in string mode keyed to the tag
  def build_string_entry(key, index, variable_data, author_data)
    if variable_data[3]
      build_combo_box(key, index, variable_data, author_data)
    else
      field = TextField.new
      add_document_listener_to(key, index, field)
      field.tool_tip_text = make_tool_tip(variable_data[2], author_data)
      field
    end
  end
  
  # Creates a list component for tags that allow use a :rest style parameter.
  #
  # @param key [Symbol,String] the key of the tag
  # @param index [Integer] the index of the particular parameter in the tag's
  #   parameters list
  # @param variable_data [Array] an array of data about the tag as a whole
  # @param author_data [Array<String>] the tag's author data
  # @return [JList] a list keyed to the tag
  def build_variable_list(key, index, variable_data, author_data)
    list = JList.new(DefaultListModel.new)
    list.input_map.put(KeyStroke.getKeyStroke("DELETE"), "delete_item")
    list.action_map.put("delete_item", @delete_item)
    list.cell_renderer = ListBackground.new
    list.selection_mode = ListSelectionModel::SINGLE_SELECTION
    5.times { list.model.add_element(' ') }
    list.tool_tip_text = make_tool_tip(variable_data[2], author_data)
    # If the plugin creator has provided specific selectable values for the
    # list's contents, we handle that here.
    if variable_data[3]
      list.add_mouse_listener(MouseListener.impl { |m,e|
        unless @setting_data
          if @parent.project && m == :mouseClicked && e.click_count >= 2
            data = variable_data[3].call.compact
            if variable_data[5]
              data = data.collect { |v| variable_data[5].call(v) }.to_java
            else data = data.select { |v| !v.empty? }.to_java end
            if value = list_prompt(variable_data[1], variable_data[2], data)
              if list.selected_value == ' '
                if (ind = list.model.index_of(' ')) == list.model.size - 1
                  list.model.add(ind, value)
                  list.selected_index = ind
                else
                  list.model.remove(ind)
                  list.model.add(ind, value)
                  list.selected_index = ind
                end
              else
                ind = list.get_selected_index
                list.model.remove(ind)
                list.model.add(ind, value)
                list.selected_index = ind
              end
            end
          end
        end
      })
    # The else case runs if the user has free reign with their choices.
    else
      list.add_mouse_listener(MouseListener.impl { |m,e|
        unless @setting_data
          if @parent.project && m == :mouseClicked && e.click_count >= 2
            if value = value_prompt(*variable_data)
              if list.selected_value == ' '
                if (ind = list.model.index_of(' ')) == list.model.size - 1
                  list.model.add(ind, value)
                  list.selected_index = ind
                else
                  list.model.remove(ind)
                  list.model.add(ind, value)
                  list.selected_index = ind
                end
              else
                ind = list.get_selected_index
                list.model.remove(ind)
                list.model.add(ind, value)
                list.selected_index = ind
              end
            end
          end
        end
      })
    end
    # Add a listener to update modified data when the list is altered.
    i = (@contents[key] ? @contents[key][3][index] += 1 : 1) - 1
    list.model.add_list_data_listener(ListDataListener.impl { |m,e|
      unless @setting_data
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = ((h1[@owner.selection] ||= {})[key.to_sym] ||= [])
        h3 = (h2[i] ||= [])
        (h3[index] ||= []).clear
        list.model.size.times do |n|
          next if list.model.get(n).strip.empty?
          if (block = @values[key.to_sym][1][:params][:rest][4])
            h3[index] << block.call(list.model.get(n))
          else
            h3[index] << list.model.get(n)
          end
        end
        h3.delete_at(index) if h3[index].compact.empty?
        h2.delete_at(i) if h3.compact.empty?
        h1[@owner.selection].delete(key.to_sym) if h2.empty?
        @owner.update_demi_data
        @parent.modified = true unless @first_run
      end
    })
    list
  end
  
  # Sets up the panel with user-inputable components for a tag.
  #
  # @param key [Symbol] the tag's key
  # @param variable_data [Array] an array of data connected to the tag
  # @return [JScrollPane] a scroll pane wrapping a panel of components
  def build_variable_panel(key, variable_data)
    # Make a panel for the components.
    panel = JPanel.new(GridBagLayout.new)
    c = GridBagConstraints.new
    reset_constraints(c)
    # Iterate through each parameter of the tag and add the appropriate
    # components.
    variable_data[1][:params].values.each_with_index do |v,i|
      add_variable_component(key, i, panel, v, variable_data, c)
    end
    # Wrap the panel in a scroll pane.
    scroll_pane = JScrollPane.new(panel)
    # If the tag is repeatable, we add a button that lets the user remove each
    # copy.
    if variable_data[1][:repeatable]
      c.anchor = GridBagConstraints::CENTER
      c.fill = GridBagConstraints::NONE
      button = JButton.new('Remove')
      button.add_action_listener(ActionListener.impl { |m,e|
        grid = @contents[key][0].get_layout
        # This is the reason that removing the first two copies of any given tag
        # will cause the third to have space above it -- we use the gridy to
        # determine the relative position of the tag. We could allow new copies
        # to be placed higher, yes, but that would look awkward for the user as
        # well. I may end up changing my mind in a later update, though.
        i = grid.get_constraints(scroll_pane).gridy
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = ((h1[@owner.selection] ||= {})[key.to_sym] ||= [])
        h2[i] = nil
        h1[@owner.selection].delete(key.to_sym) if h2.empty?
        @owner.update_demi_data
        @parent.modified = true unless @first_run
        @contents[key][0].remove(scroll_pane)
        @owner.scroll_panes[self].revalidate
        @contents[key][0].repaint
      })
      panel.add(button, c)
    end
    scroll_pane
  end
  
  # Sets up all combo boxes that are awaiting initialization.
  #
  # @return [void]
  def init_all
    @to_init.each do |c|
      data = [' '].concat(c[1].call.compact)
      if c[2]
        data = [' '].concat(data.collect { |v| c[2].call(v) }.to_java)
      else data = data.select { |v| !v.empty? }.to_java end
      c[0].model = DefaultComboBoxModel.new(data)
    end
    @to_init.clear
  end
  
  # Shows a dialog allowing the user to change a value in a list to a selection
  # based on the parameter.
  #
  # @param title [String] the title of the dialog
  # @param prompt [String] the dialog's prompt message
  # @param list [Array<String>] the possible choices for the parameter
  # @return [String] the user's selection
  def list_prompt(title, prompt, list)
    @parent.show_choice_dialog(title, prompt, list)
  end
  
  # Creates the text of a tool tip from the given data.
  #
  # @param help [String] the base help text of the tool tip
  # @param author_data [Array<String>] the tag's author data
  def make_tool_tip(help, author_data)
    "<html>Author: #{author_data[:author]}<br>" <<
                         "Source: #{author_data[:source]}<br><br>#{help}</html>"
  end
  
  # Removes all components from the tab and clears its variables.
  #
  # @return [void]
  def removeAll
    super
    @parent = nil
    @owner = nil
    @values = nil
    @constraints = nil
    @undo_listener = nil
    @undo_managers.clear
    @undo_actions.each_value { |u| u.clear }
    @undo_actions.clear
    @redo_actions.each_value { |r| r.clear }
    @redo_actions.clear
    @contents.clear
  end
  
  # Clears all parameter components of a tag in preparation for the loading of a
  # new set of data.
  #
  # @param key [Symbol] the key of the tag
  # @return [void]
  def reset_tag_data(key)
    # We tell the tab that we're manually adjusting data, so it shouldn't update
    # the selected object's tags.
    @setting_data = true
    @contents[key][2].gridy = 0
    @contents[key][3] = [0] * @values[key][1][:params].keys.size
    # If it's a repeatable tag, we just need to kill all of its instances.
    if @values[key][1][:repeatable]
      @contents[key][0].components
                                .select { |c| c.is_a?(JScrollPane) }.each do |p|
        p.remove_all
        @contents[key][0].remove(p)
      end
    # If it's not, we need to take action on each of its parameters based on
    # their types.
    else
      @contents[key][0].components
                                .select { |c| c.is_a?(JScrollPane) }
                            .collect { |c| c.viewport.components[0].components }
                                                         .flatten.each do |c|
        if c.is_a?(JList)
          c.model.remove_all_elements
          5.times { c.model.add_element(' ') }
          c.repaint
        elsif c.is_a?(JCheckBox)
          c.selected = false
        elsif c.is_a?(JComboBox)
          c.selected_index = 0
        elsif c.is_a?(JTextField) || c.is_a?(JTextArea) || c.is_a?(TextField)
          c.set_text('') unless c.is_a?(JTextArea)
          if c.is_a?(JTextArea)
            c.line_wrap = false
            c.set_caret_position(0)
            c.set_text('')
            c.line_wrap = true
          end
          c.revalidate
        end
      end
    end
    @undo_managers.each_value { |u| u.discard_all_edits }
    # We're done setting up data, so we tell the tab that anything that happens
    # from here on out is the user's input.
    @setting_data = false
  end
  
  # Resets a constraints object to some default settings.
  #
  # @param constraints [GridBagConstraints] the constraints object that we're
  #   resetting
  # @return [void]
  def reset_constraints(constraints)
    constraints.gridx = 0
    constraints.gridy = 0
    constraints.gridwidth = 1
    constraints.gridheight = 1
    constraints.weightx = 0
    constraints.weighty = 0
    constraints.anchor = GridBagConstraints::WEST
    constraints.fill = GridBagConstraints::NONE
    constraints.ipady = 4
    constraints.insets = Insets.new(2, 2, 2, 2)
  end
  
  # Resets the tab.
  #
  # @return [void]
  def reset_self
    init_all
    @contents.each_key { |k| reset_tag_data(k) }
  end
  
  # Sets the tab's tag components to match those of a selected object.
  #
  # @param tags [Hash] the tags of a selected object
  # @return [void]
  def set_data(tags)
    reset_self
    return unless tags
    # If it's the first run, we let the selected object's tags get updated so
    # that it has a baseline. If it's not, we tell the tab that we're manually
    # adjusting data, so it shouldn't update the selected object's tags.
    @first_run = !(@run ||= [])[@owner.selection]
    if @first_run then @run[@owner.selection] = true
    else @setting_data = true end
    # We go through each tag, locate the components associated with it, and
    # operate on them based on their type.
    tags.each_pair do |k,v|
      panes = @contents[k][0].components.select { |c| c.is_a?(JScrollPane) }
                               .collect { |c| c.viewport.components[0] }.flatten
      v.each_with_index do |params, i|
        # If a tag is repeatable, we need to add as many instances of it to the
        # object as there are instances in the data. This will be unnecessary in
        # v1.1, where repeatable tags will use a list-and-dialog-based interface
        # for easier maintenance.
        if @values[k][1][:repeatable]
          p = build_variable_panel(k, @contents[k][1])
          @contents[k][0].add(p, @contents[k][2])
          @owner.scroll_panes[self].revalidate
          @contents[k][2].gridy += 1
          panes << p.viewport.components[0]
          init_all
        end
        j = 0
        next unless panes[i]
        panes[i].components.each do |c|
          if c.is_a?(JScrollPane)
            c = c.viewport.components[0]
          end
          if c.is_a?(JList)
            c.model.remove_all_elements
            if @values[k][1][:params][:rest][3]
              container = @values[k][1][:params][:rest][3].call
              params[j..-1].each do |li|
                c.model.add_element(container[li.to_i])
              end
            else
              params[j..-1].each { |li| c.model.add_element("#{li}") }
            end
            if c.model.size < 5
              (5 - c.model.size).times { c.model.add_element(' ') }
            end
            j += 1
          elsif c.is_a?(JCheckBox)
            c.selected = true
            j += 1
          elsif c.is_a?(JComboBox)
            c.selected_item = params[j]
            j += 1
          elsif c.is_a?(JTextField) || c.is_a?(JTextArea) || c.is_a?(TextField)
            c.set_text(params[j])
            c.revalidate
            j += 1
          end
        end
      end
    end
    @undo_managers.each_value { |u| u.discard_all_edits }
    # We're done setting up data, so we tell the tab that anything that happens
    # from here on out is the user's input.
    @setting_data = false
    @first_run = false
  end
  
  # Shows a dialog allowing the user to change a value in a list to a value that
  # they enter.
  #
  # @param type [Symbol,String,Integer] the type of input that the user can
  #   enter
  # @param title [String] the title of the dialog
  # @param prompt [String] the dialog's prompt message
  # @return [String] the user's input
  def value_prompt(type, title, prompt, *ignore)
    @parent.show_input_dialog(title, prompt, type)
  end
end

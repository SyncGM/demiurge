# DataTab
# -----------------------------------------------------------------------------
# Serves as a tab in {DemiurgeWindow}, but also holds and controls all tabs
# related to tags.
class DataTab < DataSplitPane

  # @return [String] the name of the data type managed by the DataTab
  attr_reader :name
  
  # @return [Array<JScrollPane>] the scroll panes managed by the DataTab
  attr_reader :scroll_panes
  
  # Creates a new instance of DataTab.
  #
  # @param parent [JFrame] the top-level frame of the program
  # @param name [String] the name of the data type managed by the DataTab
  # @param values [Hash] the tags used by the contents of the DataTab
  # @return [DataTab] a new instance of DataTab
  def initialize(parent, name, values)
    super()
    @parent = parent
    @name = name
    @values = values
    @soft_reset = false
    @copy = nil
    @last_selection = nil
    build_contents
  end
  
  # Creates the list used to select which item you want to edit.
  #
  # @return [void]
  def add_list
    @list_panel = JPanel.new(GridBagLayout.new)
    c = GridBagConstraints.new
    add_search(c)
    c.gridx = 0
    c.gridy = 1
    c.weightx = 1
    c.weighty = 1
    c.gridwidth = GridBagConstraints::REMAINDER
    c.gridheight = GridBagConstraints::REMAINDER
    c.fill = GridBagConstraints::BOTH
    @list = JList.new(DefaultListModel.new)
    @list.cell_renderer = ListBackground.new
    @list.selection_mode = ListSelectionModel::SINGLE_SELECTION
    @list.add_list_selection_listener(ListSelectionListener.impl {
      set_data unless @soft_reset
    })
    @copy_item = ListCopyAction.new(self)
    @list.input_map.put(KeyStroke.getKeyStroke("control C"), "copy_item")
    @list.action_map.put("copy_item", @copy_item)
    @paste_item = ListPasteAction.new(self)
    @list.input_map.put(KeyStroke.getKeyStroke("control V"), "paste_item")
    @list.action_map.put("paste_item", @paste_item)
    @list_container = JScrollPane.new(@list)
    @list_panel.add(@list_container, c)
    self.left_component = @list_panel
  end
  
  # Creates the tabbed pane used to hold tag panels.
  #
  # @return [void]
  def add_notebook
    @notebook = JTabbedPane.new
    @tag_tabs = []
    @scroll_panes = {}
    @values.values.collect { |v| v[1][:type] }.flatten.uniq.each do |type|
      t = TagTab.new(@parent, self, "#{type}",
                                   @values.select { |k,v| v[1][:type] == type })
      @tag_tabs << t
      @scroll_panes[t] = JScrollPane.new(t)
      @notebook.add("#{type}", @scroll_panes[t])
    end
    t = UncategorizedTab.new(@parent, self)
    @tag_tabs << t
    @scroll_panes[t] = JScrollPane.new(t)
    @notebook.add('Uncategorized', @scroll_panes[t])
    self.right_component = @notebook
  end
  
  # Adds a search bar that allows the user to look up particular items in the
  # list.
  #
  # @param constraints [GridBagConstraints] a constraints object for placement
  # @return [void]
  def add_search(constraints)
    constraints.gridx = 0
    constraints.gridy = 0
    constraints.weightx = 0
    constraints.weighty = 0
    constraints.gridwidth = 1
    constraints.gridheight = 1
    constraints.anchor = GridBagConstraints::WEST
    constraints.fill = GridBagConstraints::NONE
    search_label = JLabel.new("Search: ")
    search_label.tool_tip_text = '<html>Allows you to search for a ' <<
     'particular item in the list.<br>Uses Regular Expression searching.</html>'
    @list_panel.add(search_label, constraints)
    @search_box = TextField.new
    @search_box.tool_tip_text = '<html>Allows you to search for a particular' <<
                  ' item in the list. Uses Regular Expression searching.</html>'
    @search_box.document.add_document_listener(DocumentListener.impl {
      search_list(@search_box.text)
    })
    constraints.gridx = 1
    constraints.weightx = 1
    constraints.gridwidth = GridBagConstraints::REMAINDER
    constraints.fill = GridBagConstraints::HORIZONTAL
    @list_panel.add(@search_box, constraints)
  end
  
  # Creates the contents of the DataTab.
  #
  # @return [void]
  def build_contents
    add_list
    add_notebook
    self.divider_location = 150
  end
  
  # Pastes the copied tags into the given index.
  #
  # @param index [Integer] the index at which to paste the tags
  # @return [void]
  def pasteAtIndex(index)
    return unless @copy
    id = @list.model.get(index)[/^(\d+):/, 1].to_i
    @parent.modified_data[@name.to_sym][id] = @copy[0]
    @parent.demi_data[@name.to_sym][id] = @copy[1]
    set_data(true)
  end
  
  # Reloads the tab. Prepares its managed tabs for content, but does not reset
  # them.
  #
  # @return [void]
  def reload
    reset_list
    @tag_tabs.each { |t| t.init_all if t.respond_to?(:init_all) }
  end
  
  # Removes all components from the tab.
  #
  # @return [void]
  def removeAll
    super
    @parent = nil
    @values = nil
    @notebook = nil
    @list = nil
    @copy = nil
    @copy_item = nil
    @paste_item = nil
    @list_container = nil
    @list_panel = nil
    @search_box = nil
    @tag_tabs.clear
    @scroll_panes.clear
  end
  
  # Reloads the tab. Prepares its managed tabs for content and resets them.
  #
  # @return [void]
  def reset_all
    reload
    @tag_tabs.each { |t| t.reset_self if t.respond_to?(:reset_self) }
  end
  
  # Refreshes the list with new contents.
  #
  # @return [void]
  def reset_list(keep_index = false)
    @last_selection = nil unless keep_index
    @list.model.remove_all_elements
    list = []
    if Object.const_defined?("Data_#{@name}")
      list = Object.const_get("Data_#{@name}")
    end
    list.compact.each do |v|
      @list.model.add_element("#{sprintf('%03d', v.id)}: #{v.name}")
    end
    @full_list = @list.model.to_array
    if keep_index
      @soft_reset = true
      @list.selected_index = (@last_selection ? @last_selection - 1 : 0)
      @soft_reset = false
    else
      @list.selected_index = 0 unless @full_list.empty?
    end
  end
  
  # Searches the list for a term and updates it with all matches.
  #
  # @param term [String] the term to match against the contents of the list
  # @return [void]
  def search_list(term)
    return if term[/(?:\\|\(|\)|\[|\]|\|)$/] || term[/\([^\)]+$/] ||
                                      term[/\[[^\]]+$/] || term[/^(?:\*|\+|\?)/]
    if term.empty? then reset_list
    else
      @last_selection = nil
      @list.model.remove_all_elements
      @full_list.select { |v| v[Regexp.new(term, true)] }.each do |v|
        @list.model.add_element(v)
      end
    end
  end
  
  # The ID of the current list selection.
  #
  # @return [Integer] the ID of the current list selection, or -1 if there is
  #   no selection
  def selection
    v = @list.get_selected_value
    v ? v[/^(\d+):/, 1].to_i : -1
  end
  
  # Sets the item whose tags should be copied.
  def setCopy(item)
    id = item[/^(\d+):/, 1].to_i
    @copy = [
            Marshal.load(Marshal.dump(@parent.modified_data[@name.to_sym][id])),
                Marshal.load(Marshal.dump(@parent.demi_data[@name.to_sym][id]))]
  end
  
  # Sets the data of all managed tabs to the current selection.
  #
  # @return [void]
  def set_data(force = false)
    if (v = @list.get_selected_value) && (id = v[/^(\d+):/, 1].to_i)
      if force || @last_selection != id
        @last_selection = id
        @parent.modified_data[@name.to_sym][id] ||= {}
        @parent.demi_data[@name.to_sym][id] ||= Data[@name.to_sym][id].note
        tags = {}
        data = "#{@parent.demi_data[@name.to_sym][id]}"
        @values.each_pair do |k,v|
          data.gsub!(v[2][1]) do
            params = $~[1..-1]
            if v[1][:params].keys.include?(:rest)
              params.concat(params.pop.split(/,\s*/))
              params = params.flatten
            end
            ((tags[v[1][:type]] ||= {})[k] ||= []) << params
            ''
          end
        end
        tags[:Uncategorized] = data.strip
        @tag_tabs.each do |t|
          t.set_data(tags[t.name.to_sym])
        end
        @tag_tabs.each(&:revalidate)
      end
    end
  end
  
  # Updates the tag data for the current selection.
  #
  # @return [void]
  def update_demi_data
    return unless (v = @list.get_selected_value) &&
          (id = v[/^(\d+):/, 1].to_i) && @parent.modified_data[@name.to_sym][id]
    @str = ''
    @parent.modified_data[@name.to_sym][id].each_pair do |k,v|
      if k == :Uncategorized
       @str = "#{@str}#{v.strip}\n"
      else
        p = Register::Data[@name.singular.to_sym][k]
        if p
          p = p[2][0]
          v.compact.each do |params|
            @str = "#{@str}#{p.call(*params.flatten)}\n"
          end
        end
      end
    end
    @parent.demi_data[@name.to_sym][id] = "#{@str}"
  end
end

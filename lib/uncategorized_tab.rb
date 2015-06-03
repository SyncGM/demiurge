# UncategorizedTab
# -----------------------------------------------------------------------------
# Acts as an interface to work with tags that lack plugins.
class UncategorizedTab < JPanel
  
  # @return [String] the name of the category of tags managed by this tab
  attr_reader :name
  
  # Creates a new instance of UncategorizedTab.
  #
  # @param parent [JFrame] the parent frame of the program
  # @param owner [DataTab] the data tab that manages the tab
  # @return [UncategorizedTab] a new instance of UncategorizedTab
  def initialize(parent, owner)
    super(GridBagLayout.new)
    @parent = parent
    @owner = owner
    @name = :Uncategorized
    @undo_manager = UndoManager.new
    @undo = UndoAction.new(@undo_manager)
    @redo = RedoAction.new(@undo_manager)
    @undo.redo_action = @redo
    @redo.undo_action = @undo
    @undo_listener = UndoableEditListener.impl { |m,e|
      @undo_manager.add_edit(e.edit)
      @undo.update
      @redo.update
    }
    build_contents
  end
  
  # Builds the contents of the tab.
  #
  # @return [void]
  def build_contents
    c = GridBagConstraints.new
    c.fill = GridBagConstraints::BOTH
    c.gridwidth = GridBagConstraints::REMAINDER
    c.gridheight = GridBagConstraints::REMAINDER
    c.weightx = 1
    c.weighty = 1
    @text_entry = JTextArea.new
    @text_entry.line_wrap = true
    @text_entry.wrap_style_word = true
    @text_entry.document.add_document_listener(DocumentListener.impl { |m,e|
      unless @setting_data
        h1 = @parent.modified_data[@owner.name.to_sym] ||= {}
        h2 = (h1[@owner.selection] ||= {})
        h2[:Uncategorized] = @text_entry.text
        @owner.update_demi_data
        @parent.modified = true unless @first_run
      end
    })
    @text_entry.input_map.put(KeyStroke.getKeyStroke("control Z"), 'undo')
    @text_entry.input_map.put(KeyStroke.getKeyStroke("control Y"), 'redo')
    @text_entry.action_map.put('undo', @undo)
    @text_entry.action_map.put('redo', @redo)
    @text_entry.document.add_undoable_edit_listener(@undo_listener)
    scroll_pane = JScrollPane.new(@text_entry)
    add(scroll_pane, c)
  end
  
  # Removes all components from the tab and clears its variables.
  #
  # @return [void]
  def removeAll
    super
    @parent = nil
    @owner = nil
    @undo.clear
    @redo.clear
    @undo = nil
    @redo = nil
    @undo_manager = nil
    @undo_listener = nil
    @text_entry = nil
  end
  
  # Resets the tab.
  #
  # @return [void]
  def reset_self
    @setting_data = true
    @text_entry.line_wrap = false
    @text_entry.caret_position = 0
    @text_entry.text = ''
    @text_entry.line_wrap = true
    revalidate
    @undo_manager.discard_all_edits
    @setting_data = false
  end
  
  # Sets the tab's tag components to match those of a selected object.
  #
  # @param tags [Hash] the tags of a selected object
  # @return [void]
  def set_data(data)
    reset_self
    return unless data
    # If it's the first run, we let the selected object's tags get updated so
    # that it has a baseline. If it's not, we tell the tab that we're manually
    # adjusting data, so it shouldn't update the selected object's tags.
    @first_run = !(@run ||= [])[@owner.selection]
    if @first_run then @run[@owner.selection] = true
    else @setting_data = true end
    @text_entry.text = data
    @undo_manager.discard_all_edits
    # We're done setting up data, so we tell the tab that anything that happens
    # from here on out is the user's input.
    @setting_data = false
    @first_run = false
  end
end

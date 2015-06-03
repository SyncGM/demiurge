# Register
# ---------------------------------------------------------------------------
# Handles the tags used by Demiurge.
module Register
  @in_definition = false
  @config = { name: '', description: '', repeatable: false,
                   script: { author: '', source: '' }, type: :General,
                                                                    params: {} }
  # The list of tags and their associated properties.
  Data = {}
  
  # Defines a tag for the Register.
  #
  # @param klass [String, Symbol] the class for which the tag is being defined
  # @yield runs a block in the context of the Register to define a tag
  def self.add(klass = nil, &block)
    @in_definition = true
    params = (klass ? [[nil,klass]].concat(block.parameters) : block.parameters)
    keys = [to_class_name(params[0][1]), params[1][1]]
    keys.concat(params[2..-1].collect do |p|
     :"#{(p[0] == :rest ? '*' : '')}#{p[1]}"
    end)
    (Data[keys[0]] ||= {})[keys[1]] = [[*keys[2..-1]], @config, 
                                                          instance_exec(&block)]
    @config = { name: '', description: '', repeatable: false,
                script: { author: '', source: '' }, type: :General, params: {} }
    @in_definition = false
  end
  
  # Resets tag data.
  #
  # @return [void]
  def self.clear_data
    Data.clear
    [:Actor, :Class, :Skill, :Item, :Weapon, :Armor, :Enemy, :State, :Tileset,
     :Map].each do |d|
      Data[d] = {}
    end
  end
  
  # Handles missing methods. If a tag is currently being defined, all unknown
  # setter methods are treated as keys in the tag's configuration hash.
  #
  # @param method [Symbol] the name of the missing method
  # @param args [Array] all of the arguments passed to the method
  # @return [void]
  def self.method_missing(method, *args, &block)
    if @in_definition
      if method[/(.+)=/]
        @config[$1.to_sym] = (args.size > 1 ? args : args[0])
      elsif @config[method] then @config[method]
      else super(method, *args, &block) end
    else super(method, *args, &block) end
  end
  
  # Sets the name of the author and script that a plugin is designed for.
  #
  # @param author [String] the name of the author
  # @param script [String] the name of the script
  # @return [void]
  def self.notify(author, script)
    @config[:script][:author] = author
    @config[:script][:source] = script
  end
  
  # Converts type names provided by tags into class names.
  #
  # @param sym [Symbol,String] the type name to turn into a class name
  # @param [String] the class name of the given type
  def self.to_class_name(sym)
    "#{sym}".capitalize.gsub(/_(\w)/) { "_#{$1.upcase}" }
                                                     .gsub('__') { '::' }.to_sym
  end
end

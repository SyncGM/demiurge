# String
# -----------------------------------------------------------------------------
# Ruby's base class for strings.
class String
  
  # Performs a simple pluralization to the string. Does not handle special
  # cases (e.g. mouse -> mice, goose -> geese, fish -> fish).
  #
  # @return [String] a pluralized string
  def pluralize
    if self[/y$/] then self.sub(/y$/) { 'ies' }
    elsif self[/x$/] then self.sub(/x$/) { 'ces' }
    elsif self[/s$/] then self.sub(/s$/) { 'ses' }
    else "#{self}s" end
  end
  
  # Attempts to convert the string to its singular form. Does not handle
  # special cases.
  #
  # @return [String] a singular string
  def singular
    return self unless self[/s$/]
    if self[/ies$/] then self.sub(/ies$/) { 'y' }
    elsif self[/ces$/] then self.sub(/ces$/) { 'x' }
    elsif self[/es$/] then self.sub(/es$/) { '' }
    else self.sub(/s$/) { '' } end
  end
end

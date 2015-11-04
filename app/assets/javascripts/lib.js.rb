class Element
  def attributes
    %x{
      var first = self[0];
      var attributes = [];

      for (var i=0; i<first.attributes.length; i++) {
        attributes.push([first.attributes.item(i).nodeName, first.attributes.item(i).nodeValue]);
      }

      return attributes;
    }
  end

  def node_type
    %x{
      var first = self[0];

      return first.nodeType;
    }
  end
end

class Proc
  attr_accessor :_inject

  def parameters
    /.*function[^(]*\(([^)]*)\)/.match(`#{self}.toString()`)[1].split(",").collect { |param| param.strip.gsub('$', '') }
  end
end

class Timeout
  puts "Timeout required"
  def initialize(time=0, &block)
    @timeout = `setTimeout(#{block}, time)`
  end

  def clear
    `clearTimeout(#{@timeout})`
  end
end
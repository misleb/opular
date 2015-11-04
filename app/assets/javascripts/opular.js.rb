require 'parse'
require 'injector'
require 'scope'
require 'compile'
require 'directive'

class OpularRB
  attr_reader :modules

  def initialize
    @modules = {}
  end

  def self.boot
    $opular ||= new

    $opular.module('op', [])
      .provider('_parse', Op::Parse)
      .provider('_root_scope', Op::Scope)
      .provider('_compile', Op::Compile)
      .directive('op_app', Op::Directive::App)

  end

  def module(name, requires = nil, &configFn)
    if requires
      @modules[name] = OpModule.new(name, requires, &configFn)
    else
      if @modules.key?(name)
        @modules[name]
      else
        raise "Module #{name} is not available!"
      end
    end
  end

  class OpModule
    attr_reader :name, :requires, :_invoke_queue, :_config_blocks, :_run_blocks

    def initialize(name, requires, &configFn)
      @name = name
      @requires = requires
      @_invoke_queue = []
      @_config_blocks = []
      @_run_blocks = []

      if block_given?
        config(&configFn)
      end
    end

    def invoke_later(service, method, arguments, array_meth = 'push', queue = nil)
      (queue || @_invoke_queue).send(array_meth, [service, method, arguments]) and self
    end

    def constant(key, value)
      invoke_later('_provide', 'constant', [key, value], 'unshift')
    end

    def provider(key, provider)
      invoke_later('_provide', 'provider', [key, provider])
    end

    def factory(key, &factory)
      invoke_later('_provide', 'factory', [key, factory])
    end

    def value(key, value)
      invoke_later('_provide', 'value', [key, value])
    end

    def service(key, klass)
      invoke_later('_provide', 'service', [key, klass])
    end

    def directive(name, factory)
      invoke_later('_compile_provider', 'directive', [name, factory])
    end

    def config(&block)
      invoke_later('_injector', 'invoke', [block], 'push', @_config_blocks)
    end

    def run(&block)
      @_run_blocks << block
      self
    end
  end
end
require 'forwardable'

module Op
  class Injector
    extend Forwardable

    def_delegator :@instance_injector, :get_service, :get
    def_delegator :@instance_injector, :get_service, :get_service
    def_delegator :@instance_injector, :has?, :has?
    def_delegator :@instance_injector, :invoke, :invoke
    def_delegator :@instance_injector, :instantiate, :instantiate

    INSTANTIATING = -> {}

    def initialize(modules)
      @instance_cache = {}
      @provider_cache = {}
      @loaded_modules = {}

      @provider_injector = Internal.new(@provider_cache, @provider_cache) do |name, path|
        raise "Unknown provider: #{path.join(' <- ')}"
      end

      @instance_injector = Internal.new(@instance_cache, @provider_cache) do |name, path|
        provider = @provider_injector.get("#{name}_provider")
        @instance_injector.invoke(provider.method(:_get).to_proc, provider)
      end

      @provider = Provider.new(self)

      # Inject the injector
      @instance_cache['_injector'] = @instance_injector
      @provider_cache['_injector'] = @provider_injector
      @provider_cache['_provide']  = @provider

      load_modules(modules, run_blocks = [])

      run_blocks.select { |fn| fn.is_a?(Proc) || fn.is_a?(Array) }.each do |block|
        @instance_injector.invoke(block)
      end
    end

    def load_modules(names, run_blocks)
      names.each do |name|
        unless @loaded_modules[name]
          @loaded_modules[name] = true

          if name.is_a?(String)
            mod = $opular.module(name)

            load_modules(mod.requires)
            run_invoke_queue(mod._invoke_queue)
            run_invoke_queue(mod._config_blocks)
            run_blocks.push(*mod._run_blocks)
          elsif name.is_a?(Proc) || name.is_a?(Array)
            run_blocks << @provider_injector.invoke(name)
          else
            raise "Unknown module type: #{name}"
          end
        end
      end
    end

    def run_invoke_queue(queue)
      queue.each do |args|
        @provider_cache[args[0]].send(args[1], *args[2])
      end
    end
  end

  class Provider
    def initialize(injector)
      @injector = injector
    end

    def constant(key, value)
      @injector.instance_exec do
        @provider_cache[key] = @instance_cache[key] = value
      end
    end

    def factory(key, factory)
      provider(key, Factory.new(factory))
    end

    # TODO: Something is wrong  here, defining this before a service that depends on it causes a circular dependency.
    def value(key, value)
      factory(key, -> { value })
    end

    def service(key, klass)
      injector = @injector
      factory(key, -> { injector.instantiate(klass) })
    end

    def decorator(service_name, &block)
      @injector.instance_exec do
        provider = @provider_injector.get("#{service_name}_provider")
        original_get = provider.method(:_get).to_proc
        instance_injector = @instance_injector

        new_get = -> {
          instance = instance_injector.invoke(original_get, provider)
          instance_injector.invoke(block, nil, _delegate: instance)
          instance
        }

        provider.class.define_method(:_get, new_get)
      end
    end

    def provider(key, provider)
      @injector.instance_exec do
        if provider.is_a?(Class)
          provider = @provider_injector.instantiate(provider)
        end

        @provider_cache["#{key}_provider"] = provider
      end
    end
  end

  class Factory
    def initialize(block)
      @block = block
    end

    def _get(_injector)
      _injector.invoke(@block)
    end
  end

  class Internal
    def initialize(cache, provider_cache, &factory)
      @cache = cache
      @provider_cache = provider_cache
      @factory = factory
      @path = []
    end

    def get_service(name)
      if @cache[name]
        raise "Circular dependency found: #{[name, *@path].join(' <- ')}" if @cache[name] == Injector::INSTANTIATING
        @cache[name]
      else
        @cache[name] = Injector::INSTANTIATING
        @path.unshift(name)

        begin
          return @cache[name] = @factory.call(name, @path)
        ensure
          @path.shift
          @cache.delete(name) if @cache[name] == Injector::INSTANTIATING
        end
      end
    end
    alias :get :get_service

    def has?(key)
      !!(@cache[key] || @provider_cache["#{key}_provider"])
    end

    def invoke(block, this = nil, locals = nil)
      args = annotate(block).map do |token|
        raise "Invalid injection token: #{token.inspect}" unless token.is_a?(String)
        (locals && locals.key?(token)) ? locals[token] : get_service(token)
      end

      block = block.last if block.is_a?(Array)

      this ? this.instance_exec(*args, &block) : block.call(*args)
    end

    # klass may be an annotation array w/ Class or just a Class
    #
    def instantiate(klass, locals = nil)
      unwrapped_klass = klass.is_a?(Array) ? klass.last : klass
      instance = unwrapped_klass.allocate
      proc = instance.method(:initialize).to_proc

      klass.is_a?(Array) ? (klass[-1] = proc) : (klass = proc)

      invoke(klass, instance, locals)
      instance
    end

    def annotate(fn)
      if fn.is_a?(Array)
        fn[0..-2]
      elsif fn.respond_to?(:_inject) && fn._inject
        fn._inject
      else
        fn.parameters
      end
    end
  end
end

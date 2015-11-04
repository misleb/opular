module Op
  class Scope < OpenStruct
    DIGEST_TTL = 10

    attr_reader :__watchers, :__async_queue, :__phase, :__apply_async_queue,
                :__apply_async_id, :__post_digest_queue, :__children, :_parent,
                :_isolated, :_root, :_parse, :_h_parent

    attr_accessor :__last_dirty_watch

    def initialize
      @__watchers = []
      @__children = []

      super({})
    end

    def _get(_parse)
      # There can be only one root scope, this is it. Home of the queues.
      @__async_queue = []
      @__apply_async_queue = []
      @__post_digest_queue = []
      @_root = self

      @_parse = _parse and self
    end

    def _new(isolated: false, h_parent: self)
      Scope.new.tap do |s|
        # self is always the prototypical parent, but we might want to specify a different hierarchical parent
        s.instance_variable_set(:@_h_parent, h_parent)
        h_parent.__children << s

        s.instance_variable_set(:@_parent,             self)
        s.instance_variable_set(:@_isolated ,          isolated)
        s.instance_variable_set(:@__async_queue,       __post_digest_queue)
        s.instance_variable_set(:@__apply_async_queue, __apply_async_queue)
        s.instance_variable_set(:@__post_digest_queue, __post_digest_queue)
        s.instance_variable_set(:@_root,               _root)
        s.instance_variable_set(:@_parse,              _parse)
      end
    end

    def digest_ttl(value = nil)
      Scope::DIGEST_TTL = value if value.is_a?(Fixnum)

      DIGEST_TTL
    end

    def _destroy
      return unless @_h_parent

      @_h_parent.__children.delete_if { |c| c.equal?(self) }
    end

    def _watch(watchFn, listenerFn, by_value = false)
      _root.__last_dirty_watch = nil
      __watchers << Watcher.new(_parse.proc(watchFn), listenerFn, by_value)
    end

    def _eval_async(expr = nil, &block)
      if !@__phase && @__async_queue.empty?
        Timeout.new(0) do
          self._root._digest if @__async_queue.any?
        end
      end

      @__async_queue << (block_given? ? block : expr)
    end

    def __post_digest(expr = nil, &block)
      @__post_digest_queue << (block_given? ? block : expr)
    end

    def _apply_async(expr = nil, &block)
      @__apply_async_queue << (block_given? ? block : expr)

      unless self._root.__apply_async_id
        self._root.__apply_async_id = Timeout.new(0) do
          _apply do
            _flush_apply_async
          end
        end
      end
    end

    def _digest(ttl = DIGEST_TTL)
      if ttl.zero?
        _clear_phase
        raise "Digest TTL reached"
      end

      if ttl == DIGEST_TTL
        self._root.__last_dirty_watch = nil
        _begin_phase('_digest')

        if self._root.__apply_async_id
          self._root.__apply_async_id.clear
          _flush_apply_async
        end
      end

      _consume_queue(@__async_queue)

      _digest_once && _digest(ttl -= 1)

      _consume_queue(@__post_digest_queue)

      _clear_phase
    end

    def _eval(expr, *locals)
      self.instance_exec(*locals, &(_parse.proc(expr)))
    end

    def _apply(expr = nil, &block)
      begin
        _begin_phase('_apply')
        _eval(expr || block)
      ensure
        _clear_phase
        self._root._digest
      end
    end

    def [](name)
      parent_or_table(name)
    end

    def inspect
      "#<#{self.class}: #{each_pair.map {|name, value|
        "#{name}=#{value == self ? 'self' : value.inspect}"
      }.join(" ")}>"
    end

    private

    def method_missing(name, *args)
      if name.end_with? '='
        @table[name[0 .. -2].to_sym] = args[0]
      else
        parent_or_table(name)
      end
    end

    def parent_or_table(name)
      if @table.key?(name.to_sym)
        @table[name.to_sym]
      elsif @_parent && !@_isolated
        @_parent.send(name.to_sym)
      end
    end

    def _flush_apply_async
      _consume_queue(@__apply_async_queue)
      self._root.__apply_async_id = nil
    end

    def _consume_queue(queue)
      queue.size.times do
        expr = queue.shift

        begin
          _eval(expr)
        rescue => e
          puts e.inspect
        end
      end
    end

    def _all_scopes(&block)
      if yield(self)
        @__children.all? do |child|
          child._all_scopes(&block)
        end
      else
        false
      end
    end

    def _digest_once
      dirty = false
      continue_loop = true

      _all_scopes do |scope|
        scope.__watchers.each do |watch|
          begin
            new_val = scope._eval(watch.watchFn)
            old_val = watch.last

            if new_val != old_val
               watch.listenerFn.call(new_val, (old_val == watch.init_val ? new_val : old_val), scope)
               watch.last = (watch.by_value && new_val && !new_val.is_a?(Numeric)) ? new_val.dup : new_val
               self._root.__last_dirty_watch = watch

               dirty = true
            elsif self._root.__last_dirty_watch == watch
              continue_loop = false
              break
            end
          rescue => e
            puts e.inspect
          end
        end

        continue_loop
      end

      return dirty || @__async_queue.any?
    end

    def _begin_phase(phase)
      raise "#{@__phase} already in progress" if @__phase
      puts(@__phase = phase)
    end

    def _clear_phase
      puts "clear #{@__phase}"
      @__phase = nil
    end
  end

  class Watcher
    attr_accessor :last, :by_value, :watchFn, :listenerFn

    def initialize(watchFn, listenerFn = -> {}, by_value = false)
      @watchFn = watchFn
      @listenerFn = listenerFn
      @by_value = by_value
      @last = init_val
    end

    def init_val
      @init_val ||= -> {}
    end
  end
end


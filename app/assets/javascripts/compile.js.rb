module Op
  class Compile
    attr_reader :_provide

    def initialize(_provide)
      @_provide = _provide;
    end

    def has_directives
      @has_directives ||= {}
    end

    def _get(_injector)
      @compiler ||= Compiler.new(_injector, has_directives)
    end

    def directive(name, factory)
      if name.is_a?(String)
        unless has_directives[name]
          has_directives[name] = []

          _provide.factory("#{name}_directive", ->(_injector) {
            has_directives[name].map do |n|
              if n.is_a?(Class)
                _injector.instantiate(n)
              else
                _injector.invoke(n)
              end
            end
          })
        end

        has_directives[name] << factory
      else
        name.each do |d_name, d_factory|
          directive(d_name, d_factory)
        end
      end
    end

    class Compiler
      attr_reader :_injector, :has_directives

      def initialize(_injector, has_directives)
        @_injector = _injector
        @has_directives = has_directives
      end

      def run(nodes)
        nodes.each do |node|
          terminal = apply_directives_to_node(collect_directives(node), node)
          run(node.children) unless terminal
        end
      end

      def collect_directives(node)
        [].tap do |directives|
          add_directive(directives, directive_normalize(node_name(node)), 'E')
          node.attributes.each do |attr|
            attr_start = attr_end = nil
            name = attr[0]

            normal_attr = directive_normalize(name)
            directive_n_name = normal_attr.gsub(/_(start|end)$/, '')

            if directive_is_multi_element(directive_n_name)
              if normal_attr =~ /start$/
                attr_start = name
                attr_end   = "#{name[0..-6]}end"
                name = name[0..-7]
              end
            end

            add_directive(directives, directive_normalize(name), 'A', attr_start, attr_end)
          end
        end.sort { |b,a| a.priority == b.priority ? b.name <=> a.name : a.priority <=> b.priority }
      end

      def directive_is_multi_element(name)
        if has_directives[name]
          _injector.get("#{name}_directive").any?(&:multi_element)
        end
      end

      def node_name(element)
        element.tag_name
      end

      def add_directive(directives, name, type, attr_start = nil, attr_end = nil)
        if has_directives[name]
          found = _injector.get("#{name}_directive")
          app = found.select { |dir| dir.restrict[type] }

          app.each do |directive|
            if attr_start
              directive = directive.dup.tap do |dir|
                dir.__start = attr_start
                dir.__end = attr_end
              end
            end

            directives << directive
          end
        end
      end

      def apply_directives_to_node(directives, node)
        term_priority = -999999
        terminal = false

        directives.each do |dir|
          node = group_scan(node, dir.__start, dir.__end) if dir.__start
          next if dir.priority < term_priority
          dir.compile(node)

          if dir.terminal
            terminal = true
            term_priority = dir.priority
          end
        end

        terminal
      end

      def group_scan(node, _start, _end)
        [].tap do |nodes|
          if _start && node && node.has_attribute?(_start)
            depth = 0

            loop do
              if node.node_type == 1
                if node.has_attribute?(_start)
                  depth += 1
                elsif node.has_attribute?(_end)
                  depth -= 1
                end
              end

              nodes << node
              node = node.next

              break unless depth > 0
            end
          else
            nodes << node
          end
        end
      end

      def directive_normalize(name)
        name.downcase.gsub(/(x[\:\-_]|data[\:\-_])/i, '').gsub('-', '_')
      end
    end
  end
end


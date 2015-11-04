require 'spec_helper'

describe "_compile" do
  def makeInjectorWithDirectives(args, &block)
    Op::Injector.new(['op', ->(_compile_provider) {
      _compile_provider.directive(args, block)
    }])
  end

  it 'allows creating directives' do
    myModule = $opular.module('myModule', [])
    myModule.directive('testing', -> {})
    injector = Op::Injector.new(['op', 'myModule'])
    expect(injector.has?('testing_directive')).to eq(true)
  end

  it('allows creating many directives with the same name') do
    myModule = $opular.module('myModule', [])
    myModule.directive('testing', -> { Op::Directive::Base.new.tap {|d| d.name = 'one'} })
    myModule.directive('testing', -> { Op::Directive::Base.new.tap {|d| d.name = 'two'} })
    injector = Op::Injector.new(['op', 'myModule'])

    result = injector.get('testing_directive')
    expect(result.length).to eq(2)
    expect(result[0].name).to eq('one')
    expect(result[1].name).to eq('two')
  end

  it('allows creating directives with object notation') do
    myModule = $opular.module('myModule', [])
    myModule.directive(
      a: Op::Directive::Base,
      b: Op::Directive::Base,
      c: Op::Directive::Base
    )
    injector = Op::Injector.new(['op', 'myModule'])

    expect(injector.has?('a_directive')).to eq(true)
    expect(injector.has?('b_directive')).to eq(true)
    expect(injector.has?('c_directive')).to eq(true)
  end


  it('compiles element directives from a single element') do
    injector = makeInjectorWithDirectives('my_directive') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict
          'EACM'
        end
        def obj.compile(element)
          element.data('hasCompiled', true)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.new('my-directive')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    })
  end

  it('compiles element directives found from several elements') do
    $idx = 0
    injector = makeInjectorWithDirectives('my_directive') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict; 'EACM'; end
        def obj.compile(element)
          element.data('idx', $idx += 1)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<my-directive></my-directive><my-directive></my-directive>')
      _compile.run(el)
      expect(el.at(0).data('idx')).to eq(1)
      expect(el.at(1).data('idx')).to eq(2)
    })
  end

  it('compiles element directives from child elements') do
    $idx = 0
    injector = makeInjectorWithDirectives('my_directive') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict; 'EACM'; end
        def obj.compile(element)
          element.data('dir', $idx += 1)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div><my-directive></my-directive></div>')
      _compile.run(el)
      expect(el.data('dir')).to be_nil
      expect(el.find('> my-directive').data('dir')).to eq(1)
    })
  end


  it('compiles nested directives') do
    $idx = 0
    injector = makeInjectorWithDirectives('my_dir') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict; 'EACM'; end
        def obj.compile(element)
          element.data('dir', $idx += 1)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<my-dir><my-dir><my-dir/></my-dir></my-dir>')
      _compile.run(el)
      expect(el.data('dir')).to eq(1)
      expect(el.find('> my-dir').data('dir')).to eq(2)
      expect(el.find('> my-dir > my-dir').data('dir')).to eq(3)
    })
  end

  ['x', 'data'].each do |prefix|
    [':', '-', '_'].each do |delim|
      it("compiles element directives with #{prefix}#{delim} prefix") do
        injector = makeInjectorWithDirectives('my_directive') do
          Op::Directive::Base.new.tap do |obj|
            def obj.restrict
              'EACM'
            end
            def obj.compile(element)
              element.data('hasCompiled', true)
            end
          end
        end

        injector.invoke(->(_compile) {
          el = Element.parse("<#{prefix}#{delim}my-directive></#{prefix}#{delim}my-directive>")
          _compile.run(el)
          expect(el.data('hasCompiled')).to eq(true)
        })
      end
    end
  end

  it('compiles attribute directives') do
    injector = makeInjectorWithDirectives('my_directive') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict
          'EACM'
        end
        def obj.compile(element)
          element.data('hasCompiled', true)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div my-directive></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    })
  end

  it('compiles attribute directives with prefixes') do
    injector = makeInjectorWithDirectives('my_directive') do
      Op::Directive::Base.new.tap do |obj|
        def obj.restrict
          'EACM'
        end
        def obj.compile(element)
          element.data('hasCompiled', true)
        end
      end
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div x:my-directive></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    })
  end

  it('compiles several attribute directives in an element') do
    injector = makeInjectorWithDirectives(
      my_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.restrict
            'EACM'
          end
          def obj.compile(element)
            element.data('hasCompiled', true)
          end
        end
      },
      my_second_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.restrict
            'EACM'
          end
          def obj.compile(element)
            element.data('secondCompiled', true)
          end
        end
      }
    )
    injector.invoke(->(_compile) {
      el = Element.parse('<div my-directive my-second-directive></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
      expect(el.data('secondCompiled')).to eq(true)
    })
  end

  it('compiles both element and attributes directives in an element') do
    injector = makeInjectorWithDirectives({
      my_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.restrict
            'EACM'
          end
          def obj.compile(element)
            element.data('hasCompiled', true)
          end
        end
      },
      my_second_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.restrict
            'EACM'
          end
          def obj.compile(element)
            element.data('secondCompiled', true)
          end
        end
      }
    })
    injector.invoke(->(_compile) {
      el = Element.parse('<my-directive my-second-directive></my-directive>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
      expect(el.data('secondCompiled')).to eq(true)
    })
  end

=begin
  it('compiles attribute directives with ng-attr prefix') do
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        restrict: 'EACM',
        compile: function(element) {
          element.data('hasCompiled', true)
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div ng-attr-my-directive></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    end
  end

  it('compiles attribute directives with data:ng-attr prefix') do
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        restrict: 'EACM',
        compile: function(element) {
          element.data('hasCompiled', true)
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div data:ng-attr-my-directive></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    end
  end

  it('compiles class directives') do
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        restrict: 'EACM',
        compile: function(element) {
          element.data('hasCompiled', true)
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div class="my-directive"></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    end
  end

  it('compiles several class directives in an element') do
    injector = makeInjectorWithDirectives({
      my_directive: -> {
        return {
          restrict: 'EACM',
          compile: function(element) {
            element.data('hasCompiled', true)
          }
        }
      },
      mySecond_directive: -> {
        return {
          restrict: 'EACM',
          compile: function(element) {
            element.data('secondCompiled', true)
          }
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div class="my-directive my-second-directive unrelated-class"></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
      expect(el.data('secondCompiled')).to eq(true)
    end
  end

  it('compiles class directives with prefixes') do
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        restrict: 'EACM',
        compile: function(element) {
          element.data('hasCompiled', true)
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div class="x-my-directive"></div>')
      _compile.run(el)
      expect(el.data('hasCompiled')).to eq(true)
    end
  end

  it('compiles comment directives') do
    hasCompiled
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        restrict: 'EACM',
        compile: function(element) {
          hasCompiled = true
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<!-- directive: my-directive -->')
      _compile.run(el)
      expect(hasCompiled).to eq(true)
    end
  end

  _.forEach({
    E:    {element: true,  attribute: false, class: false, comment: false},
    A:    {element: false, attribute: true,  class: false, comment: false},
    C:    {element: false, attribute: false, class: true,  comment: false},
    M:    {element: false, attribute: false, class: false, comment: true},
    EA:   {element: true,  attribute: true,  class: false, comment: false},
    AC:   {element: false, attribute: true,  class: true,  comment: false},
    EAM:  {element: true,  attribute: true,  class: false, comment: true},
    EACM: {element: true,  attribute: true,  class: true,  comment: true},
  }, function(expected, restrict) {

    describe('restricted to '+restrict) do

      _.forEach({
        element:   '<my-directive></my-directive>',
        attribute: '<div my-directive></div>',
        class:     '<div class="my-directive"></div>',
        comment:   '<!-- directive: my-directive -->'
      }, function(dom, type) {

        it((expected[type] ? 'matches' : 'does not match') + ' on '+type) do
          hasCompiled = false
          injector = makeInjectorWithDirectives('my_directive') do
            return {
              restrict: restrict,
              compile: function(element) {
                hasCompiled = true
              }
            }
          end
          injector.invoke(->(_compile) {
            el = $(dom)
            _compile.run(el)
            expect(hasCompiled).to eq(expected[type])
          end
        end

      end

    end

  end

  it('applies to attributes when no restrict given') do
    hasCompiled = false
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        compile: function(element) {
          hasCompiled = true
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div my-directive></div>')
      _compile.run(el)
      expect(hasCompiled).to eq(true)
    end
  end

  it('applies to elements when no restrict given') do
    hasCompiled = false
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        compile: function(element) {
          hasCompiled = true
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<my-directive></my-directive>')
      _compile.run(el)
      expect(hasCompiled).to eq(true)
    end
  end

  it('does not apply to classes when no restrict given') do
    hasCompiled = false
    injector = makeInjectorWithDirectives('my_directive') do
      return {
        compile: function(element) {
          hasCompiled = true
        }
      }
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div class="my-directive"></div>')
      _compile.run(el)
      expect(hasCompiled).to eq(false)
    end
  end
=end


  it('applies in priority order') do
    $compilations = []
    injector = makeInjectorWithDirectives({
      lower_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.priority; 1; end
          def obj.compile(element)
            $compilations.push('lower')
          end
        end
      },
      higher_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          def obj.priority; 2; end
          def obj.compile(element)
            $compilations.push('higher')
          end
        end
      }
    })
    injector.invoke(->(_compile) {
      el = Element.parse('<div lower-directive higher-directive></div>')
      _compile.run(el)
      expect($compilations).to eq(['higher', 'lower'])
    })
  end

  it('applies in name order when priorities are the same') do
    $compilations = []
    injector = makeInjectorWithDirectives({
      first_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          obj.name = 'first'
          def obj.priority; 1000; end
          def obj.compile(element)
            $compilations.push('first')
          end
        end
      },
      second_directive: -> {
        Op::Directive::Base.new.tap do |obj|
          obj.name = 'second'
          def obj.priority; 1000; end
          def obj.compile(element)
            $compilations.push('second')
          end
        end
      }
    })
    injector.invoke(->(_compile) {
      el = Element.parse('<div second-directive first-directive></div>')
      _compile.run(el)
      expect($compilations).to eq(['first', 'second'])
    })
  end

  it('applies in registration order when names are the same') do
    $compilations = []
    myModule = $opular.module('myModule', [])
    myModule.directive('a_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 1; end
        def obj.compile(element)
          $compilations.push('first')
        end
      end
    })
    myModule.directive('a_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 1; end
        def obj.compile(element)
          $compilations.push('second')
        end
      end
    })
    injector = Op::Injector.new(['op', 'myModule'])
    injector.invoke(->(_compile) {
      el = Element.parse('<div a-directive></div>')
      _compile.run(el)
      expect($compilations).to eq(['first', 'second'])
    })
  end

  it('stops compiling at a terminal directive') do
    $compilations = []
    myModule = $opular.module('myModule', [])
    myModule.directive('first_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 1; end
        def obj.terminal; true; end
        def obj.compile(element)
          $compilations.push('first')
        end
      end
    })
    myModule.directive('second_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 0; end
        def obj.compile(element)
          $compilations.push('second')
        end
      end
    })

    Op::Injector.new(['op', 'myModule']).invoke(->(_compile) {
      el = Element.parse('<div first-directive second-directive></div>')
      _compile.run(el)
      expect($compilations).to eq(['first'])
    })
  end

  it('still compiles directives with same priority after terminal') do
    $compilations = []
    myModule = $opular.module('myModule', [])
    myModule.directive('first_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 1; end
        def obj.terminal; true; end
        def obj.compile(element)
          $compilations.push('first')
        end
      end
    })
    myModule.directive('second_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.priority; 1; end
        def obj.compile(element)
          $compilations.push('second')
        end
      end
    })
    injector = Op::Injector.new(['op', 'myModule'])
    injector.invoke(->(_compile) {
      el = Element.parse('<div first-directive second-directive></div>')
      _compile.run(el)
      expect($compilations).to eq(['first', 'second'])
    })
  end

  it('stops child compilation after a terminal directive') do
    $compilations = []
    myModule = $opular.module('myModule', [])
    myModule.directive('parent_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.terminal; true; end
        def obj.compile(element)
          $compilations.push('parent')
        end
      end
    })
    myModule.directive('child_directive', -> {
      Op::Directive::Base.new.tap do |obj|
        def obj.compile(element)
          $compilations.push('child')
        end
      end
    })
    injector = Op::Injector.new(['op', 'myModule'])
    injector.invoke(->(_compile) {
      el = Element.parse('<div parent-directive><div child-directive></div></div>')
      _compile.run(el)
      expect($compilations).to eq(['parent'])
    })
  end


  it('allows applying a directive to multiple elements') do
    $compileEl = false
    injector = makeInjectorWithDirectives('my_dir') do
      Class.new(Op::Directive::Base) do
        def multi_element; true; end
        def compile(element)
          $compileEl = element
        end
      end.new
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div my-dir-start></div><span></span><div my-dir-end></div>')
      _compile.run(el)
      expect($compileEl.length).to eq(3)
    })
  end

=begin

  describe('attributes') do

    function registerAndCompile(dirName, domString, callback) {
      givenAttrs
      injector = makeInjectorWithDirectives(dirName) do
        return {
          restrict: 'EACM',
          compile: function(element, attrs) {
            givenAttrs = attrs
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = $(domString)
        _compile.run(el)
        callback(el, givenAttrs, $rootScope)
      end
    }

    it('passes the element attributes to the compile function') do
      registerAndCompile(
        'my_directive',
        '<my-directive my-attr="1" my-other-attr="two"></my-directive>',
        function(element, attrs) {
          expect(attrs.myAttr).to eq('1')
          expect(attrs.myOtherAttr).to eq('two')
        }
      )
    end

    it('trims attribute values') do
      registerAndCompile(
        'my_directive',
        '<my-directive my-attr=" val "></my-directive>',
        function(element, attrs) {
          expect(attrs.myAttr).to eq('val')
        }
      )
    end

    it('sets the value of boolean attributes to true') do
      registerAndCompile(
        'my_directive',
        '<input my-directive disabled>',
        function(element, attrs) {
          expect(attrs.disabled).to eq(true)
        }
      )
    end

    it('does not set the value of non-standard boolean attributes to true') do
      registerAndCompile(
        'my_directive',
        '<input my-directive whatever>',
        function(element, attrs) {
          expect(attrs.whatever).to eq('')
        }
      )
    end

    it('overrides attributes with ng-attr- versions') do
      registerAndCompile(
        'my_directive',
        '<input my-directive ng-attr-whatever="42" whatever="41">',
        function(element, attrs) {
          expect(attrs.whatever).to eq('42')
        }
      )
    end

    it('allows setting attributes') do
      registerAndCompile(
        'my_directive',
        '<my-directive attr="true"></my-directive>',
        function(element, attrs) {
          attrs.$set('attr', 'false')
          expect(attrs.attr).to eq('false')
        }
      )
    end

    it('sets attributes to DOM') do
      registerAndCompile(
        'my_directive',
        '<my-directive attr="true"></my-directive>',
        function(element, attrs) {
          attrs.$set('attr', 'false')
          expect(element.attr('attr')).to eq('false')
        }
      )
    end

    it('does not set attributes to DOM when flag set to false') do
      registerAndCompile(
        'my_directive',
        '<my-directive attr="true"></my-directive>',
        function(element, attrs) {
          attrs.$set('attr', 'false', false)
          expect(element.attr('attr')).to eq('true')
        }
      )
    end

    it('shares attributes between directives') do
      attrs1, attrs2
      injector = makeInjectorWithDirectives({
        myDir: -> {
          return {
            compile: function(element, attrs) {
              attrs1 = attrs
            }
          }
        },
        myOtherDir: -> {
          return {
            compile: function(element, attrs) {
              attrs2 = attrs
            }
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-dir my-other-dir></div>')
        _compile.run(el)
        expect(attrs1).to eq(attrs2)
      end
    end

    it('sets prop for boolean attributes') do
      registerAndCompile(
        'my_directive',
        '<input my-directive>',
        function(element, attrs) {
          attrs.$set('disabled', true)
          expect(element.prop('disabled')).to eq(true)
        }
      )
    end

    it('sets prop for boolean attributes even when not flushing') do
      registerAndCompile(
        'my_directive',
        '<input my-directive>',
        function(element, attrs) {
          attrs.$set('disabled', true, false)
          expect(element.prop('disabled')).to eq(true)
        }
      )
    end

    it('denormalizes attribute name when explicitly given') do
      registerAndCompile(
        'my_directive',
        '<my-directive some-attribute="42"></my-directive>',
        function(element, attrs) {
          attrs.$set('someAttribute', 43, true, 'some-attribute')
          expect(element.attr('some-attribute')).to eq('43')
        }
      )
    end

    it('denormalizes attribute by snake-casing when no other means available') do
      registerAndCompile(
        'my_directive',
        '<my-directive some-attribute="42"></my-directive>',
        function(element, attrs) {
          attrs.$set('someAttribute', 43)
          expect(element.attr('some-attribute')).to eq('43')
        }
      )
    end

    it('denormalizes attribute by using original attribute name') do
      registerAndCompile(
        'my_directive',
        '<my-directive x-some-attribute="42"></my-directive>',
        function(element, attrs) {
          attrs.$set('someAttribute', 43)
          expect(element.attr('x-some-attribute')).to eq('43')
        }
      )
    end

    it('does not use ng-attr- prefix in denormalized names') do
      registerAndCompile(
        'my_directive',
        '<my-directive ng-attr-some-attribute="42"></my-directive>',
        function(element, attrs) {
          attrs.$set('someAttribute', 43)
          expect(element.attr('some-attribute')).to eq('43')
        }
      )
    end

    it('uses new attribute name after once given') do
      registerAndCompile(
        'my_directive',
        '<my-directive x-some-attribute="42"></my-directive>',
        function(element, attrs) {
          attrs.$set('someAttribute', 43, true, 'some-attribute')
          attrs.$set('someAttribute', 44)

          expect(element.attr('some-attribute')).to eq('44')
          expect(element.attr('x-some-attribute')).to eq('42')
        }
      )
    end

    it('calls observer immediately when attribute is $set') do
      registerAndCompile(
        'my_directive',
        '<my-directive some-attribute="42"></my-directive>',
        function(element, attrs) {

          gotValue
          attrs.$observe('someAttribute', function(value) {
            gotValue = value
          end

          attrs.$set('someAttribute', '43')

          expect(gotValue).to eq('43')
        }
      )
    end

    it('calls observer on next $digest after registration') do
      registerAndCompile(
        'my_directive',
        '<my-directive some-attribute="42"></my-directive>',
        function(element, attrs, $rootScope) {

          gotValue
          attrs.$observe('someAttribute', function(value) {
            gotValue = value
          end

          $rootScope.$digest()

          expect(gotValue).to eq('42')
        }
      )
    end

    it('lets observers be deregistered') do
      registerAndCompile(
        'my_directive',
        '<my-directive some-attribute="42"></my-directive>',
        function(element, attrs) {

          gotValue
          remove = attrs.$observe('someAttribute', function(value) {
            gotValue = value
          end

          attrs.$set('someAttribute', '43')
          expect(gotValue).to eq('43')

          remove()
          attrs.$set('someAttribute', '44')
          expect(gotValue).to eq('43')
        }
      )
    end

    it('adds an attribute from a class directive') do
      registerAndCompile(
        'my_directive',
        '<div class="my-directive"></div>',
        function(element, attrs) {
          expect(attrs.hasOwnProperty('my_directive')).to eq(true)
        }
      )
    end

    it('does not add attribute from class without a directive') do
      registerAndCompile(
        'my_directive',
        '<my-directive class="some-class"></my-directive>',
        function(element, attrs) {
          expect(attrs.hasOwnProperty('someClass')).to eq(false)
        }
      )
    end

    it('supports values for class directive attributes') do
      registerAndCompile(
        'my_directive',
        '<div class="my-directive: my attribute value"></div>',
        function(element, attrs) {
          expect(attrs.my_directive).to eq('my attribute value')
        }
      )
    end

    it('terminates class directive attribute value at semicolon') do
      registerAndCompile(
        'my_directive',
        '<div class="my-directive: my attribute value; some-other-class"></div>',
        function(element, attrs) {
          expect(attrs.my_directive).to eq('my attribute value')
        }
      )
    end

    it('adds an attribute with a value from a comment directive') do
      registerAndCompile(
        'my_directive',
        '<!-- directive: my-directive and the attribute value -->',
        function(element, attrs) {
          expect(attrs.hasOwnProperty('my_directive')).to eq(true)
          expect(attrs.my_directive).to eq('and the attribute value')
        }
      )
    end

    it('allows adding classes') do
      registerAndCompile(
        'my_directive',
        '<my-directive></my-directive>',
        function(element, attrs) {
          attrs.$addClass('some-class')
          expect(element.hasClass('some-class')).to eq(true)
        }
      )
    end

    it('allows removing classes') do
      registerAndCompile(
        'my_directive',
        '<my-directive class="some-class"></my-directive>',
        function(element, attrs) {
          attrs.$removeClass('some-class')
          expect(element.hasClass('some-class')).to eq(false)
        }
      )
    end

    it('allows updating classes') do
      registerAndCompile(
        'my_directive',
        '<my-directive class="one three four"></my-directive>',
        function(element, attrs) {
          attrs.$updateClass('one two three', 'one three four')
          expect(element.hasClass('one')).to eq(true)
          expect(element.hasClass('two')).to eq(true)
          expect(element.hasClass('three')).to eq(true)
          expect(element.hasClass('four')).to eq(false)
        }
      )
    end

  end

  it('returns a public link function from compile') do
    injector = makeInjectorWithDirectives('my_directive') do
      return {compile: _.noop}
    end
    injector.invoke(->(_compile) {
      el = Element.parse('<div my-directive></div>')
      linkFn = _compile.run(el)
      expect(linkFn).to eqDefined()
      expect(_.isFunction(linkFn)).to eq(true)
    end
  end

  describe('linking') do

    it('takes a scope and attaches it to elements') do
      injector = makeInjectorWithDirectives('my_directive') do
        return {compile: _.noop}
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(el.data('$scope')).to eq($rootScope)
      end

    end

    it('calls directive link function with scope') do
      givenScope, givenElement, givenAttrs
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          compile: -> {
            return function link(scope, element, attrs) {
              givenScope = scope
              givenElement = element
              givenAttrs = attrs
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope).to eq($rootScope)
        expect(givenElement[0]).to eq(el[0])
        expect(givenAttrs).to eqDefined()
        expect(givenAttrs.my_directive).to eqDefined()
      end
    end

    it('supports link function in directive definition object') do
      givenScope, givenElement, givenAttrs
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          link: function(scope, element, attrs) {
            givenScope = scope
            givenElement = element
            givenAttrs = attrs
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope).to eq($rootScope)
        expect(givenElement[0]).to eq(el[0])
        expect(givenAttrs).to eqDefined()
        expect(givenAttrs.my_directive).to eqDefined()
      end
    end

    it('links children when parent has no directives') do
      givenElements = []
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          link: function(scope, element, attrs) {
            givenElements.push(element)
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(givenElements.length).to eq(1)
        expect(givenElements[0][0]).to eq(el[0].firstChild)
      end
    end

    it('supports link function objects') do
      linked
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          link: {
            post: function(scope, element, attrs) {
              linked = true
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(linked).to eq(true)
      end
    end

    it('supports prelinking and postlinking') do
      linkings = []
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          link: {
            pre: function(scope, element) {
              linkings.push(['pre', element[0]])
            },
            post: function(scope, element) {
              linkings.push(['post', element[0]])
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive><div my-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(linkings.length).to eq(4)
        expect(linkings[0]).to eq(['pre',  el[0]])
        expect(linkings[1]).to eq(['pre',  el[0].firstChild])
        expect(linkings[2]).to eq(['post', el[0].firstChild])
        expect(linkings[3]).to eq(['post', el[0]])
      end
    end

    it('reverses priority for postlink functions') do
      linkings = []
      injector = makeInjectorWithDirectives({
        first_directive: -> {
          return {
            priority: 2,
            link: {
              pre: function(scope, element) {
                linkings.push('first-pre')
              },
              post: function(scope, element) {
                linkings.push('first-post')
              }
            }
          }
        },
        second_directive: -> {
          return {
            priority: 1,
            link: {
              pre: function(scope, element) {
                linkings.push('second-pre')
              },
              post: function(scope, element) {
                linkings.push('second-post')
              }
            }
          }
        },
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div first-directive second-directive></div>')
        _compile.run(el)($rootScope)
        expect(linkings).to eq([
          'first-pre',
          'second-pre',
          'second-post',
          'first-post'
        ])
      end
    end

    it('stabilizes node list during linking') do
      givenElements = []
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          link: function(scope, element, attrs) {
            givenElements.push(element[0])
            element.after('<div></div>')
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-directive></div><div my-directive></div></div>')
        el1 = el[0].childNodes[0], el2 = el[0].childNodes[1]
        _compile.run(el)($rootScope)
        expect(givenElements.length).to eq(2)
        expect(givenElements[0]).to eq(el1)
        expect(givenElements[1]).to eq(el2)
      end
    end

    it('invokes multi-element directive link functions with whole group') do
      givenElements
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          multiElement: true,
          link: function(scope, element, attrs) {
            givenElements = element
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = $(
          '<div my-directive-start></div>'+
          '<p></p>'+
          '<div my-directive-end></div>'
        )
        _compile.run(el)($rootScope)
        expect(givenElements.length).to eq(3)
      end
    end

    it('makes new scope for element when directive asks for it') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: true,
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.$parent).to eq($rootScope)
      end
    end

    it('gives inherited scope to all directives on element') do
      givenScope
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: true
          }
        },
        myOther_directive: -> {
          return {
            link: function(scope) {
              givenScope = scope
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.$parent).to eq($rootScope)
      end
    end

    it('adds scope class and data for element with new scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: true,
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(el.hasClass('ng-scope')).to eq(true)
        expect(el.data('$scope')).to eq(givenScope)
      end
    end

    it('creates an isolate scope when requested') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {},
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.$parent).to eq($rootScope)
        expect(Object.getPrototypeOf(givenScope)).not.to eq($rootScope)
      end
    end

    it('does not share isolate scope with other directives on the element') do
      givenScope
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {}
          }
        },
        myOther_directive: -> {
          return {
            link: function(scope) {
              givenScope = scope
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(givenScope).to eq($rootScope)
      end
    end

    it('does not use isolate scope on child elements') do
      givenScope
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {}
          }
        },
        myOther_directive: -> {
          return {
            link: function(scope) {
              givenScope = scope
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive><div my-other-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(givenScope).to eq($rootScope)
      end
    end

    it('does not allow two isolate scope directives on an element') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {}
          }
        },
        myOther_directive: -> {
          return {
            scope: {}
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        expect(-> {
          _compile.run(el)
        end.toThrow()
      end
    end

    it('does not allow both isolate and inherited scopes on an element') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {}
          }
        },
        myOther_directive: -> {
          return {
            scope: true
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        expect(-> {
          _compile.run(el)
        end.toThrow()
      end
    end

    it('adds isolate scope class and data for element with isolated scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {},
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(el.hasClass('ng-isolate-scope')).to eq(true)
        expect(el.hasClass('ng-scope')).to eq(false)
        expect(el.data('$isolateScope')).to eq(givenScope)
      end
    end

    it('allows observing attribute to the isolate scope') do
      givenScope, givenAttrs
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            anAttr: '@'
          },
          link: function(scope, element, attrs) {
            givenScope = scope
            givenAttrs = attrs
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)

        givenAttrs.$set('anAttr', '42')
        expect(givenScope.anAttr).to eq('42')
      end
    end

    it('sets initial value of observed attr to the isolate scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            anAttr: '@'
          },
          link: function(scope, element, attrs) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive an-attr="42"></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.anAttr).to eq('42')
      end
    end

    it('allows aliasing observed attribute') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            aScopeAttr: '@anAttr'
          },
          link: function(scope, element, attrs) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive an-attr="42"></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.aScopeAttr).to eq('42')
      end
    end

    it('allows binding expression to isolate scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            anAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive an-attr="42"></div>')
        _compile.run(el)($rootScope)

        expect(givenScope.anAttr).to eq(42)
      end
    end

    it('allows aliasing expression attribute on isolate scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '=theAttr'
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive the-attr="42"></div>')
        _compile.run(el)($rootScope)

        expect(givenScope.myAttr).to eq(42)
      end
    end

    it('evaluates isolate scope expression on parent scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        $rootScope.parentAttr = 41
        el = Element.parse('<div my-directive my-attr="parentAttr + 1"></div>')
        _compile.run(el)($rootScope)

        expect(givenScope.myAttr).to eq(42)
      end
    end

    it('watches isolated scope expressions') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="parentAttr + 1"></div>')
        _compile.run(el)($rootScope)

        $rootScope.parentAttr = 41
        $rootScope.$digest()
        expect(givenScope.myAttr).to eq(42)
      end
    end

    it('allows assigning to isolated scope expressions') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="parentAttr"></div>')
        _compile.run(el)($rootScope)

        givenScope.myAttr = 42
        $rootScope.$digest()
        expect($rootScope.parentAttr).to eq(42)
      end
    end

    it('gives parent change precedence when both parent and child change') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="parentAttr"></div>')
        _compile.run(el)($rootScope)

        $rootScope.parentAttr = 42
        givenScope.myAttr = 43
        $rootScope.$digest()
        expect($rootScope.parentAttr).to eq(42)
        expect(givenScope.myAttr).to eq(42)
      end
    end

    it('throws when binding array-returning function to isolate scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '='
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        $rootScope.parentFunction = -> {
          return [1, 2, 3]
        }
        el = Element.parse('<div my-directive my-attr="parentFunction()"></div>')
        _compile.run(el)($rootScope)
        expect(-> {
          $rootScope.$digest()
        end.toThrow()
      end
    end

    it('can watch isolated scope expressions as collections') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myAttr: '=*'
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        $rootScope.parentFunction = -> {
          return [1, 2, 3]
        }
        el = Element.parse('<div my-directive my-attr="parentFunction()"></div>')
        _compile.run(el)($rootScope)
        $rootScope.$digest()
        expect(givenScope.myAttr).to eq([1, 2, 3])
      end
    end

    it('allows binding an invokable expression on the parent scope') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myExpr: '&'
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        $rootScope.parentFunction = -> {
          return 42
        }
        el = Element.parse('<div my-directive my-expr="parentFunction() + 1"></div>')
        _compile.run(el)($rootScope)
        expect(givenScope.myExpr()).to eq(43)
      end
    end

    it('allows passing arguments to parent scope expression') do
      givenScope
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          scope: {
            myExpr: '&'
          },
          link: function(scope) {
            givenScope = scope
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        gotArg
        $rootScope.parentFunction = function(arg) {
          gotArg = arg
        }
        el = Element.parse('<div my-directive my-expr="parentFunction(argFromChild)"></div>')
        _compile.run(el)($rootScope)
        givenScope.myExpr({argFromChild: 42})
        expect(gotArg).to eq(42)
      end
    end

  end

  describe('controllers') do

    it('can be attached to directives as functions') do
      controllerInvoked
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          controller: function MyController() {
            controllerInvoked = true
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(controllerInvoked).to eq(true)
      end
    end

    it('can be attached to directives as string references') do
      controllerInvoked
      function MyController() {
        controllerInvoked = true
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {controller: 'MyController'}
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(controllerInvoked).to eq(true)
      end
    end

    it('can be applied in the same element independent of each other') do
      controllerInvoked
      otherControllerInvoked
      function MyController() {
        controllerInvoked = true
      }
      function MyOtherController() {
        otherControllerInvoked = true
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        $controllerProvider.register('MyOtherController', MyOtherController)
        _compileProvider.directive('my_directive') do
          return {controller: 'MyController'}
        end
        _compileProvider.directive('myOther_directive') do
          return {controller: 'MyOtherController'}
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(controllerInvoked).to eq(true)
        expect(otherControllerInvoked).to eq(true)
      end
    end

    it('can be applied to different directives, as different instances') do
      invocations = 0
      function MyController() {
        invocations++
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {controller: 'MyController'}
        end
        _compileProvider.directive('myOther_directive') do
          return {controller: 'MyController'}
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(invocations).to eq(2)
      end
    end

    it('can be aliased with @ when given in directive attribute') do
      controllerInvoked
      function MyController() {
        controllerInvoked = true
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {controller: '@'}
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive="MyController"></div>')
        _compile.run(el)($rootScope)
        expect(controllerInvoked).to eq(true)
      end
    end

    it('gets scope, element, and attrs through DI') do
      gotScope, gotElement, gotAttrs
      function MyController($element, $scope, $attrs) {
        gotElement = $element
        gotScope = $scope
        gotAttrs = $attrs
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {controller: 'MyController'}
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive an-attr="abc"></div>')
        _compile.run(el)($rootScope)
        expect(gotElement[0]).to eq(el[0])
        expect(gotScope).to eq($rootScope)
        expect(gotAttrs).to eqDefined()
        expect(gotAttrs.anAttr).to eq('abc')
      end
    end

    it('can be attached on the scope') do
      function MyController() { }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {
            controller: 'MyController',
            controllerAs: 'myCtrl'
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect($rootScope.myCtrl).to eqDefined()
        expect($rootScope.myCtrl instanceof MyController).to eq(true)
      end
    end

    it('gets isolate scope as injected $scope') do
      gotScope
      function MyController($scope) {
        gotScope = $scope
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: 'MyController'
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotScope).not.to eq($rootScope)
      end
    end

    it('has isolate scope bindings available during construction') do
      gotMyAttr
      function MyController($scope) {
        gotMyAttr = $scope.myAttr
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {
            scope: {
              myAttr: '@my_directive'
            },
            controller: 'MyController'
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive="abc"></div>')
        _compile.run(el)($rootScope)
        expect(gotMyAttr).to eq('abc')
      end
    end

    it('can bind isolate scope bindings directly to self') do
      gotMyAttr
      function MyController() {
        gotMyAttr = this.myAttr
      }
      injector = Op::Injector.new(['op', function($controllerProvider, _compileProvider) {
        $controllerProvider.register('MyController', MyController)
        _compileProvider.directive('my_directive') do
          return {
            scope: {
              myAttr: '@my_directive'
            },
            controller: 'MyController',
            bindToController: true
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive="abc"></div>')
        _compile.run(el)($rootScope)
        expect(gotMyAttr).to eq('abc')
      end
    end

    it('can return a semi-constructed controller when using array injection', function() {
      injector = Op::Injector.new(['op', function($provide) {
        $provide.constant('aDep', 42)
      }])
      $controller = injector.get('$controller')

      function MyController(aDep) {
        this.aDep = aDep
        this.constructed = true
      }

      controller = $controller(['aDep', MyController], null, true)
      expect(controller.constructed).to eqUndefined()
      actualController = controller()
      expect(actualController.constructed).to eqDefined()
      expect(actualController.aDep).to eq(42)
    end

    it('can be required from a sibling directive') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: 'my_directive',
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('can be required from multiple sibling directives') do
      function MyController() { }
      function MyOtherController() { }
      gotControllers
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: true,
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            scope: true,
            controller: MyOtherController
          }
        end
        _compileProvider.directive('myThird_directive') do
          return {
            require: ['my_directive', 'myOther_directive'],
            link: function(scope, element, attrs, controllers) {
              gotControllers = controllers
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive my-third-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotControllers).to eqDefined()
        expect(gotControllers.length).to eq(2)
        expect(gotControllers[0] instanceof MyController).to eq(true)
        expect(gotControllers[1] instanceof MyOtherController).to eq(true)
      end
    end

    it('is passed to link functions if there is no require') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController,
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('is passed through grouped link wrapper') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            multiElement: true,
            scope: {},
            controller: MyController,
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive-start></div><div my-directive-end></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('can be required from a parent directive') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: '^my_directive',
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive><div my-other-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('also finds from sibling directive when requiring with parent prefix') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: '^my_directive',
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('can be required from a parent directive with ^^') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: '^^my_directive',
            link: function(scope, element, attrs, myController) {
              gotMyController = myController
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive><div my-other-directive></div></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end

    it('does not find from sibling directive when requiring with ^^') do
      function MyController() { }
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: '^^my_directive',
            link: function(scope, element, attrs, myController) {
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        expect(-> {
          _compile.run(el)($rootScope)
        end.toThrow()
      end
    end

    it('does not throw on required missing controller when optional') do
      gotCtrl
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            require: '?noSuch_directive',
            link: function(scope, element, attrs, ctrl) {
              gotCtrl = ctrl
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotCtrl).to eq(null)
      end
    end

    it('allows optional marker after parent marker') do
      gotCtrl
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            require: '^?noSuch_directive',
            link: function(scope, element, attrs, ctrl) {
              gotCtrl = ctrl
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotCtrl).to eq(null)
      end
    end

    it('allows optional marker before parent marker') do
      function MyController() { }
      gotMyController
      injector = Op::Injector.new(['op', function(_compileProvider) {
        _compileProvider.directive('my_directive') do
          return {
            scope: {},
            controller: MyController
          }
        end
        _compileProvider.directive('myOther_directive') do
          return {
            require: '?^my_directive',
            link: function(scope, element, attrs, ctrl) {
              gotMyController = ctrl
            }
          }
        end
      }])
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)($rootScope)
        expect(gotMyController).to eqDefined()
        expect(gotMyController instanceof MyController).to eq(true)
      end
    end


  end

  describe('template') do

    it('populates an element during compilation') do
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          template: '<div class="from-template"></div>'
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)
        expect(el.find('> .from-template').length).to eq(1)
      end
    end

    it('replaces any existing children') do
      injector = makeInjectorWithDirectives('my_directive') do
        return {
          template: '<div class="from-template"></div>'
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive><div class="existing"></div></div>')
        _compile.run(el)
        expect(el.find('> .existing').length).to eq(0)
      end
    end

    it('compiles template contents also') do
      compileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            template: '<div my-other-directive></div>'
          }
        },
        myOther_directive: -> {
          return {
            compile: compileSpy
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)
        expect(compileSpy).toHaveBeenCalled()
      end
    end

    it('does not allow two directives with templates') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {template: '<div></div>'}
        },
        myOther_directive: -> {
          return {template: '<div></div>'}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        expect(-> {
          _compile.run(el)
        end.toThrow()
      end
    end

    it('supports functions as template values') do
      templateSpy = jasmine.createSpy()
        .and.returnValue('<div class="from-template"></div>')
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            template: templateSpy
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)
        expect(el.find('> .from-template').length).to eq(1)
        expect(templateSpy.calls.first().args[0][0]).to eq(el[0])
        expect(templateSpy.calls.first().args[1].my_directive).to eqDefined()
      end
    end

    it('uses isolate scope for template contents') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {
              isoValue: '=my_directive'
            },
            template: '<div my-other-directive></div>'
          }
        },
        myOther_directive: -> {
          return {link: linkSpy}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive="42"></div>')
        _compile.run(el)($rootScope)
        expect(linkSpy.calls.first().args[0]).not.to eq($rootScope)
        expect(linkSpy.calls.first().args[0].isoValue).to eq(42)
      end
    end


  end


  describe('templateUrl') do

    xhr, requests

    beforeEach(-> {
      xhr = sinon.useFakeXMLHttpRequest()
      requests = []
      xhr.onCreate = function(req) {
        requests.push(req)
      }
    end
    afterEach(-> {
      xhr.restore()
    end

    it('defers remaining directive compilation') do
      otherCompileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        },
        myOther_directive: -> {
          return {compile: otherCompileSpy}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        _compile.run(el)
        expect(otherCompileSpy).not.toHaveBeenCalled()
      end
    end

    it('defers current directive compilation') do
      compileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            templateUrl: '/my_directive.html',
            compile: compileSpy
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive></div>')
        _compile.run(el)
        expect(compileSpy).not.toHaveBeenCalled()
      end
    end

    it('immediately empties out the element') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive>Hello</div>')
        _compile.run(el)
        expect(el.is(':empty')).to eq(true)
      end
    end

    it('fetches the template') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        expect(requests.length).to eq(1)
        expect(requests[0].method).to eq('GET')
        expect(requests[0].url).to eq('/my_directive.html')
      end
    end

    it('populates element with template') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div class="from-template"></div>')

        expect(el.find('> .from-template').length).to eq(1)
      end
    end

    it('resumes current directive compilation after template received') do
      compileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            templateUrl: '/my_directive.html',
            compile: compileSpy
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div class="from-template"></div>')
        expect(compileSpy).toHaveBeenCalled()
      end
    end

    it('resumes remaining directive compilation after template received') do
      otherCompileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        },
        myOther_directive: -> {
          return {compile: otherCompileSpy}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div class="from-template"></div>')
        expect(otherCompileSpy).toHaveBeenCalled()
      end
    end

    it('resumes child compilation after template received') do
      otherCompileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        },
        myOther_directive: -> {
          return {compile: otherCompileSpy}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div my-other-directive></div>')
        expect(otherCompileSpy).toHaveBeenCalled()
      end
    end

    it('supports functions as values') do
      templateUrlSpy = jasmine.createSpy()
        .and.returnValue('/my_directive.html')
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            templateUrl: templateUrlSpy
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        expect(requests[0].url).to eq('/my_directive.html')
        expect(templateUrlSpy.calls.first().args[0][0]).to eq(el[0])
        expect(templateUrlSpy.calls.first().args[1].my_directive).to eqDefined()
      end
    end

    it('does not allow templateUrl directive after template directive') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {template: '<div></div>'}
        },
        myOther_directive: -> {
          return {templateUrl: '/my_other_directive.html'}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-directive my-other-directive></div>')
        expect(-> {
          _compile.run(el)
        end.toThrow()
      end
    end

    it('does not allow template directive after templateUrl directive') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        },
        myOther_directive: -> {
          return {template: '<div></div>'}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')

        _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div class="replacement"></div>')
        expect(el.find('> .replacement').length).to eq(1)
      end
    end

    it('links the directive when public link function is invoked') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            templateUrl: '/my_directive.html',
            link: linkSpy
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        linkFunction = _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div></div>')

        linkFunction($rootScope)
        expect(linkSpy).toHaveBeenCalled()
        expect(linkSpy.calls.first().args[0]).to eq($rootScope)
        expect(linkSpy.calls.first().args[1][0]).to eq(el[0])
        expect(linkSpy.calls.first().args[2].my_directive).to eqDefined()
      end
    end

    it('links child elements when public link function is invoked') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {templateUrl: '/my_directive.html'}
        },
        myOther_directive: -> {
          return {link: linkSpy}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        linkFunction = _compile.run(el)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div my-other-directive></div>')

        linkFunction($rootScope)
        expect(linkSpy).toHaveBeenCalled()
        expect(linkSpy.calls.first().args[0]).to eq($rootScope)
        expect(linkSpy.calls.first().args[1][0]).to eq(el[0].firstChild)
        expect(linkSpy.calls.first().args[2].myOther_directive).to eqDefined()
      end
    end

    it('links when template received if node link function has been invoked') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            templateUrl: '/my_directive.html',
            link: linkSpy
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')

        linkFunction = _compile.run(el)($rootScope); // link first

        $rootScope.$apply()
        requests[0].respond(200, {}, '<div></div>'); // then receive template

        expect(linkSpy).toHaveBeenCalled()
        expect(linkSpy.calls.argsFor(0)[0]).to eq($rootScope)
        expect(linkSpy.calls.argsFor(0)[1][0]).to eq(el[0])
        expect(linkSpy.calls.argsFor(0)[2].my_directive).to eqDefined()
      end
    end

    it('links directives that were compiled earlier') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {link: linkSpy}
        },
        myOther_directive: -> {
          return {templateUrl: '/my_other_directive.html'}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')

        linkFunction = _compile.run(el)
        $rootScope.$apply()

        linkFunction($rootScope)

        requests[0].respond(200, {}, '<div></div>')

        expect(linkSpy).toHaveBeenCalled()
        expect(linkSpy.calls.argsFor(0)[0]).to eq($rootScope)
        expect(linkSpy.calls.argsFor(0)[1][0]).to eq(el[0])
        expect(linkSpy.calls.argsFor(0)[2].my_directive).to eqDefined()
      end
    end

    it('retains isolate scope directives from earlier') do
      linkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {val: '=my_directive'},
            link: linkSpy
          }
        },
        myOther_directive: -> {
          return {templateUrl: '/my_other_directive.html'}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive="42" my-other-directive></div>')

        linkFunction = _compile.run(el)
        $rootScope.$apply()

        linkFunction($rootScope)

        requests[0].respond(200, {}, '<div></div>')

        expect(linkSpy).toHaveBeenCalled()
        expect(linkSpy.calls.first().args[0]).to eqDefined()
        expect(linkSpy.calls.first().args[0]).not.to eq($rootScope)
        expect(linkSpy.calls.first().args[0].val).to eq(42)
      end
    end

    it('sets up controllers for all controller directives') do
      my_directiveControllerInstantiated, myOther_directiveControllerInstantiated
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            controller: function My_directiveController() {
              my_directiveControllerInstantiated = true
            }
          }
        },
        myOther_directive: -> {
          return {
            templateUrl: '/my_other_directive.html',
            controller: function MyOther_directiveController() {
              myOther_directiveControllerInstantiated = true
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-other-directive></div>')

        _compile.run(el)($rootScope)
        $rootScope.$apply()

        requests[0].respond(200, {}, '<div></div>')

        expect(my_directiveControllerInstantiated).to eq(true)
        expect(myOther_directiveControllerInstantiated).to eq(true)
      end
    end

    describe('with transclusion') do

      it('makes transclusion available to link fn when template arrives first') do
        injector = makeInjectorWithDirectives({
          myTranscluder: -> {
            return {
              transclude: true,
              templateUrl: 'my_template.html',
              link: function(scope, element, attrs, ctrl, transclude) {
                element.find('[in-template]').append(transclude())
              }
            }
          }
        end
        injector.invoke(function(_compile, $rootScope) {
          el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

          linkFunction = _compile.run(el)
          $rootScope.$apply()
          requests[0].respond(200, {}, '<div in-template></div>'); // respond first
          linkFunction($rootScope); // then link

          expect(el.find('> [in-template] > [in-transclude]').length).to eq(1)
        end
      end

      it('makes transclusion available to link fn when template arrives after') do
        injector = makeInjectorWithDirectives({
          myTranscluder: -> {
            return {
              transclude: true,
              templateUrl: 'my_template.html',
              link: function(scope, element, attrs, ctrl, transclude) {
                element.find('[in-template]').append(transclude())
              }
            }
          }
        end
        injector.invoke(function(_compile, $rootScope) {
          el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

          linkFunction = _compile.run(el)
          $rootScope.$apply()
          linkFunction($rootScope); // link first
          requests[0].respond(200, {}, '<div in-template></div>'); // then respond

          expect(el.find('> [in-template] > [in-transclude]').length).to eq(1)
        end
      end

      it('is only allowed once') do
        otherCompileSpy = jasmine.createSpy()
        injector = makeInjectorWithDirectives({
          myTranscluder: -> {
            return {
              priority: 1,
              transclude: true,
              templateUrl: 'my_template.html'
            }
          },
          mySecondTranscluder: -> {
            return {
              priority: 0,
              transclude: true,
              compile: otherCompileSpy
            }
          }
        end
        injector.invoke(function(_compile, $rootScope) {
          el = Element.parse('<div my-transcluder my-second-transcluder></div>')

          _compile.run(el)
          $rootScope.$apply()
          requests[0].respond(200, {}, '<div in-template></div>')

          expect(otherCompileSpy).not.toHaveBeenCalled()
        end
      end

    end

  end

  describe('transclude') do

    it('removes the children of the element from the DOM') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {transclude: true}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-transcluder><div>Must go</div></div>')

        _compile.run(el)

        expect(el.is(':empty')).to eq(true)
      end
    end

    it('compiles child elements') do
      insideCompileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {transclude: true}
        },
        insideTranscluder: -> {
          return {compile: insideCompileSpy}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-transcluder><div inside-transcluder></div></div>')

        _compile.run(el)

        expect(insideCompileSpy).toHaveBeenCalled()
      end
    end

    it('makes contents available to link function') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>',
            link: function(scope, element, attrs, ctrl, transclude) {
              element.find('[in-template]').append(transclude())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transcluder></div></div>')

        _compile.run(el)($rootScope)
        expect(el.find('> [in-template] > [in-transcluder]').length).to eq(1)
      end
    end

    it('is only allowed once per element') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {transclude: true}
        },
        mySecondTranscluder: -> {
          return {transclude: true}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div my-transcluder my-second-transcluder></div>')

        expect(-> {
          _compile.run(el)
        end.toThrow()
      end
    end

    it('makes scope available to link functions inside') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              element.append(transclude())
            }
          }
        },
        myInner_directive: -> {
          return {
            link: function(scope, element) {
              element.html(scope.anAttr)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div my-inner-directive></div></div>')

        $rootScope.anAttr = 'Hello from root'
        _compile.run(el)($rootScope)
        expect(el.find('> [my-inner-directive]').html()).to eq('Hello from root')
      end
    end

    it('does not use the inherited scope of the directive') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            scope: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              scope.anAttr = 'Shadowed attribute'
              element.append(transclude())
            }
          }
        },
        myInner_directive: -> {
          return {
            link: function(scope, element) {
              element.html(scope.anAttr)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div my-inner-directive></div></div>')

        $rootScope.anAttr = 'Hello from root'
        _compile.run(el)($rootScope)
        expect(el.find('> [my-inner-directive]').html()).to eq('Hello from root')
      end
    end

    it('contents are destroyed along with transcluding directive') do
      watchSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            scope: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              element.append(transclude())
              scope.$on('destroyNow') do
                scope.$destroy()
              end
            }
          }
        },
        myInner_directive: -> {
          return {
            link: function(scope) {
              scope.$watch(watchSpy)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div my-inner-directive></div></div>')
        _compile.run(el)($rootScope)

        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(2)

        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(3)

        $rootScope.$broadcast('destroyNow')
        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(3)
      end
    end

    it('allows passing another scope to transclusion function') do
      otherLinkSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            scope: {},
            template: '<div></div>',
            link: function(scope, element, attrs, ctrl, transclude) {
              mySpecialScope = scope.$new(true)
              mySpecialScope.specialAttr = 42
              transclude(mySpecialScope)
            }
          }
        },
        myOther_directive: -> {
          return {link: otherLinkSpy}
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div my-other-directive></div></div>')

        _compile.run(el)($rootScope)

        transcludedScope = otherLinkSpy.calls.first().args[0]
        expect(transcludedScope.specialAttr).to eq(42)
      end
    end

    it('makes contents available to child elements') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>'
          }
        },
        inTemplate: -> {
          return {
            link: function(scope, element, attrs, ctrl, transcludeFn) {
              element.append(transcludeFn())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> [in-template] > [in-transclude]').length).to eq(1)
      end
    end

    it('makes contents available to indirect child elements') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div><div in-template></div></div>'
          }
        },
        inTemplate: -> {
          return {
            link: function(scope, element, attrs, ctrl, transcludeFn) {
              element.append(transcludeFn())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> div > [in-template] > [in-transclude]').length).to eq(1)
      end
    end

    it('supports passing transclusion function to public link function') do
      injector = makeInjectorWithDirectives({
        myTranscluder: ->(_compile) {
          return {
            transclude: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              customTemplate = Element.parse('<div in-custom-template></div>')
              element.append(customTemplate)
              _compile.run(customTemplate)(scope, undefined, {
                parentBoundTranscludeFn: transclude
              end
            }
          }
        },
        inCustomTemplate: -> {
          return {
            link: function(scope, element, attrs, ctrl, transclude) {
              element.append(transclude())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> [in-custom-template] > [in-transclude]').length).to eq(1)
      end
    end

    it('destroys scope passed through public link fn at the right time') do
      watchSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: ->(_compile) {
          return {
            transclude: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              customTemplate = Element.parse('<div in-custom-template></div>')
              element.append(customTemplate)
              _compile.run(customTemplate)(scope, undefined, {
                parentBoundTranscludeFn: transclude
              end
            }
          }
        },
        inCustomTemplate: -> {
          return {
            scope: true,
            link: function(scope, element, attrs, ctrl, transclude) {
              element.append(transclude())
              scope.$on('destroyNow') do
                scope.$destroy()
              end
            }
          }
        },
        inTransclude: -> {
          return {
            link: function(scope) {
              scope.$watch(watchSpy)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

        _compile.run(el)($rootScope)

        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(2)

        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(3)

        $rootScope.$broadcast('destroyNow')
        $rootScope.$apply()
        expect(watchSpy.calls.count()).to eq(3)
      end
    end

    it('makes contents available to controller') do
      gotTransclusionFunction
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>',
            controller: function($element, $transclude) {
              $element.find('[in-template]').append($transclude())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')
        _compile.run(el)($rootScope)

        expect(el.find('> [in-template] > [in-transclude]').length).to eq(1)
      end
    end

    it('can be used with multi-element directives') do
      injector = makeInjectorWithDirectives({
        myTranscluder: ->(_compile) {
          return {
            transclude: true,
            multiElement: true,
            template: '<div in-template></div>',
            link: function(scope, element, attrs, ctrl, transclude) {
              element.find('[in-template]').append(transclude())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-transcluder-start><div in-transclude></div></div><div my-transcluder-end></div></div>')
        _compile.run(el)($rootScope)
        expect(el.find('[my-transcluder-start] [in-template] [in-transclude]').length).to eq(1)
      end
    end

    it('works with thing 1') do
      injector = makeInjectorWithDirectives({
        inner: -> {
          return {
            transclude: true,
            template: '<u ng-transclude></u>'
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<inner>y</inner>')
        _compile.run(el)($rootScope)
        expect(el.html()).to eq('<u ng-transclude="">y</u>')
      end
    end

    it('works with nested transcludes') do
      injector = makeInjectorWithDirectives({
        inner: -> {
          return {
            transclude: true,
            template: '<u ng-transclude></u>'
          }
        },
        workaround: -> {
          return {
            transclude: true,
            template: '<a href="#"><inner><foo ng-transclude></foo></inner></a>'
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<workaround>y</workaround>')
        _compile.run(el)($rootScope)
        expect(el.html()).to eq('<a href="#"><inner><u ng-transclude=""><foo ng-transclude="">y</foo></u></inner></a>')
      end
    end

    it('works with nested transcludes without wrap') do
      injector = makeInjectorWithDirectives({
        inner: -> {
          return {
            transclude: true,
            template: '<u my-trans></u>'
          }
        },
        workaround: -> {
          return {
            transclude: true,
            template: '<a href="#"><inner><foo my-trans></foo></inner></a>'
          }
        },
        outer: -> {
          return {
            transclude: true,
            template: '<a href="#"><inner my-trans></inner></a>'
          }
        },
        myTrans: -> {
          return {
            link: function(scope, element, attrs, ctrl, trans) {
              trcluded = trans()
              //console.log('tr', trcluded.length)
              element.empty().append(trcluded)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<inner>y</inner>')
        _compile.run(el)($rootScope)
        expect(el.html()).to eq('<u my-trans="">y</u>')

        el = Element.parse('<workaround>y</workaround>')
        _compile.run(el)($rootScope)
        expect(el.html()).to eq('<a href="#"><inner><u my-trans=""><foo my-trans="">y</foo></u></inner></a>')

        el = Element.parse('<outer>y</outer>')
        _compile.run(el)($rootScope)
        expect(el.html()).to eq('<a href="#"><inner my-trans=""><u my-trans="">y</u></inner></a>')
      end
    end

  end

  describe('clone attach function') do

    it('can be passed to public link fn') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>Hello</div>')
        myScope = $rootScope.$new()
        gotEl, gotScope

        _compile.run(el)(myScope, function(el, scope) {
          gotEl = el
          gotScope = scope
        end

        expect(gotEl[0].isEqualNode(el[0])).to eq(true)
        expect(gotScope).to eq(myScope)
      end
    end

    it('causes compiled elements to be cloned') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>Hello</div>')
        myScope = $rootScope.$new()
        gotClonedEl

        _compile.run(el)(myScope, function(clonedEl) {
          gotClonedEl = clonedEl
        end

        expect(gotClonedEl[0].isEqualNode(el[0])).to eq(true)
        expect(gotClonedEl[0]).not.to eq(el[0])
      end
    end

    it('causes cloned DOM to be linked') do
      gotCompileEl, gotLinkEl
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            compile: function(compileEl) {
              gotCompileEl = compileEl
              return function link(scope, linkEl) {
                gotLinkEl = linkEl
              }
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive></div>')
        myScope = $rootScope.$new()
        gotClonedEl

        _compile.run(el)(myScope) do})

        expect(gotCompileEl[0]).not.to eq(gotLinkEl[0])
      end
    end

    it('allows connecting transcluded content') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>',
            link: function(scope, element, attrs, ctrl, transcludeFn) {
              myScope = scope.$new()
              transcludeFn(myScope, function(transclNode) {
                element.find('[in-template]').append(transclNode)
              end
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclude></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> [in-template] > [in-transclude]').length).to eq(1)
      end
    end

    it('can be used with default transclusion scope') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>',
            link: function(scope, element, attrs, ctrl, transcludeFn) {
              transcludeFn(function(transclNode) {
                element.find('[in-template]').append(transclNode)
              end
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div in-transclusion></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> [in-template] > [in-transclusion]').length).to eq(1)
      end
    end

    it('allows passing data to transclusion') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: true,
            template: '<div in-template></div>',
            link: function(scope, element, attrs, ctrl, transcludeFn) {
              transcludeFn(function(transclNode, transclScope) {
                transclScope.dataFromTranscluder = 'Hello from transcluder'
                element.find('[in-template]').append(transclNode)
              end
            }
          }
        },
        myOther_directive: -> {
          return {
            link: function(scope, element) {
              element.html(scope.dataFromTranscluder)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-transcluder><div my-other-directive></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('> [in-template] > [my-other-directive]').html()).to eq('Hello from transcluder')
      end
    end

  end

  describe('element transclusion') do

    it('removes the element from the DOM') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: 'element'
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder></div></div>')

        _compile.run(el)

        expect(el.is(':empty')).to eq(true)
      end
    end

    it('replaces the element with a comment') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: 'element'
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder></div></div>')

        _compile.run(el)

        expect(el.html()).to eq('<!-- myTranscluder:  -->')
      end
    end

    it('includes directive attribute value in comment') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {transclude: 'element'}
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder=42></div></div>')

        _compile.run(el)

        expect(el.html()).to eq('<!-- myTranscluder: 42 -->')
      end
    end

    it('calls directive compile and link with comment') do
      gotCompiledEl, gotLinkedEl
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: 'element',
            compile: function(compiledEl) {
              gotCompiledEl = compiledEl
              return function(scope, linkedEl) {
                gotLinkedEl = linkedEl
              }
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-transcluder></div></div>')

        _compile.run(el)($rootScope)

        expect(gotCompiledEl[0].nodeType).to eq(Node.COMMENT_NODE)
        expect(gotLinkedEl[0].nodeType).to eq(Node.COMMENT_NODE)
      end
    end

    it('calls lower priority compile with original') do
      gotCompiledEl, gotLinkedEl
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            priority: 2,
            transclude: 'element'
          }
        },
        myOther_directive: -> {
          return {
            priority: 1,
            compile: function(compiledEl) {
              gotCompiledEl = compiledEl
            }
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder my-other-directive></div></div>')

        _compile.run(el)

        expect(gotCompiledEl[0].nodeType).to eq(Node.ELEMENT_NODE)
      end
    end

    it('calls compile on child element directives') do
      compileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: 'element'
          }
        },
        myOther_directive: -> {
          return {
            compile: compileSpy
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder><div my-other-directive></div></div></div>')

        _compile.run(el)

        expect(compileSpy).toHaveBeenCalled()
      end
    end

    it('compiles original element contents once') do
      compileSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {transclude: 'element'}
        },
        myOther_directive: -> {
          return {
            compile: compileSpy
          }
        }
      end
      injector.invoke(->(_compile) {
        el = Element.parse('<div><div my-transcluder><div my-other-directive></div></div></div>')

        _compile.run(el)

        expect(compileSpy.calls.count()).to eq(1)
      end
    end

    it('makes original element available for transclusion') do
      injector = makeInjectorWithDirectives({
        myDouble: -> {
          return {
            transclude: 'element',
            link: function(scope, el, attrs, ctrl, transclude) {
              transclude(function(clone) {
                el.after(clone)
              end
              transclude(function(clone) {
                el.after(clone)
              end
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-double>Hello</div>')

        _compile.run(el)($rootScope)

        expect(el.find('[my-double]').length).to eq(2)
      end
    end

    it('sets directive attributes element to comment') do
      injector = makeInjectorWithDirectives({
        myTranscluder: -> {
          return {
            transclude: 'element',
            link: function(scope, element, attrs, ctrl, transclude) {
              attrs.$set('testing', '42')
              element.after(transclude())
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-transcluder></div></div>')

        _compile.run(el)($rootScope)

        expect(el.find('[my-transcluder]').attr('testing')).to eqUndefined()
      end
    end

    it('supports requiring controllers') do
      MyController = -> { }
      gotCtrl
      injector = makeInjectorWithDirectives({
        myCtrl_directive: -> {
          return {controller: MyController}
        },
        myTranscluder: -> {
          return {
            transclude: 'element',
            link: function(scope, el, attrs, ctrl, transclude) {
              el.after(transclude())
            }
          }
        },
        myOther_directive: -> {
          return {
            require: '^myCtrl_directive',
            link: function(scope, el, attrs, ctrl, transclude) {
              gotCtrl = ctrl
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div><div my-ctrl-directive my-transcluder><div my-other-directive>Hello</div></div>')

        _compile.run(el)($rootScope)

        expect(gotCtrl).to eqDefined()
        expect(gotCtrl instanceof MyController).to eq(true)
      end
    end

  end

  describe('interpolation') do

    it('is done for text nodes') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>My expression: {{myExpr}}</div>')
        _compile.run(el)($rootScope)

        $rootScope.$apply()
        expect(el.html()).to eq('My expression: ')

        $rootScope.myExpr = 'Hello'
        $rootScope.$apply()
        expect(el.html()).to eq('My expression: Hello')
      end
    end

    it('adds binding class to text node parents') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>My expression: {{myExpr}}</div>')
        _compile.run(el)($rootScope)

        expect(el.hasClass('ng-binding')).to eq(true)
      end
    end

    it('adds binding data to text node parents') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>{{myExpr}} and {{myOtherExpr}}</div>')
        _compile.run(el)($rootScope)

        expect(el.data('$binding')).to eq(['myExpr', 'myOtherExpr'])
      end
    end

    it('adds binding data to parent from multiple text nodes') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div>{{myExpr}} <span>and</span> {{myOtherExpr}}</div>')
        _compile.run(el)($rootScope)

        expect(el.data('$binding')).to eq(['myExpr', 'myOtherExpr'])
      end
    end

    it('is done for attributes') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<img alt="{{myAltText}}">')
        _compile.run(el)($rootScope)

        $rootScope.$apply()
        expect(el.attr('alt')).to eq('')

        $rootScope.myAltText = 'My favourite photo'
        $rootScope.$apply()
        expect(el.attr('alt')).to eq('My favourite photo')
      end
    end

    it('fires observers on attribute expression changes') do
      observerSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            link: function(scope, element, attrs) {
              attrs.$observe('alt', observerSpy)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<img alt="{{myAltText}}" my-directive>')
        _compile.run(el)($rootScope)

        $rootScope.myAltText = 'My favourite photo'
        $rootScope.$apply()
        expect(observerSpy.calls.mostRecent().args[0]).to eq('My favourite photo')
      end
    end

    it('fires observers just once upon registration') do
      observerSpy = jasmine.createSpy()
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            link: function(scope, element, attrs) {
              attrs.$observe('alt', observerSpy)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<img alt="{{myAltText}}" my-directive>')
        _compile.run(el)($rootScope)
        $rootScope.$apply()

        expect(observerSpy.calls.count()).to eq(1)
      end
    end

    it('is done for attributes by the time other directive is linked') do
      gotMyAttr
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            link: function(scope, element, attrs) {
              gotMyAttr = attrs.myAttr
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="{{myExpr}}"></div>')
        $rootScope.myExpr = 'Hello'
        _compile.run(el)($rootScope)

        expect(gotMyAttr).to eq('Hello')
      end
    end

    it('is done for attributes by the time bound to iso scope') do
      gotMyAttr
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            scope: {myAttr: '@'},
            link: function(scope, element, attrs) {
              gotMyAttr = scope.myAttr
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="{{myExpr}}"></div>')
        $rootScope.myExpr = 'Hello'
        _compile.run(el)($rootScope)

        expect(gotMyAttr).to eq('Hello')
      end
    end

    it('is done for attributes so that changes during compile are reflected') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            compile: function(element, attrs) {
              attrs.$set('myAttr', '{{myDifferentExpr}}')
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="{{myExpr}}"></div>')
        $rootScope.myExpr = 'Hello'
        $rootScope.myDifferentExpr = 'Other Hello'
        _compile.run(el)($rootScope)
        $rootScope.$apply()

        expect(el.attr('my-attr')).to eq('Other Hello')
      end
    end

    it('is done for attributes so that removal during compile is reflected') do
      injector = makeInjectorWithDirectives({
        my_directive: -> {
          return {
            compile: function(element, attrs) {
              attrs.$set('myAttr', null)
            }
          }
        }
      end
      injector.invoke(function(_compile, $rootScope) {
        el = Element.parse('<div my-directive my-attr="{{myExpr}}"></div>')
        $rootScope.myExpr = 'Hello'
        _compile.run(el)($rootScope)
        $rootScope.$apply()

        expect(el.attr('my-attr')).to eqFalsy()
      end
    end

    it('cannot be done for event handler attributes') do
      injector = makeInjectorWithDirectives({})
      injector.invoke(function(_compile, $rootScope) {
        $rootScope.myFunction = -> { }
        el = Element.parse('<button onclick="{{myFunction()}}"></button>')
        expect(-> {
          _compile.run(el)($rootScope)
        end.toThrow()
      end
    end

    it('denormalizes directive templates') do
    injector = Op::Injector.new(['op', function($interpolateProvider, _compileProvider) {
      $interpolateProvider.startSymbol('[[').endSymbol(']]')
      _compileProvider.directive('my_directive') do
        return {
          template: 'Value is {{myExpr}}'
        }
      end
    }])
    injector.invoke(function(_compile, $rootScope) {
      el = Element.parse('<div my-directive></div>')
      $rootScope.myExpr = 42
      _compile.run(el)($rootScope)
      $rootScope.$apply()

      expect(el.html()).to eq('Value is 42')
    end
  end

  end
=end

end
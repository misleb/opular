$opular.module('op').constant('a', 1).constant('b', 2)

i = Op::Injector.new(['op'])

fn = ->(a, b) { a + b }

class Blah
  attr_reader :result

  def initialize(a, b)
    puts self.inspect
    @result = a + b
  end
end

class A
  def _get(b)
    self
  end
end

class B
  def _get()
    self
  end
end

class C
  def _get(a)
    self
  end
end





$opular.module('op').factory('aValue') do
  {aKey: 42}
end.config do |_provide|
  _provide.decorator('aValue') do |_delegate|
    _delegate[:decoratedKey] = 43
  end
end

Op::Injector.new(['op']).get('aValue')




class MyService
  attr_reader :value

  def initialize(theValue)
    @value = theValue
  end
end

$opular.module('op')
  .value('theValue', 42)
  .service('aService', MyService)

Op::Injector.new(['op']).get('aService')




 do
  {aKey: 42}
end.config do |_provide|
  _provide.decorator('aValue') do |_delegate|
    _delegate[:decoratedKey] = 43
  end
end

Op::Injector.new(['op']).get('aValue')






class AProvider
  attr_accessor :value

  def initialize(_provide)
    _provide.constant('b', 2)
  end

  def _get(b)
    b + @value.to_i
  end
end

$opular.module('noob', []) do |aProvider|
    aProvider.value = 42
  end
  .provider('a', AProvider)
  .run do |a|
    puts "Run: #{a}"
  end


i = Op::Injector.new(['op'])

  puts i.get('a')




" asdf food.bar = 2".gsub(/\s+([^\.|\s]+)\s+\=[^\=]/, ' self.\1 = ')




s = Op::Scope.new
s._watch(->(scp) { scp.num }, ->(n,o,scp) { puts "#{n}, #{o}" })
s._apply("self.num = 1")




result = $opular_injector.invoke(->(_compile) {
  el = Element.find(".home-index")
  _compile.run(el)
})

result.data('hasCompiled')







begin
  puts "ONce"
end while false










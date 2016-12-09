RSpec::Matchers.define :override_method do |expected|
  match do |actual|
    klass = actual.is_a?(Class) ? actual : actual.class
    method = klass.instance_method(expected)
    method.owner == klass
  end
end

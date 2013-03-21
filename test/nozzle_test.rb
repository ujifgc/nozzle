require 'minitest_helper'

describe Nozzle do
  it 'should have a version' do
    Nozzle::VERSION.must_match /.+/
  end
end

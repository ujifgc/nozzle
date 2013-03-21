require 'minitest_helper'

describe Nozzle::Adapter do

  before do
    class Klass0
      def avatar
        @avatar
      end
      def avatar=(value)
        @avatar = value
      end
    end
    Klass0.send :extend, Nozzle::Adapter
    Klass0.install_adapter :avatar
  end

  it 'should be able to install itself' do
    Klass0.adapter_classes.must_equal :avatar => Nozzle::Adapter::Base
  end

  it 'should register instance methods' do
    @inst = Klass0.new
    @inst.respond_to?(:avatar_adapter).must_equal true
    @inst.respond_to?(:avatar).must_equal true
    @inst.respond_to?(:avatar=).must_equal true
    @inst.respond_to?(:avatar_after_save).must_equal true
    @inst.respond_to?(:avatar_after_destroy).must_equal true
    @inst.avatar_adapter.class.must_equal Nozzle::Adapter::Base
  end

  it 'should register instance methods one and only one time' do
    Klass0.install_adapter :avatar
    Klass0.install_adapter :avatar
    @inst = Klass0.new
    @inst.avatar.class.must_equal Nozzle::Adapter::Base
    @inst.original_avatar.class.wont_equal Nozzle::Adapter::Base
  end

end

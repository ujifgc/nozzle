require 'minitest_helper'
require 'fileutils'

describe Nozzle::Adapter::Base do
  # these tests are ordered
  class << self; define_method :test_order do :alpha end; end

  before do
    class Klass1
      def avatar
        @avatar
      end
      def avatar=(value)
        @avatar = value
      end
      def save
        send :avatar_after_save
      end
      def destroy
        send :avatar_after_destroy
      end
    end
    Klass1.send :extend, Nozzle::Adapter
    Klass1.install_adapter :avatar
  end

  it 'should raise ENOENT on non-existing asset' do
    inst = Klass1.new
    lambda do
      inst.avatar = 'test/fixtures/non-existing.jpg'
    end.must_raise Errno::ENOENT
  end

  it 'should raise ArgumentError on bad arguments' do
    inst = Klass1.new
    lambda do
      inst.avatar = ['array']
    end.must_raise ArgumentError
    lambda do
      inst.avatar = :symbol
    end.must_raise ArgumentError
  end

  it 'should save file into public folder and destroy it' do
    PUBLIC_PATH = './public/Klass1/avatar/test-697x960.jpg'

    inst = Klass1.new
    inst.avatar = 'test/fixtures/test-697x960.jpg'
    inst.avatar.filename.must_equal 'test-697x960.jpg'

    inst.save
    inst.avatar.path.must_equal PUBLIC_PATH
    File.exists?(PUBLIC_PATH).must_equal true

    inst.destroy
    File.exists?(PUBLIC_PATH).must_equal false
  end

  after do
    FileUtils.rm_rf './public'
  end

end

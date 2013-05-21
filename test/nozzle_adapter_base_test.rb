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
    public_path = 'public/uploads/Klass1/avatar/test-697x960.jpg'

    inst = Klass1.new
    inst.avatar = 'test/fixtures/test-697x960.jpg'
    inst.avatar.filename.must_equal 'test-697x960.jpg'

    inst.save
    inst.avatar.path.must_equal public_path
    File.exists?(public_path).must_equal true

    inst.save
    inst.avatar.path.must_equal public_path
    File.exists?(public_path).must_equal true

    inst.destroy
    File.exists?(public_path).must_equal false
  end

  it 'should return intermediate tempfile path or stored path' do
    inst = Klass1.new
    inst.avatar = 'test/fixtures/test-697x960.jpg'
    inst.avatar.access_path.must_equal File.expand_path('test/fixtures/test-697x960.jpg')
    inst.save
    inst.avatar.access_path.must_equal 'public/uploads/Klass1/avatar/test-697x960.jpg'
  end

  it 'should respect custom filename' do
    public_path = 'public/uploads/Klass1/avatar/girl-and-square.jpg'

    inst = Klass1.new
    inst.avatar = { :tempfile => 'test/fixtures/test-697x960.jpg', :filename => 'girl-and-square.jpg' }
    inst.avatar.filename.must_equal 'girl-and-square.jpg'

    inst.save
    inst.avatar.path.must_equal public_path
    File.exists?(public_path).must_equal true

    inst.destroy
    File.exists?(public_path).must_equal false
  end

  it 'should accept string-keyed hash' do
    public_path = 'public/uploads/Klass1/avatar/girl-and-square.jpg'

    inst = Klass1.new
    inst.avatar = { 'tempfile' => 'test/fixtures/test-697x960.jpg', 'filename' => 'girl-and-square.jpg' }
    inst.avatar.filename.must_equal 'girl-and-square.jpg'

    inst.save
    inst.avatar.path.must_equal public_path
    File.exists?(public_path).must_equal true

    inst.destroy
    File.exists?(public_path).must_equal false
  end

  after do
    FileUtils.rm_rf 'public'
  end

end

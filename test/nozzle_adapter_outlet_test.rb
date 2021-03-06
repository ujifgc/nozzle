require 'minitest_helper'
require 'fileutils'

describe Nozzle::Adapter::Outlet do
  # these tests are ordered
  class << self; define_method :test_order do :alpha end; end

  before do
    class Klass2
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
    Klass2.send :extend, Nozzle::Adapter
    class BaseOutlet < Nozzle::Adapter::Base
      def filename
        "#{Time.now.strftime('%Y%m%d')}_#{super}"
      end

      outlet :thumb do
        def filename
          'ava_' + super
        end
        def prepare( original, result )
          `convert #{original} -thumbnail x96 #{result}`
        end
        outlet :mini
      end
      outlet :big do
        def relative_folder
          File.join 'big', @model.to_s
        end
      end
    end
    Klass2.install_adapter :avatar, BaseOutlet
  end

  it 'should install an adapter with custom filename and outlets' do
    date = Time.now.strftime('%Y%m%d')
    inst = Klass2.new
    inst.avatar = 'test/fixtures/test-697x960.jpg'
    inst.save
    inst.avatar.filename.must_equal "#{date}_test-697x960.jpg"
    inst.avatar.thumb.filename.must_equal "ava_#{date}_test-697x960.jpg"
    inst.avatar.big.path.must_equal "public/uploads/big/Klass2/big_#{date}_test-697x960.jpg"
    inst.avatar.thumb.mini.path.must_equal "public/uploads/Klass2/avatar/mini_ava_#{date}_test-697x960.jpg"
    inst.avatar.respond_to?(:version_name).must_equal false, 'original adapter must not have version name'
    inst.avatar.thumb.version_name.must_equal 'thumb'
    inst.avatar.thumb.mini.version_name.must_equal 'thumb_mini'

    inst.avatar.thumb.prepare!
    `identify #{inst.avatar.thumb.path}`.must_match /JPEG 70x96/
    inst.avatar.big.prepare!
    `identify #{inst.avatar.big.path}`.must_match /JPEG 697x960/

    inst.avatar.cleanup!
    File.exists?(inst.avatar.path).must_equal true, 'outlet must not cleanup the original'
    File.exists?(inst.avatar.thumb.path).must_equal false, 'outlet must cleanup its cache'
    File.exists?(inst.avatar.big.path).must_equal false
    File.exists?(inst.avatar.big.system_path).must_equal false, 'outlet must cleanup its folders'

    inst.avatar.big.prepare!
    `identify #{inst.avatar.big.path}`.must_match /JPEG 697x960/
    a,b,a1,b1 = [ inst.avatar.path, inst.avatar.big.path, inst.avatar.system_path, inst.avatar.big.system_path ]
    inst.destroy
    File.exists?(a).must_equal false
    File.exists?(b).must_equal false
    File.exists?(a1).must_equal false
    File.exists?(b1).must_equal false
  end

  it 'should move temporary file' do
    temporary_path = '/tmp/test-697x960.jpg'
    FileUtils.cp 'test/fixtures/test-697x960.jpg', temporary_path
    inst1 = Klass2.new
    inst1.avatar = temporary_path
    inst1.save
    File.exists?(inst1.avatar.path).must_equal true
    File.exists?(temporary_path).must_equal false
  end

  it 'should copy non-temporary file' do
    permanent_path = 'test/fixtures/test-697x960.jpg'
    inst1 = Klass2.new
    inst1.avatar = permanent_path
    inst1.save
    File.exists?(inst1.avatar.path).must_equal true
    File.exists?(permanent_path).must_equal true
  end

  after do
    FileUtils.rm_rf 'public'
  end

end

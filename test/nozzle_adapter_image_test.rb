require 'minitest_helper'
require 'fileutils'
require 'nozzle/adapter/image'

describe Nozzle::Adapter::Image do
  # these tests are ordered
  class << self; define_method :test_order do :alpha end; end

  before do
    class Klass3
      def avatar1; @avatar1; end
      def avatar1=(value); @avatar1 = value; end
      def avatar2; @avatar2; end
      def avatar2=(value); @avatar2 = value; end
      def save
        send :avatar1_after_save
        send :avatar2_after_save
      end
      def destroy
        send :avatar1_after_destroy
        send :avatar2_after_destroy
      end
    end
    Klass3.send :extend, Nozzle::Adapter
    Klass3.install_adapter :avatar1, Nozzle::Adapter::Image
    Klass3.install_adapter :avatar2, Nozzle::Adapter::Image, :thumb_size => '90x60'
  end

  it 'should have default url' do
    inst = Klass3.new
    inst.avatar1.url.must_equal '/images/image_missing.png'
    inst.avatar2.settings[:thumb_size].must_equal '90x60'
    inst.avatar1.settings[:thumb_size].must_equal '200x150'

    inst.avatar1 = 'test/fixtures/test-697x960.jpg'
    inst.avatar2 = 'test/fixtures/test-697x960.jpg'
    inst.save
    inst.avatar1.thumb.prepare!
    `identify #{inst.avatar1.thumb.path}`.must_match /JPEG 109x150/
    inst.avatar2.thumb.prepare!
    `identify #{inst.avatar2.thumb.path}`.must_match /JPEG 44x60/
  end

  after do
    FileUtils.rm_rf './public'
  end

end

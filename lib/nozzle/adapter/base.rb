require 'fileutils'
require 'nozzle/adapter/outlet'

module Nozzle
  module Adapter
    class Base
      include Nozzle::Adapter::Outlet

      # Initializes internal structure of new adapter.
      #   outlet_class.new( instance, :avatar, 'image.jpg', :fake => true
      def initialize( record, column, filename, options = {} )
        @record = record
        @model = record.class
        @column = column.to_sym
        @filename = filename
        settings.merge! options
      end

      # Sets or gets settings provided by options.
      #   if instance.avatar.settings[:fake]
      #     instance.avatar.settings[:fake] = false
      #   end
      def settings
        @settings ||= {}
      end

      # Constructs an URL which relatively points to file resource.
      #   instance.avatar.url # => '/uploads/Model/avatar/image.jpg'
      # Note: if filename is not yet stored, +default_url+ is called.
      def url
        File.join '', public_path, filename
      rescue TypeError
        default_url
      end

      # Constructs a filesustem path which absolutely points to stored file.
      #   instance.avatar.path # => '/home/user/project/public/uploads/Model/avatar/image.jpg'
      # Note: if filename is not yet stored, nil is returned.
      def path
        File.join system_path, filename
      rescue TypeError
        nil
      end

      # Returns stored filename.
      #   instance.avatar.filename # => 'image.jpg'
      def filename
        @filename
      end

      # Returns nil.
      # This SHOULD be overridden by subclasses of Nozzle::Adapter::Base.
      #   instance.avatar.default_url # => nil
      def default_url
        nil
      end

      # Returns root path of an application.
      #   instance.avatar.root # => '.'
      # This MAY be overridden to return an application root different
      # from the current folder.
      def root
        '.'
      end

      def adapter_folder
        'uploads'
      end

      def adapter_path
        File.join root, 'public', adapter_folder
      end

      def relative_folder
        File.join @model.to_s, @column.to_s
      end

      def system_path
        File.join adapter_path, relative_folder
      end

      def public_path
        File.join adapter_folder, relative_folder
      end

      def to_s
        "#{self.class}#url: #{url}"
      end

      def delete
        @record.send(:"#{@column}=", nil)
      end

      def load( value )
        @filename = value
        self
      end

      def dump( value )
        reset
        @original_path = path
        return nil  unless value

        new_path = expand_argument value
        raise Errno::ENOENT, "'#{new_path}'"  unless File.exists?(new_path)

        @tempfile_path = File.expand_path(new_path)
        @filename
      end

      def store!
        unlink! @original_path
        return nil  unless @tempfile_path

        new_path = path
        FileUtils.mkdir_p File.dirname(new_path)
        result = if @tempfile_path =~ /\/t.?mp\//
          FileUtils.move @tempfile_path, new_path
        else
          FileUtils.copy @tempfile_path, new_path
        end
        reset
        result
      end

      def unlink!( target = path )
        FileUtils.rm_f target  if target
      end

    private

      def reset
        @original_path = nil
        @tempfile_path = nil
      end

      def expand_argument( value )
        tempfile_path = case value
        when String
          value
        when File
          value.path
        when Hash
          expand_argument( value[:tempfile] || value['tempfile'] )
        else
          raise ArgumentError, "#{@model}##{@column}= argument must be kind of String, File or Hash[:tempfile => 'path']"
        end
        @filename = value.kind_of?(Hash) && ( value[:filename] || value['filename'] ) || File.basename(tempfile_path)
        tempfile_path
      end

    end
  end
end

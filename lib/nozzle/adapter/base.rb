require 'fileutils'

module Nozzle
  module Adapter
    class Base

      def initialize( record, column )
        @record = record
        @model = record.class
        @column = column.to_sym
      end

      def url
        File.join '', relative_folder, filename
      rescue TypeError
        default_url
      end

      def path
        File.join absolute_folder, filename
      rescue TypeError
        nil
      end

      def filename
        @filename
      end

      def default_url
        nil
      end

      def root
        '.'
      end

      def adapter_folder
        File.join root, 'public/uploads'
      end

      def relative_folder
        File.join @model.to_s, @column.to_s
      end

      def absolute_folder
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

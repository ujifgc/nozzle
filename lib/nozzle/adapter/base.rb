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
        File.join root, 'public'
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
        @original_path = nil
        @tempfile_path = nil

        new_path = case value
        when String
          value
        when File
          value.path
        when Hash
          actual_filename = value[:filename]
          value[:tempfile].path || value[:filetemp]
        when NilClass
          @unlink_requested = true
          @original_path = path
          nil
        else
          raise ArgumentError, "#{@model}##{@column}= argument must be kind of String, File, Hash or nil"
        end

        return nil  unless new_path
        raise Errno::ENOENT, "'#{new_path}'"  unless File.exists?(new_path)

        @original_path ||= path
        @tempfile_path = File.expand_path(new_path)  
        @filename = actual_filename || File.basename(new_path)
      end

      def store!
        FileUtils.rm_f @original_path  if @original_path
        return @unlink_requested = nil  if @unlink_requested
        return nil  unless @tempfile_path

        new_path = path
        FileUtils.mkdir_p File.dirname(new_path)
        result = if @tempfile_path =~ /\/t.?mp\//
          FileUtils.move @tempfile_path, new_path
        else
          FileUtils.copy @tempfile_path, new_path
        end
      end

      def unlink!
        FileUtils.rm_f path  if path
      end

    end
  end
end

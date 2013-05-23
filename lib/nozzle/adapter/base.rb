require 'fileutils'
require 'tempfile'
require 'nozzle/adapter/outlet'

module Nozzle
  module Adapter
    class Base
      include Nozzle::Adapter::Outlet

      # Initializes internal structure of new adapter.
      #   outlet_class.new( instance, :avatar, 'image.jpg', :fake => true )
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

      # Constructs an URL which relatively points to the file.
      #   instance.avatar.url # => '/uploads/Model/avatar/image.jpg'
      # How it's constructed:
      #   "#{public_path}/#{filename}"
      #   "/#{adapter_folder}/#{relative_folder}/#{filename}"
      #   "/uploads/#{@model}/#{@column}/#{filename}"
      #   "/uploads/Model/avatar/image.jpg"
      # Note: if filename is not yet stored, +default_url+ is called.
      def url
        File.join '', public_path, filename
      rescue TypeError
        default_url
      end

      # Constructs a filesustem path which absolutely points to stored file.
      #   instance.avatar.path # => 'public/uploads/Model/avatar/image.jpg'
      # How it's constructed:
      #   "/#{system_path}/#{filename}"
      #   "/#{adapter_path}/#{relative_folder}/#{filename}"
      #   "#{root}/#{adapter_folder}/#{@model}/#{@column}/#{filename}"
      #   "public/uploads/#{@model}/#{@column}/#{filename}"
      #   "public/uploads/Model/avatar/image.jpg"
      # Note: if filename is not yet stored, nil is returned.
      def path
        File.join system_path, filename
      rescue TypeError
        nil
      end

      # Returns intermediate path to the tempfile if the record is not yet
      # saved and file is not yet stored at path.
      def access_path
        @tempfile_path || path
      end

      # Returns file content_type stored in avatar_content_type column
      # of the record.
      def content_type
        @record.send( :"#{@column}_content_type" )  rescue ''
      end

      # Returns file size stored in avatar_size column of the record.
      def size
        @record.send( :"#{@column}_size" )  rescue -1
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

      # Returns root path of application's static assets.
      #   instance.avatar.root # => 'public'
      # This MAY be overridden to return an application root different
      # from the current folder.
      def root
        'public'
      end

      # Returns folder name of the adapter relative to application public.
      #   instance.avatar.adapter_folder # => 'uploads'
      # This MAY be overridden to specify where all the files should be stored.
      def adapter_folder
        'uploads'
      end

      # Returns filesystem folder path of the adapter relative to adapter root.
      #   instance.avatar.adapter_path # => 'public/uploads'
      # It is constructed from #root, 'public' and #adapter_folder.
      def adapter_path
        File.join root, adapter_folder
      end

      # Returns file's folder relative to #adapter_path.
      #   instance.avatar.relative_folder # => 'Model/avatar'
      # It is constructed from object's class name and column name.
      # This MAY be overridden to place files somwhere other than 'Model/avatar'.
      def relative_folder
        File.join @model.to_s, @column.to_s
      end

      # Returns filesystem folder path relative to adapter root.
      #   instance.avatar.system_path # => 'public/uploads/Model/avatar'
      # It is constructed from #adapter_path and #relative_folder
      def system_path
        File.join adapter_path, relative_folder
      end

      # Returns folder path relative to public folder.
      #   instance.avatar.public_path # => 'uploads/Model/avatar'
      # It is constructed from #adapter_folder and #relative_folder
      def public_path
        File.join adapter_folder, relative_folder
      end

      # Inspects class name and url of the object.
      #   instance.avatar.to_s # => 'Model#url: /uploads/Model/avatar/image.jpg'
      def to_s
        "#{self.class}#url: #{url}"
      end

      # Sets adapter to delete stored file on #adapеr_after_save.
      #   instance.avatar.delete # => nil
      def delete
        @record.send(:"#{@column}=", nil)
      end

      # Returns adapter instance.
      # It's used in Nozzle::Adapter#avatar after retrieving filename from the object.
      def load( value )
        @filename = value
        self
      end

      # Fills internal structure of the adapter with new file's path.
      # It's used in Nozzle::Adapter#avatar= before sending filename to the object.
      def dump( value )
        reset
        @original_path = path
        return nil  unless value

        new_path = expand_argument value
        raise Errno::ENOENT, "'#{new_path}'"  unless File.exists?(new_path)

        @tempfile_path = File.expand_path(new_path)
        detect_properties
        @filename
      end

      # Stores temporary filename by the constructed path. Deletes old file.
      # Note: the file is moved if it's path contains /tmp/ or /temp/, copied
      # otherwise.
      def store!
        unlink! @original_path
        return nil  unless @tempfile_path

        new_path = path
        FileUtils.mkdir_p File.dirname(new_path)
        result = if @tempfile_path =~ /\/te?mp\//
          FileUtils.move @tempfile_path, new_path
        else
          FileUtils.copy @tempfile_path, new_path
        end
        File.chmod 0644, new_path
        reset
        result
      end

      # Deletes file by path. Do not use, it will break adapter's integrity.
      # It's called in #avatar_after_destroy after the object is destroyed.
      #   unlink!                # deletes path
      #   unlink! @original_path # deletes @original_path
      #   unlink! nil            # deletes nothing
      def unlink!( target = path )
        delete_file_and_folder! target  if target
      end

      def as_json
        { :url => url }
      end

    private

      # Tries to detect content_type and size of the file.
      # Note: this method calls `file` system command to detect file content type.
      def detect_properties
        @record.send( :"#{@column}_content_type=", `file -bp --mime-type '#{access_path}'`.to_s.strip )
        @record.send( :"#{@column}_size=", File.size(access_path) )
      rescue NoMethodError
        nil
      end

      # Resets internal paths.
      def reset
        @original_path = nil
        @tempfile_path = nil
      end

      # Analyzes the value assigned to adapter and fills @filename. Returns
      # system path where temporary file is located.
      # The +value+ MUST be File, String, Hash or nil. See Nozzle::Adapter#avatar=.
      def expand_argument( value )
        tempfile_path = case value
        when String
          value
        when File, Tempfile
          value.path
        when Hash
          expand_argument( value[:tempfile] || value['tempfile'] )
        else
          raise ArgumentError, "#{@model}##{@column}= argument must be kind of String, File, Tempfile or Hash[:tempfile => 'path']"
        end
        @filename = value.kind_of?(Hash) && ( value[:filename] || value['filename'] ) || File.basename(tempfile_path)
        tempfile_path
      end

      # Deletes the specified file and all empty folders recursively stopping at
      # #adapter_folder.
      def delete_file_and_folder!( file_path )
        FileUtils.rm_f file_path
        boundary = adapter_path + '/'
        loop do
          file_path = File.dirname file_path
          break  unless file_path.index boundary
          FileUtils.rmdir file_path
        end
      end

    end
  end
end

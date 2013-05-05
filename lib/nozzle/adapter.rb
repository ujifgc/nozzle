require 'nozzle/adapter/base'

module Nozzle
  module Adapter
    # Installs default or custom adapter to a class.
    #
    #   class Example
    #     attr_accessor :file, :avatar, :thumb
    #     include Nozzle::Adapter
    #     install_adapter( :file )
    #     install_adapter( :avatar, CustomAdapter )
    #     install_adapter( :thumb, Nozzle::Adapter::Image, :thumb_size => '90x60' )
    #     def save
    #       file_after_save; avatar_after_save; thumb_after_save
    #     end
    #     def destroy
    #       file_after_destroy; avatar_after_destroy; thumb_after_destroy
    #     end
    #   enc
    #
    # The class MUST have readers and writers to install corresponding adapters.
    # +install_adapter+ overrides these methods and saves the originals in
    # <tt>original_avatar</tt> and <tt>original_avatar=</tt> aliases.
    # The originals are called to save and load the filename of stored asset.
    #
    # The class MUST call +avatar_after_save+ and +avatar_after_destroy+ after
    # the corresponding events. +avatar_after_save+ does some IO to move
    # or copy temporary file. +avatar_after_destroy+ deletes the stored file.
    #
    # Note: +options+ are only supported when +adapter+ is specified.
    def install_adapter( column, adapter = nil, options = {} )
      attr_accessor :"#{column}_adapter"
      adapter_classes[column] = adapter || Base
      adapter_options[column] = options

      class_eval <<-RUBY, __FILE__, __LINE__+1
        unless instance_methods.map(&:to_s).include?('original_#{column}')
          alias_method :original_#{column}, :#{column}
          alias_method :original_#{column}=, :#{column}=
        end

        def #{column}_adapter
          @#{column}_adapter ||= self.class.adapter_classes[:#{column}].new(  
            self, :#{column}, nil, self.class.adapter_options[:#{column}] )   
        end

        def #{column}
          #{column}_adapter.load send( :original_#{column} )
        end

        def #{column}=(value)
          send( :original_#{column}=, #{column}_adapter.dump(value) )
        end

        def #{column}_after_save
          #{column}_adapter.store!
        end

        def #{column}_after_destroy
          #{column}_adapter.cleanup!
          #{column}_adapter.unlink!
        end
      RUBY
    end

    def adapter_classes # :nodoc:
      @adapter_classes ||= {}
    end

    def adapter_options # :nodoc:
      @adapter_options ||= {}
    end

    ##
    # :method: avatar
    # Returns column adapter instance.
    #
    # Note: this method and the following 3 methods are dynamically created by
    # +install_adapter+. These methods will be named according to the column
    # name specified in first argument of +install_adapter+ call.
    # This document explains methods created for column named <tt>:avatar</tt>.

    ##
    # :method: avatar=
    #
    # :call-seq: avatar=(value)
    #
    # Calls initialization routines to save file into class instance.
    #
    # The +value+ MUST be File, String, Hash or nil
    #   instance.avatar = File.open('tmp/031337.jpg')
    #   instance.avatar = 'tmp/031337.jpg'
    #   instance.avatar = { :filename => 'Cool file.jpg', :tempfile => cool }
    #   instance.avatar = nil
    # If +value+ is nil then the stored file is deleted on +avatar_after_save+.

    ##
    # :method: avatar_after_save
    # Calls Base#store! to move or copy temporary file to it's new store location.

    ##
    # :method: avatar_after_destroy
    # Calls Base#unlink! to cleanup stored files.
  end
end

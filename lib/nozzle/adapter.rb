require 'nozzle/adapter/base'

module Nozzle
  module Adapter

    def adapter_classes
      @adapter_classes ||= {}
      @adapter_classes
    end

    def install_adapter( column, adapter = nil )
      attr_accessor :"#{column}_adapter"
      adapter_classes[column] = adapter || Base

      class_eval <<-INSTANCE_METHODS, __FILE__, __LINE__+1
        unless instance_methods.map(&:to_s).include?('original_#{column}')
          alias_method :original_#{column}, :#{column}
          alias_method :original_#{column}=, :#{column}=
        end

        def #{column}_adapter
          @#{column}_adapter ||= self.class.adapter_classes[:#{column}].new( self, :#{column} )
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
          #{column}_adapter.unlink!
        end
      INSTANCE_METHODS

    end

  end
end

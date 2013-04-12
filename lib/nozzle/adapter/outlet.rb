module Nozzle
  module Adapter
    module Outlet

      def self.included(base)
        base.instance_eval do
          def outlets
            @outlets ||= {}
          end
        end
        base.extend(ClassMethods)
      end

      def outlets
        return @outlets  if @outlets
        @outlets = {}
        self.class.outlets.each do |name, outlet_class|
          @outlets[name] = outlet_class.new(@record, @column, @filename, @settings)
        end
        @outlets
      end

      def prepare( original, result )
        FileUtils.mkdir_p File.dirname(result)
        FileUtils.cp original, result
      end

      def prepare!
        prepare( @record.send(@column).path, path )
      end

      def cleanup!
        delete_file_and_folder!( path )  if respond_to?(:version_name)
        outlets.each{ |name, outlet| outlet.cleanup! }
      end

      module ClassMethods

        def outlet( name, &block )
          class_eval <<-RUBY,__FILE__,__LINE__+1
            def #{name}
              outlets[:#{name}]
            end
          RUBY
          outlets[name] = create_outlet( name, &block )
        end

      private

        def create_outlet( name, &block )
          new_outlet = Class.new(self)
          new_outlet.class_eval <<-RUBY,__FILE__,__LINE__+1
            def version_name
              (defined?(super) ? super+'_' : '') + "#{name}"
            end
            def filename
              "#{name}_\#{super}"
            end
          RUBY
          new_outlet.class_eval(&block)  if block
          new_outlet
        end

      end

    end
  end
end

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
        self.class.outlets.each do |name, outlet|
          @outlets[name] = outlet.new(@record, @column, @filename)
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
        if respond_to?(:version_name)
          dir = path
          FileUtils.rm_f dir
          loop do
            FileUtils.rmdir dir = File.dirname(dir)
            break  unless dir.index(adapter_folder+'/')
          end
        end
        outlets.each{ |name, outlet| outlet.cleanup! }
      end

      module ClassMethods

        def outlet( name, &block )
          class_eval <<-RUBY,__FILE__,__LINE__+1
            def #{name}
              outlets[:#{name}]
            end
          RUBY
          unless outlets[name]
            outlets[name] = Class.new(self)
            outlets[name].class_eval <<-RUBY,__FILE__,__LINE__+1
              def version_name
                (defined?(super) ? super+'_' : '') + "#{name}"
              end
              def filename
                "#{name}_\#{super}"
              end
            RUBY
          end
          outlets[name].class_eval(&block)  if block
        end

      end

    end
  end
end

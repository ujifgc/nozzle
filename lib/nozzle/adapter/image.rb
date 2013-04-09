require 'nozzle/adapter/base'

module Nozzle
  module Adapter
    class Image < Nozzle::Adapter::Base
      DEFAULT_SETTINGS = {
        :thumb_size => '200x150',
      }.freeze
      
      def initialize( record, column, filename = nil, options = {} )
        @settings = DEFAULT_SETTINGS.dup
        super( record, column, filename, options )
      end
      
      def default_url
        '/images/image_missing.png'
      end

      outlet :thumb do
        def prepare( original, result )
          `convert #{original} -thumbnail #{settings[:thumb_size]} #{result}`
        end
      end

    end
  end
end

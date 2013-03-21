# encoding: utf-8

require 'nozzle'
require 'dm-core'

module Nozzle
  module DataMapper
    include Nozzle::Adapter

    module Property
      class Filename < ::DataMapper::Property::String
        length 255
        def custom?; true; end
      end
    end

    def nozzle!( column, adapter = nil )
      property column, Property::Filename  unless properties.named?(column)

      install_adapter column, adapter

      after :save,    :"#{column}_after_save"
      after :destroy, :"#{column}_after_destroy"
    end
  end
end

DataMapper::Model.append_extensions(Nozzle::DataMapper)

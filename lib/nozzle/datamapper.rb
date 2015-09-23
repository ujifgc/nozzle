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
      property column,                    Property::Filename     unless properties.named?(column)
      property :"#{column}_content_type", String, :length => 127 unless properties.named?("#{column}_content_type")
      property :"#{column}_size",         Integer                unless properties.named?("#{column}_size")

      install_adapter column, adapter

      after :save,    :"#{column}_after_save"
      after :destroy, :"#{column}_after_destroy"
    end
  end
end

DataMapper::Model.append_extensions(Nozzle::DataMapper)

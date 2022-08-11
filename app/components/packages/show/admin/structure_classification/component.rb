# frozen_string_literal: true

module Packages
  module Show
    module Admin
      module StructureClassification
        class Component < ViewComponent::Base
          attr_reader :package

          def initialize(package:)
            @package = package
          end

          def categories
            SibrowserConfig::CATEGORIES_2
          end

          def radio_name(round_id, theme_id, question_id, category)
            [round_id, theme_id, question_id, category].join('_')
          end

          def value_by_name(name)
            parts = name.split('_')
            package&.structure_classification&.[](name) || 'null'
          end
        end
      end
    end
  end
end

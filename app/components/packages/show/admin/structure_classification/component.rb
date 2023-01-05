# frozen_string_literal: true

module Packages
  module Show
    module Admin
      module StructureClassification
        class Component < ViewComponent::Base
          attr_reader :package

          def initialize(package:)
            @package = package

            @tabs = {}
            total_questions = @package.question_distribution[:total]

            categories.each_with_index do |cat, i|
              # (total_questions + 1) for submit button
              # * 3 for yes-null-no 3 radio buttons
              @tabs[cat] = (total_questions + 1) * i * 3
            end
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

          def tabindex(category)
            @tabs[category] += 1
          end
        end
      end
    end
  end
end

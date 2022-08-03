# frozen_string_literal: true

module Packages
  module Show
    module Questions
      class Component < ViewComponent::Base
        attr_reader :structure

        def initialize(structure:)
          @structure = structure || []
        end

        def tab_id(i)
          "round-tab-#{i}"
        end

        def content_id(i)
          "round-content-#{i}"
        end
      end
    end
  end
end

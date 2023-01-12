# frozen_string_literal: true

module Packages
  module Distributions
    class Component < ViewComponent::Base
      def initialize(package:, class: '')
        @package = package
        @class = binding.local_variable_get(:class)
      end
    end
  end
end

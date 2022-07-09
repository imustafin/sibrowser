# frozen_string_literal: true

module Packages
  module FileName
    class Component < ViewComponent::Base
      def initialize(package:, class: nil)
        @package = package
        @class = binding.local_variable_get(:class)
      end
    end
  end
end

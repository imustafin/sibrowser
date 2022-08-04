# frozen_string_literal: true

module Packages
  module Logo
    class Component < ViewComponent::Base
      attr_reader :package

      def initialize(package:)
        @package = package
      end
    end
  end
end

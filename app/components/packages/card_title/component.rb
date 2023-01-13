# frozen_string_literal: true

module Packages
  module CardTitle
    class Component < ViewComponent::Base
      attr_reader :variant

      def initialize(package:, variant:)
        @package = package

        raise "Unknown variant #{variant}" unless %i[small big].include?(variant)
        @variant = variant
      end

      def title_size
        variant == :big ? 'text-2xl' : 'text-xl'
      end

      def link?
        variant == :small
      end
    end
  end
end

# frozen_string_literal: true

module PackagesPaginated
  module Local
    class Component < ViewComponent::Base
      def initialize(local_key:)
        @local_key = local_key
      end
    end
  end
end

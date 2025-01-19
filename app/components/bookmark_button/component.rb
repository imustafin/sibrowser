# frozen_string_literal: true

module BookmarkButton
  class Component < ViewComponent::Base
    def initialize(class:, package_id:, with_controller: false, thin: false)
      @class = binding.local_variable_get(:class)
      @package_id = package_id
      @with_controller = with_controller
      @thin = thin
    end
  end
end

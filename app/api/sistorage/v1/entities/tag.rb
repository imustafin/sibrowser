module Sistorage
  module V1
    module Entities
      class Tag < Grape::Entity
        expose :name, documentation: {
            type: String,
            required: true,
            desc: 'Tag name'
          } \
        do |tag, _options|
          tag
        end
      end
    end
  end
end

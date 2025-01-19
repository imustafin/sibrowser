module Sistorage
  module V1
    module Entities
      class PackagePage < Grape::Entity
        expose :packages, using: Package, documentation: {
            is_array: true
          }
        expose :total, documentation: {
            type: Integer,
            desc: 'Total number of packages'
          }
      end
    end
  end
end

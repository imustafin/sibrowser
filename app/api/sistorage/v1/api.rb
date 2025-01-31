module Sistorage
  module V1
    class Api < Grape::API
      version 'v1'

      desc 'Which advanced SIStorage capabilities are supported'
      get :info do
        {
          randomPackagesSupported: false,
          identifiersSupported: false
        }
      end
      resource :packages do
        desc 'Search packages by facet values',
          entity: Entities::PackagePage,
          detail: ''
        params do
          optional :from, type: Integer, desc: 'Last `id` of the previous page for pagination'
          optional :count, type: Integer, desc: 'Number of packages per result page. Maximum is `10`.', values: 0..10
        end
        get :search do
          limit = params[:count] || 10
          from = params[:from]

          packages = Package.visible

          total = packages.count

          packages = packages.offset(from) if from

          packages = packages.limit(limit)

          res = { total:, packages: }
          present res, with: Entities::PackagePage
        end

        route_param :package_id, type: Integer do
          desc 'Get package by id',
            entity: Entities::Package,
            detail: ''
          get do
            p = Package.find(params[:package_id])

            present p, with: Entities::Package
          end
        end
      end
    end
  end
end

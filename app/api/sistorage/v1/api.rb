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
          optional :sortMode, type: Integer, values: [0, 1, 2, 3], desc: <<~DESC
            Sort key. By default sort by `id`. Possible values:
            * `0`: name
            * `1`: creation date
            * `2`: download count
            * `3`: rating (unused, falls back to `id`)
          DESC
          optional :sortDirection, type: Integer, values: [0, 1], desc: <<~DESC
            Sort direction. By default sort in ascending order. Possible values:
            * `0`: ascending
            * `1`: descending
          DESC
          optional :searchText, type: String, length: { max: 100 }, desc: <<~DESC
            Free-text search.

            Maximum length is 100 characters.
          DESC
          optional :tags, type: String, desc: <<~DESC
            Comma-separated list of tags.

            Maximum length is 100 characters.
          DESC
        end
        get :search do
          limit = params[:count] || 10
          from = params[:from]
          sort_modes = {
            0 => :name,
            1 => :created_at,
            2 => :download_count,
            3 => :id
          }
          sort_key = sort_modes[params[:sortMode]] || :id
          sort_dirs = {
            0 => :asc,
            1 => :desc
          }
          sort_dir = sort_dirs[params[:sortDirection]] || :asc

          packages = Package.visible.order(sort_key => sort_dir)

          if params[:searchText].present?
            packages = packages.search_freetext(params[:searchText])
          end

          if sort_key != :id
            # Add order by id to break ties in predictable order
            packages = packages.order(id: :asc)
          end

          if params[:tags]
            params[:tags]
              .split(',')
              .map(&:strip)
              .each { packages = packages.by_tag(it) }
          end

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

      resource :facets do
        resource :tags do
          desc 'Get all tags',
            entity: Entities::Tag,
            is_array: true,
            detail: ''
          get do
            tags = Package
              .from(Package.visible.select('jsonb_array_elements_text(tags) AS tag'))
              .where("tag <> ''")
              .group('lower(tag)')
              .order('lower(tag) asc')
              .pluck('min(tag)')
            present tags, with: Entities::Tag
          end
        end
      end
    end
  end
end

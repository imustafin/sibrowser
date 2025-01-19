module Sistorage
  module V1
    module Entities
      class Package < Grape::Entity
        include Rails.application.routes.url_helpers

        expose :id, documentation: {
            required: true,
            type: Integer
          }
        expose :name, documentation: {
            type: String,
            desc: 'Human readable name'
          }
        expose :directContentUri, documentation: {
            type: String,
            desc: 'Package direct content location. Using this link does not increase the download count.'
          } \
        do |package, _options|
          package.vk_download_url
        end

        expose :logoUri, documentation: {
            type: String,
            desc: 'Package logo location. Can be an absolute path on this host.'
          } \
        do |package, _options|
          package_logo_path(package, locale: nil)
        end

        expose :size, documentation: {
            type: Integer,
            desc: 'Package file size in bytes'
          } \
        do |package, _options|
          package.file_size
        end

        expose :downloadCount, documentation: {
            type: Integer,
            desc: 'Download count'
          } \
        do |package, _options|
          package.download_count
        end
      end
    end
  end
end

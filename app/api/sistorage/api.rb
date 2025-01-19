module Sistorage
  class Api < Grape::API
    format :json

    mount V1::Api

    add_swagger_documentation \
      hide_documentation_path: false,
      info: {
        title: 'SIStorage compatible API of SIBrowser',
        description: <<~DESC,
          This API is based on https://github.com/VladimirKhil/SIStorage/wiki/Swagger-API
        DESC
        contact_name: 'Ilgiz Mustafin',
        contact_email: 'ilgimustafin@gmail.com',
        contact_url: 'https://imustafin.tatar'
      }
  end
end

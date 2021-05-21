require 'zip'

module Si
  class Package
    attr_accessor :name, :version, :authors

    def self.read_from_siq(zip_buffer)
      p = new

      Zip::File.open_buffer(zip_buffer) do |zip|
        content = Nokogiri::XML(zip.read('content.xml'))

        package = content.css('package').first

        p.authors = package.css('info authors author').map(&:text)
        p.name = package['name']
        p.version = package['version']
      end

      p
    end
  end
end

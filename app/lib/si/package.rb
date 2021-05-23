require 'zip'

module Si
  class Package
    def initialize(buffer)
      Zip::File.open_buffer(buffer) do |zip|
        @content = Nokogiri::XML(zip.read('content.xml'))
      end
    end

    def package
      @package ||= @content.css('package').first
    end

    def name
      package['name']
    end

    def authors
      package.css('> info authors author').map(&:text)
    end

    # Hash from round name to themes array
    def structure
      package.css('rounds round').map do |round|
        themes = round.css('themes theme').map { |x| x['name'] }

        [round['name'], themes]
      end.to_h
    end
  end
end

require 'zip'

module Si
  class Package
    def initialize(buffer)
      Zip::File.open_buffer(buffer) do |zip|
        @content = Nokogiri::XML(zip.read('content.xml'))

        if logo_file_path
          begin
            logo_path = "Images/#{Rack::Utils.escape(logo_file_path)}"
            tmp = Tempfile.new([File.basename(logo_file_path), File.extname(logo_file_path)])
            logo_file = tmp.path
            tmp.unlink
            zip.extract(logo_path, logo_file)
            convert_logo(logo_file)
          rescue e
            Sentry.capture_exception(e)
          end
        end
      end
    end

    def logo_file_path
      @logo_file_path ||= package['logo']&.delete_prefix('@')
    end

    IMAGE_EXT = 'webp'
    IMAGE_TYPE = 'image/webp'

    def convert_logo(logo_file)
      logo_file = ImageProcessing::Vips
        .source(logo_file)
        .resize_to_limit(600, 600)
        .convert('webp')
        .saver(quality: 75, lossless: false, min_size: true, strip: true)
        .call


      @logo_bytes = logo_file.read

      logo_image = Vips::Image.new_from_file(logo_file.path)
      @logo_width, @logo_height = logo_image.size
    end

    attr_reader :logo_bytes, :logo_width, :logo_height

    def package
      @package ||= @content.css('package').first
    end

    def name
      package['name']
    end

    def authors
      AuthorExtractor.extract(package.css('> info authors author').map(&:text))
    end

    # [i][j][k] = i-th round, j-th theme, k-th question { question_text, question_types, answers }
    def structure
      package.css('rounds round').map do |round|
        themes = round.css('themes theme').map do |theme|
          questions = theme.css('questions question').map do |q|
            question_text = q.css('scenario atom:not([type]), scenario atom[type=text]').map(&:text).join(' ')
            answers = q.css('right answer').map(&:text)
            question_types = q.css('scenario atom').map { |a| a['type'] || 'text' }

            {
              question_text: question_text,
              answers: answers,
              question_types: question_types # types of atoms in scenario
            }
          end

          {
            name: theme['name'],
            questions: questions
          }
        end

        {
          name: round['name'],
          themes: themes
        }
      end
    end

    def tags
      package.css('> tags tag').map(&:text).reject(&:empty?)
    end
  end
end

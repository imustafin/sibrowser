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
              question_types: question_types
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
      package.css('> tags tag').map(&:text)
    end
  end
end

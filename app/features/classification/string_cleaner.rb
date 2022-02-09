module Classification
  class StringCleaner
    def clean_string_from_package(package)
      ans = ''

      package.structure.each do |round|
        round['themes'].each do |theme|
          theme['questions'].each do |question|
            sentences = question['answers'] + [question['question_text']]

            clean_sentences(sentences).each { |s| ans << s << ' ' }
          end
        end
      end

      ans.strip
    end

    def clean_sentences(ar)
      ar
        .map(&method(:clean))
        .reject(&method(:has_foreign?))
    end

    def has_foreign?(s)
      ru = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя'
      en = 'abcdefghijklmnopqrstuvwxyz'
      space = ' '

      s =~ /[^#{ru + en + space}]/
    end

    def clean(s)
      s = s.downcase

      s.gsub!(/[^[[:alpha:]]]/, ' ') # remove all non-letters

      remove_scripts = %w[
        Hiragana
        Katakana
        Han
        Hangul
      ]

      scripts_re = Regexp
        .new('[' + remove_scripts.map { |s| '\p{' + s + '}' }.join + ']')

      s.gsub!(scripts_re, ' ')

      s
        .split
        .reject { |s| s.length < 2 || s.length > 10 }
        .join(' ')
    end
  end
end

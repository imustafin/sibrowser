module Si
  class AuthorExtractor
    class << self
      def extract(authors)
        authors.flat_map(&method(:process_string))
      end

      STOP_WORDS = [
        'редакторы:',
        'разработка игры:',
        'поддержка и тестирование:',
        'креативная идея:',
        'и',
        'при поддержке',
        'составитель -',
        'неизвестно,',
        'aka',
        'feat.',
        '&',
        'т.д',
        'a.k.',
        'a.k',
        'а.к.а',
        '|',
        '/',
        'and',
        'featuring',
        'скомпилировал'
      ]

      def split_regexps
        phrases = STOP_WORDS.map do |word|
          /(\s+|\A)#{Regexp.escape(word)}(\s+|\Z)/i
        end

        simple = [',', ';']

        [
          *phrases,
          *simple.map { |s| Regexp.new(Regexp.escape(s)) },
          /\.(\s+|\Z)/
        ]
      end

      def process_string(s)
        s = s.gsub(/\s+/, ' ')

        # Parentheses sanitization
        s = s.gsub(/\s+"\s+/, '"')
        s = s.gsub(/(\A[^"]*[^"\s+])"([^\s+])/, '\1 "\2')
        s = s.gsub(/([^\s+])"([^\s+()])/, '\1" \2')

        authors = [s]

        split_regexps.each do |r|
          authors = authors.flat_map { |a| a.split(r) }
        end

        authors.map(&:strip).reject(&:empty?)
      end
    end
  end
end

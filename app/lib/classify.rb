class Classify
  def self.print_params
    tags_to_cats = SibrowserConfig.instance.tags_to_cats || {}

    packages = []

    Package.find_in_batches do |group|
      group.each do |p|
        next unless p.structure

        p.structure.each_with_index do |round, round_id|
          round['themes'].each_with_index do |theme, theme_id|
            theme['questions'].each_with_index do |question, question_id|
              text = [question['question_text'], *question['answers']].reject(&:blank?).join('. ')
              cat = (p.manual_categories || {}).dig(round_id.to_s, theme_id.to_s, question_id.to_s)
              cat = nil unless SibrowserConfig::CATEGORIES.include?(cat)

              puts [text, cat, p.id, round_id, theme_id, question_id].to_json
            end
          end
        end
      end
    end
  end

  def initialize(existing = nil)
    @classifier = existing || ClassifierReborn::LSI.new(auto_rebuild: false)
  end

  def add(text, cats)
    @classifier.add_item(text, *cats) unless cats.empty?
  end

  def classify(text)
    @classifier.scored_categories(text)
  end

  def build
    @classifier.build_index
  end

  def dump
    Marshal.dump(@classifier)
  end

  def self.package_to_text(p)
    text = ''

    p.structure.each do |round|
      text += "\n\n" + round['name'] + ".\n\n"
      round['themes'].each do |theme|
        text += "\n\n" + theme['name'] + ".\n\n"
        theme['questions'].each do |question|
          text += question['question_text'] + '. '
          text += question['answers'].join(', ')
          text += "\n"
        end
      end
    end

    text
  end
end

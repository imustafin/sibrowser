class Classify
  def self.print_params
    tags_to_cats = SibrowserConfig.instance.tags_to_cats || {}

    packages = []

    Package.find_in_batches do |group|
      group.each do |p|
        next unless p.structure

        text = package_to_text(p)
        tags = p.tags.map(&:downcase).map(&:strip)

        cats = tags.map { |t| tags_to_cats[t] || [] }.flatten.uniq

        puts [p.id, package_to_text(p), cats].to_json
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

FactoryBot.define do
  factory :package do
    factory :package_one_theme do
      transient do
        questions { [] }
      end

      structure do
        [
          {
            'name' => 'The only Round',
            'themes' => [
              'name' => 'The only Theme',
              'questions' => questions
            ]
          }
        ]
      end
    end
  end
end

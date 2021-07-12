FactoryBot.define do
  sequence :vk_document_id do |n|
    n
  end

  factory :package do
    name { 'Package Name' }
    source_link { 'https://example.com/package.siq' }
    version { Package::VERSION }
    vk_document_id

    factory :package_one_theme do
      transient do
        questions { [] }
        theme { 'The only theme' }
        round { 'The only round' }
      end

      structure do
        [
          {
            'name' => round,
            'themes' => [
              'name' => theme,
              'questions' => questions
            ]
          }
        ]
      end
    end
  end
end

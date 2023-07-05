FactoryBot.define do
  sequence :file_hash do |n|
    n
  end

  factory :package do
    name { 'Package Name' }
    version { Package::VERSION }
    file_hash
    parsed_at { Time.current }
    vk_download_url_updated_at { Time.current }

    posts { [{}] }

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

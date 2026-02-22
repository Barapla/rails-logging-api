# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    active { true }

    # Asigna rol por defecto
    association :role, factory: :role, name: 'usuario'

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :with_confirmation_token do
      confirmation_token { SecureRandom.random_number(1000...9999) }
      confirmation_sent_at { Time.current }
    end

    trait :inactive do
      active { false }
    end
  end
end

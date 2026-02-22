# lib/tasks/permissions.rake
# frozen_string_literal: true

namespace :permissions do
  desc "Invalidar todo el cache de permisos"
  task invalidate_cache: :environment do
    puts "Invalidando cache de permisos..."
    Permissions::CacheService.invalidate_all
    puts "✓ Cache invalidado exitosamente"
  end

  desc "Precalentar cache de permisos para todos los usuarios activos"
  task warm_cache: :environment do
    puts "Precalentando cache de permisos..."

    User.where(active: true).find_each do |user|
      Permissions::CacheService.get_user_permissions(user.id)
      print "."
    end

    puts "\n✓ Cache precalentado exitosamente"
  end
end

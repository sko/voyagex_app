# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

admin = User.where(email: ADMIN_EMAIL_ADDRESS).first
unless admin.present?
  admin = User.rand_user
  admin.update_attributes email: ADMIN_EMAIL_ADDRESS, username: 'admin', password: 'd6du9jfgh3'
  admin.confirm!
end
initial_commit = Commit.first ||
                 # existing git-commit required
                 Commit.create(user: admin, hash_id: VersionManager.new(Poi::MASTER, Poi::WORK_DIR_ROOT, admin).cur_commit)
default_location ||= (Location.order(:id).first ||
                      Location.create(latitude: 51.3766024, longitude: 7.4940061, address: 'Hagen, Universitätsstraße, 1', commit: initial_commit))

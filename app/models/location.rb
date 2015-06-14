class Location < ActiveRecord::Base
  belongs_to :commit#, dependent: :destroy
  has_many :locations_users, dependent: :destroy
  has_many :users, through: :locations_users
  has_one :poi, inverse_of: :location, dependent: :destroy

  # Geocoder.search([l.latitude, l.longitude])
  reverse_geocoded_by :latitude, :longitude# do |obj, results|
#    if geo = results.first
#binding.pry
#      obj.city = geo.city
#      obj.zipcode = geo.postal_code
#      obj.country = geo.country_code
#    end
#  end
  after_validation :reverse_geocode
  #after_create :ensure_commit

  @@default_location = nil

  def self.default
    # a default location must be seeded
    @@default_location ||= Location.order(:id).first
  end

  # protected

  # def ensure_commit
  #   unless commit.present?
  #     dataJSON = { id: id, latitude: latitude, longitude: longitude, address: address }
  #     update_attribute :commit, Commit.create(user: User.admin, hash_id: Commit.generate_hash(dataJSON.to_json))
  #   end
  # end

end

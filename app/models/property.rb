class Property < ApplicationRecord
  # attr_accessor :id, :label, :slug_id, :contact_id
  belongs_to :slug
  belongs_to :contact
  has_many :appointments
  belongs_to :contract, optional: true
  mount_uploaders :images, ImagesUploader
end

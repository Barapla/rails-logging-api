class Catalog < ApplicationRecord
    include SoftDeletable
    belongs_to :group_catalog

    validates :value, presence: true
    validates :code, presence: true, uniqueness: { scope: :group_catalog_id }
    validates :group_catalog, presence: true

    scope :active, -> { where(active: true) }
end

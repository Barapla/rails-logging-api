class GroupCatalog < ApplicationRecord
    include SoftDeletable
    has_many :catalogs, dependent: :destroy
    has_many :statuses, dependent: :destroy

    validates :name, presence: true
    validates :code, presence: true, uniqueness: true

    scope :active, -> { where(active: true) }
end

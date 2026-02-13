class Status < ApplicationRecord
    belongs_to :group_catalog

    before_create :generate_uuid

    validates :name, presence: true
    validates :code, presence: true, uniqueness: { scope: :group_catalog_id }
    validates :uuid, uniqueness: true
    validates :group_catalog, presence: true

    scope :active, -> { where(active: true) }

    private

    def generate_uuid
        self.uuid ||= SecureRandom.uuid
    end
end

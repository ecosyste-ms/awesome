class Owner < ApplicationRecord
  has_many :projects

  validates :name, presence: true, uniqueness: true

  scope :visible, -> { where(hidden: false) }
  scope :hidden, -> { where(hidden: true) }

  before_validation :downcase_name
  after_save :clear_hidden_cache, if: :saved_change_to_hidden?

  private

  def downcase_name
    self.name = name&.downcase
  end

  def clear_hidden_cache
    Rails.cache.delete('hidden_owner_ids')
  end
end
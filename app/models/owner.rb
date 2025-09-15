class Owner < ApplicationRecord
  has_many :projects

  validates :name, presence: true, uniqueness: true

  scope :visible, -> { where(hidden: false) }
  scope :hidden, -> { where(hidden: true) }

  before_validation :downcase_name

  private

  def downcase_name
    self.name = name&.downcase
  end
end
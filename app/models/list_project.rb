class ListProject < ApplicationRecord
  belongs_to :list
  belongs_to :project
end

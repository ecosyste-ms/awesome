class AddCriticalPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Critical: topics.slug is queried 5.5M times with no index
    add_index :topics, :slug, unique: true

    # Topics filtering queries
    add_index :topics, :github_count

    # List queries frequently filter by list_of_lists
    add_index :lists, :list_of_lists

    # Projects frequently filtered by list boolean
    add_index :projects, :list

    # Composite index for common list_projects joins
    add_index :list_projects, [:list_id, :project_id], unique: true
  end
end

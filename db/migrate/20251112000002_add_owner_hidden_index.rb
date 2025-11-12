class AddOwnerHiddenIndex < ActiveRecord::Migration[8.0]
  def change
    # The visible_owners scope does: left_joins(:owner_record).where(owners: { hidden: [false, nil] })
    # This needs a partial index on owners.hidden
    # Already exists: add_index :owners, :hidden per schema.rb line 58

    # Add composite index for the join + filter pattern
    add_index :projects, [:owner_id, :last_synced_at],
              where: "owner_id IS NOT NULL"
  end
end

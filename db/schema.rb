# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_01_02_201648) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "list_projects", force: :cascade do |t|
    t.integer "list_id"
    t.integer "project_id"
    t.string "name"
    t.string "description"
    t.string "category"
    t.string "sub_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "lists", force: :cascade do |t|
    t.string "url"
    t.string "name"
    t.string "description"
    t.integer "projects_count"
    t.datetime "last_synced_at"
    t.json "repository"
    t.text "readme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "url"
    t.json "repository"
    t.text "readme"
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

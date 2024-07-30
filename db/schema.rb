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

ActiveRecord::Schema[7.1].define(version: 2024_07_30_154138) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_stat_statements"
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
    t.index ["list_id"], name: "index_list_projects_on_list_id"
    t.index ["project_id"], name: "index_list_projects_on_project_id"
  end

  create_table "lists", force: :cascade do |t|
    t.citext "url"
    t.string "name"
    t.string "description"
    t.integer "projects_count"
    t.datetime "last_synced_at"
    t.json "repository"
    t.text "readme"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "primary_language"
    t.boolean "list_of_lists", default: false
    t.boolean "displayable", default: false
    t.string "keywords", default: [], array: true
    t.integer "stars", default: 0
    t.index ["stars"], name: "index_lists_on_stars"
    t.index ["url"], name: "index_lists_on_url", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "url"
    t.json "repository"
    t.text "readme"
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "list", default: false
    t.integer "stars", default: 0
    t.index ["keywords"], name: "index_projects_on_keywords", using: :gin
    t.index ["stars"], name: "index_projects_on_stars"
    t.index ["url"], name: "index_projects_on_url", unique: true
  end

  create_table "topics", force: :cascade do |t|
    t.string "slug"
    t.string "name"
    t.string "short_description"
    t.string "url"
    t.integer "github_count"
    t.string "created_by"
    t.string "logo_url"
    t.string "released"
    t.string "wikipedia_url"
    t.string "related_topics", default: [], array: true
    t.string "aliases", default: [], array: true
    t.string "github_url"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end

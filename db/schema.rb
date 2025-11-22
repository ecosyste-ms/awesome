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

ActiveRecord::Schema[8.1].define(version: 2025_11_12_172132) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "list_projects", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "list_id"
    t.string "name"
    t.integer "project_id"
    t.string "sub_category"
    t.datetime "updated_at", null: false
    t.index ["list_id", "project_id"], name: "index_list_projects_on_list_id_and_project_id", unique: true
    t.index ["project_id"], name: "index_list_projects_on_project_id"
  end

  create_table "lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "displayable", default: false
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.boolean "list_of_lists", default: false
    t.string "name"
    t.string "primary_language"
    t.integer "projects_count"
    t.text "readme"
    t.json "repository"
    t.bigint "stars", default: 0
    t.datetime "updated_at", null: false
    t.citext "url"
    t.index ["displayable", "stars"], name: "index_lists_on_displayable_and_stars"
    t.index ["keywords"], name: "index_lists_on_keywords", using: :gin
    t.index ["list_of_lists"], name: "index_lists_on_list_of_lists"
    t.index ["stars"], name: "index_lists_on_stars"
    t.index ["url"], name: "index_lists_on_url", unique: true
  end

  create_table "owners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "hidden", default: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["hidden"], name: "index_owners_on_hidden"
    t.index ["name"], name: "index_owners_on_name", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "keywords", default: [], array: true
    t.datetime "last_synced_at"
    t.boolean "list", default: false
    t.string "owner"
    t.bigint "owner_id"
    t.text "readme"
    t.json "repository"
    t.bigint "stars", default: 0
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["keywords"], name: "index_projects_on_keywords", using: :gin
    t.index ["last_synced_at"], name: "index_projects_on_last_synced_at"
    t.index ["list", "stars"], name: "index_projects_on_list_and_stars"
    t.index ["owner"], name: "index_projects_on_owner"
    t.index ["owner_id", "last_synced_at"], name: "index_projects_on_owner_id_and_last_synced_at", where: "(owner_id IS NOT NULL)"
    t.index ["owner_id"], name: "index_projects_on_owner_id"
    t.index ["stars"], name: "index_projects_on_stars"
    t.index ["url"], name: "index_projects_on_url", unique: true
  end

  create_table "topics", force: :cascade do |t|
    t.string "aliases", default: [], array: true
    t.text "content"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.integer "github_count"
    t.string "github_url"
    t.string "logo_url"
    t.string "name"
    t.string "related_topics", default: [], array: true
    t.string "released"
    t.string "short_description"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "wikipedia_url"
    t.index ["github_count"], name: "index_topics_on_github_count"
    t.index ["slug"], name: "index_topics_on_slug", unique: true
  end

  add_foreign_key "projects", "owners"
end

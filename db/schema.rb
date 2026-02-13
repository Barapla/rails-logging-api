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

ActiveRecord::Schema[8.1].define(version: 2026_02_13_122729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "catalogs", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "group_catalog_id_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "value"
    t.index ["active"], name: "index_catalogs_on_active"
    t.index ["group_catalog_id_id"], name: "index_catalogs_on_group_catalog_id_id"
    t.index ["uuid"], name: "index_catalogs_on_uuid", unique: true
  end

  create_table "group_catalogs", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_group_catalogs_on_active"
    t.index ["uuid"], name: "index_group_catalogs_on_uuid", unique: true
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "exp"
    t.string "jti"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_jwt_denylists_on_active"
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
    t.index ["uuid"], name: "index_jwt_denylists_on_uuid", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_permissions_on_active"
    t.index ["uuid"], name: "index_permissions_on_uuid", unique: true
  end

  create_table "resources", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_resources_on_active"
    t.index ["uuid"], name: "index_resources_on_uuid", unique: true
  end

  create_table "role_permission_resources", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "resource_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_role_permission_resources_on_active"
    t.index ["permission_id"], name: "index_role_permission_resources_on_permission_id"
    t.index ["resource_id"], name: "index_role_permission_resources_on_resource_id"
    t.index ["role_id", "permission_id", "resource_id"], name: "idx_on_role_id_permission_id_resource_id_84702b9493", unique: true
    t.index ["role_id"], name: "index_role_permission_resources_on_role_id"
    t.index ["uuid"], name: "index_role_permission_resources_on_uuid", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_roles_on_active"
    t.index ["uuid"], name: "index_roles_on_uuid", unique: true
  end

  create_table "statuses", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "code"
    t.datetime "created_at", null: false
    t.bigint "group_catalogs_id", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_statuses_on_active"
    t.index ["group_catalogs_id"], name: "index_statuses_on_group_catalogs_id"
    t.index ["uuid"], name: "index_statuses_on_uuid", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "role_id_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id_id", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_user_roles_on_active"
    t.index ["role_id_id"], name: "index_user_roles_on_role_id_id"
    t.index ["user_id_id"], name: "index_user_roles_on_user_id_id"
    t.index ["uuid"], name: "index_user_roles_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.string "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uuid"], name: "index_users_on_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalogs", "group_catalogs", column: "group_catalog_id_id", name: "fk_catalogs_group_catalog"
  add_foreign_key "role_permission_resources", "permissions", name: "fk_role_permission_resources_permission"
  add_foreign_key "role_permission_resources", "resources", name: "fk_role_permission_resources_resource"
  add_foreign_key "role_permission_resources", "roles", name: "fk_role_permission_resources_role"
  add_foreign_key "statuses", "group_catalogs", column: "group_catalogs_id", name: "fk_statuses_group_catalogs"
  add_foreign_key "user_roles", "roles", column: "role_id_id", name: "fk_user_roles_role"
  add_foreign_key "user_roles", "users", column: "user_id_id", name: "fk_user_roles_user"
end

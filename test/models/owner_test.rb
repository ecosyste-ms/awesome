require 'test_helper'

class OwnerTest < ActiveSupport::TestCase
  test "should validate presence of name" do
    owner = Owner.new(hidden: false)
    assert_not owner.valid?
    assert_includes owner.errors[:name], "can't be blank"
  end

  test "should validate uniqueness of name" do
    Owner.create!(name: "test-owner")
    duplicate_owner = Owner.new(name: "test-owner")
    assert_not duplicate_owner.valid?
    assert_includes duplicate_owner.errors[:name], "has already been taken"
  end

  test "should have many projects" do
    assert_respond_to Owner.new, :projects
  end

  test "visible scope should return non-hidden owners" do
    visible_owner = Owner.create!(name: "visible-owner", hidden: false)
    hidden_owner = Owner.create!(name: "hidden-owner", hidden: true)

    visible_owners = Owner.visible
    assert_includes visible_owners, visible_owner
    assert_not_includes visible_owners, hidden_owner
  end

  test "hidden scope should return hidden owners" do
    visible_owner = Owner.create!(name: "visible-owner", hidden: false)
    hidden_owner = Owner.create!(name: "hidden-owner", hidden: true)

    hidden_owners = Owner.hidden
    assert_includes hidden_owners, hidden_owner
    assert_not_includes hidden_owners, visible_owner
  end

  test "default hidden value should be false" do
    owner = Owner.new(name: "test-owner")
    assert_equal false, owner.hidden
  end

  test "should downcase name before validation" do
    owner = Owner.create!(name: "TestOwner")
    assert_equal "testowner", owner.name
  end

  test "should handle mixed case names in uniqueness validation" do
    Owner.create!(name: "testowner")
    duplicate_owner = Owner.new(name: "TestOwner")
    assert_not duplicate_owner.valid?
    assert_includes duplicate_owner.errors[:name], "has already been taken"
  end

  test "should handle nil name in downcase callback" do
    owner = Owner.new(name: nil)
    assert_not owner.valid?
    assert_nil owner.name
  end
end
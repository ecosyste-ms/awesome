require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "should return 404 when project owner is hidden" do
    hidden_owner = create(:owner, :hidden)
    project = create(:project, owner_record: hidden_owner)

    get project_path(project.slug)
    assert_response :not_found
  end

  test "should show project when owner is visible" do
    visible_owner = create(:owner)
    project = create(:project, owner_record: visible_owner)

    get project_path(project.slug)
    assert_response :success
  end

  test "should show project when no owner_record" do
    project = create(:project, owner_record: nil)

    get project_path(project.slug)
    assert_response :success
  end

  test "index should exclude projects with hidden owners" do
    hidden_owner = create(:owner, :hidden)
    visible_owner = create(:owner)

    hidden_project = create(:project, owner_record: hidden_owner, last_synced_at: 1.hour.ago, repository: { "name" => "hidden" })
    visible_project = create(:project, owner_record: visible_owner, last_synced_at: 1.hour.ago, repository: { "name" => "visible" })

    get projects_path
    assert_response :success

    assert_not_includes assigns(:projects), hidden_project
    assert_includes assigns(:projects), visible_project
  end

  test "should return 404 when filtering by hidden owner" do
    hidden_owner = create(:owner, name: "hidden-owner", hidden: true)

    get projects_path(owner: "hidden-owner")
    assert_response :not_found
  end

  test "should return projects when filtering by visible owner" do
    visible_owner = create(:owner, name: "visible-owner")
    project = create(:project, owner: "visible-owner", owner_record: visible_owner, last_synced_at: 1.hour.ago, repository: { "name" => "test" })

    get projects_path(owner: "visible-owner")
    assert_response :success
    assert_includes assigns(:projects), project
  end

  test "should handle case-insensitive owner filtering" do
    visible_owner = create(:owner, name: "testowner")
    project = create(:project, owner: "TestOwner", owner_record: visible_owner, last_synced_at: 1.hour.ago, repository: { "name" => "test" })

    get projects_path(owner: "TestOwner")
    assert_response :success
    assert_includes assigns(:projects), project
  end

  test "should return 404 for hidden owner with different case" do
    hidden_owner = create(:owner, name: "hiddenowner", hidden: true)

    get projects_path(owner: "HiddenOwner")
    assert_response :not_found
  end
end
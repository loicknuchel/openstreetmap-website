require "test_helper"

class UserRolesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/user/username/role/rolename/grant", :method => :post },
      { :controller => "user_roles", :action => "grant", :display_name => "username", :role => "rolename" }
    )
    assert_routing(
      { :path => "/user/username/role/rolename/revoke", :method => :post },
      { :controller => "user_roles", :action => "revoke", :display_name => "username", :role => "rolename" }
    )
  end

  ##
  # test the grant action
  def test_grant
    target_user = create(:user)
    normal_user = create(:user)
    administrator_user = create(:administrator_user)
    super_user = create(:super_user)

    # Granting should fail when not logged in
    post grant_role_path(target_user, "moderator")
    assert_response :forbidden

    # Login as an unprivileged user
    session_for(normal_user)

    # Granting should still fail
    post grant_role_path(target_user, "moderator")
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Login as an administrator
    session_for(administrator_user)

    UserRole::ALL_ROLES.each do |role|
      # Granting a role to a non-existent user should fail
      assert_difference "UserRole.count", 0 do
        post grant_role_path("non_existent_user", role)
      end
      assert_response :not_found
      assert_template "users/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Granting a role to a user that already has it should fail
      assert_no_difference "UserRole.count" do
        post grant_role_path(super_user, role)
      end
      assert_redirected_to user_path(super_user)
      assert_equal "The user already has role #{role}.", flash[:error]

      # Granting a role to a user that doesn't have it should work...
      assert_difference "UserRole.count", 1 do
        post grant_role_path(target_user, role)
      end
      assert_redirected_to user_path(target_user)

      # ...but trying a second time should fail
      assert_no_difference "UserRole.count" do
        post grant_role_path(target_user, role)
      end
      assert_redirected_to user_path(target_user)
      assert_equal "The user already has role #{role}.", flash[:error]
    end

    # Granting a non-existent role should fail
    assert_difference "UserRole.count", 0 do
      post grant_role_path(target_user, "no_such_role")
    end
    assert_redirected_to user_path(target_user)
    assert_equal "The string 'no_such_role' is not a valid role.", flash[:error]
  end

  ##
  # test the revoke action
  def test_revoke
    target_user = create(:user)
    normal_user = create(:user)
    administrator_user = create(:administrator_user)
    super_user = create(:super_user)

    # Revoking should fail when not logged in
    post revoke_role_path(target_user, "moderator")
    assert_response :forbidden

    # Login as an unprivileged user
    session_for(normal_user)

    # Revoking should still fail
    post revoke_role_path(target_user, "moderator")
    assert_redirected_to :controller => :errors, :action => :forbidden

    # Login as an administrator
    session_for(administrator_user)

    UserRole::ALL_ROLES.each do |role|
      # Removing a role from a non-existent user should fail
      assert_difference "UserRole.count", 0 do
        post revoke_role_path("non_existent_user", role)
      end
      assert_response :not_found
      assert_template "users/no_such_user"
      assert_select "h1", "The user non_existent_user does not exist"

      # Removing a role from a user that doesn't have it should fail
      assert_no_difference "UserRole.count" do
        post revoke_role_path(target_user, role)
      end
      assert_redirected_to user_path(target_user)
      assert_equal "The user does not have role #{role}.", flash[:error]

      # Removing a role from a user that has it should work...
      assert_difference "UserRole.count", -1 do
        post revoke_role_path(super_user, role)
      end
      assert_redirected_to user_path(super_user)

      # ...but trying a second time should fail
      assert_no_difference "UserRole.count" do
        post revoke_role_path(super_user, role)
      end
      assert_redirected_to user_path(super_user)
      assert_equal "The user does not have role #{role}.", flash[:error]
    end

    # Revoking a non-existent role should fail
    assert_difference "UserRole.count", 0 do
      post revoke_role_path(target_user, "no_such_role")
    end
    assert_redirected_to user_path(target_user)
    assert_equal "The string 'no_such_role' is not a valid role.", flash[:error]

    # Revoking administrator role from current user should fail
    post revoke_role_path(administrator_user, "administrator")
    assert_redirected_to user_path(administrator_user)
    assert_equal "Cannot revoke administrator role from current user.", flash[:error]
  end
end

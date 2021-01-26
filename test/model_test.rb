# frozen_string_literal: true

require "test_helper"

module ActiveStorageAliyun
  class ModelTest < ActionDispatch::IntegrationTest
    test "service_name" do
      u = User.new(avatar: fixture_file_upload("foo.jpg"))
      assert_equal "aliyun", u.avatar.blob.service_name

      u = User.new(files: [fixture_file_upload("foo.jpg")])
      assert_equal "aliyun", u.files.first.blob.service_name
    end
  end
end

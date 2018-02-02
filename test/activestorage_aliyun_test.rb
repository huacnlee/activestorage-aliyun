# frozen_string_literal: true

require "active_support/core_ext/securerandom"
require "activestorage-aliyun"
require "test_helper"

class ActiveStorageAliyun::Test < ActiveSupport::TestCase
  FIXTURE_KEY   = SecureRandom.base58(24)
  FIXTURE_DATA  = "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020\000\000\000\020\001\003\000\000\000%=m\"\000\000\000\006PLTE\000\000\000\377\377\377\245\331\237\335\000\000\0003IDATx\234c\370\377\237\341\377_\206\377\237\031\016\2603\334?\314p\1772\303\315\315\f7\215\031\356\024\203\320\275\317\f\367\201R\314\f\017\300\350\377\177\000Q\206\027(\316]\233P\000\000\000\000IEND\256B`\202".dup.force_encoding(Encoding::BINARY)
  ALIYUN_CONFIG = {
    aliyun: {
      service: "Aliyun",
      access_key_id: ENV["ALIYUN_ACCESS_KEY_ID"],
      access_key_secret: ENV["ALIYUN_ACCESS_KEY_SECRET"],
      bucket: ENV["ALIYUN_BUCKET"],
      endpoint: ENV["ALIYUN_ENDPOINT"],
      path: "activestorage-aliyun-test"
    }
  }

  def fixure_url_for(path)
    filename = CGI.escape(["activestorage-aliyun-test", path].join("/"))
    host = ENV["ALIYUN_ENDPOINT"].gsub("://", "://#{ENV["ALIYUN_BUCKET"]}.")
    "#{host}/#{filename}"
  end

  setup do
    @service = ActiveStorage::Service.configure(:aliyun, ALIYUN_CONFIG)
    @service.upload FIXTURE_KEY, StringIO.new(FIXTURE_DATA)
  end

  teardown do
    @service.delete FIXTURE_KEY
  end

  test "get url" do
    assert_equal fixure_url_for(FIXTURE_KEY), @service.url(FIXTURE_KEY, expires_in: 500, filename: "foo.jpg", content_type: "image/jpeg", disposition: :inline)
    assert_equal fixure_url_for(FIXTURE_KEY) + "?x-oss-process=image/resize,h_100,w_100", @service.url(FIXTURE_KEY, expires_in: 500, content_type: "image/jpeg", disposition: :inline, filename: "x-oss-process=image/resize,h_100,w_100")
  end

  test "uploading with integrity" do
    begin
      key  = SecureRandom.base58(24)
      data = "Something else entirely!"
      @service.upload(key, StringIO.new(data), checksum: Digest::MD5.base64digest(data))

      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end

  test "downloading" do
    assert_equal FIXTURE_DATA, @service.download(FIXTURE_KEY)
  end

  test "downloading in chunks" do
    chunks = []

    @service.download(FIXTURE_KEY) do |chunk|
      chunks << chunk
    end

    assert_equal [ FIXTURE_DATA ], chunks
  end

  test "existing" do
    assert @service.exist?(FIXTURE_KEY)
    assert_not @service.exist?(FIXTURE_KEY + "nonsense")
  end

  test "deleting" do
    @service.delete FIXTURE_KEY
    assert_not @service.exist?(FIXTURE_KEY)
  end

  test "deleting nonexistent key" do
    assert_nothing_raised do
      @service.delete SecureRandom.base58(24)
    end
  end

  test "deleting by prefix" do
    begin
      @service.upload("a/a/a", StringIO.new(FIXTURE_DATA))
      @service.upload("a/a/b", StringIO.new(FIXTURE_DATA))
      @service.upload("a/b/a", StringIO.new(FIXTURE_DATA))

      @service.delete_prefixed("a/a/")
      assert_not @service.exist?("a/a/a")
      assert_not @service.exist?("a/a/b")
      assert @service.exist?("a/b/a")
    ensure
      @service.delete("a/a/a")
      @service.delete("a/a/b")
      @service.delete("a/b/a")
    end
  end

  test "headers_for_direct_upload" do
    key          = "test-file"
    data         = "Something else entirely!"
    checksum     = Digest::MD5.base64digest(data)
    content_type = "text/plain"
    date         = "Fri, 02 Feb 2018 06:45:25 GMT"

    travel_to Time.parse(date) do
      headers  = @service.headers_for_direct_upload(key, expires_in: 5.minutes, content_type: content_type, content_length: data.size, checksum: checksum)
      assert_equal date, headers["x-oss-date"]
      assert_equal "text/plain", headers["Content-Type"]
      assert_equal checksum, headers["Content-MD5"]
      assert headers["Authorization"].start_with?("OSS #{ENV["ALIYUN_ACCESS_KEY_ID"]}:")
    end
  end

  test "direct upload" do
    begin
      key      = SecureRandom.base58(24)
      data     = "Something else entirely!"
      checksum = Digest::MD5.base64digest(data)
      url      = @service.url_for_direct_upload(key, expires_in: 5.minutes, content_type: "text/plain", content_length: data.size, checksum: checksum)
      assert_equal fixure_url_for(key), url

      headers  = @service.headers_for_direct_upload(key, expires_in: 5.minutes, content_type: "text/plain", content_length: data.size, checksum: checksum)

      uri = URI.parse url
      request = Net::HTTP::Put.new uri.request_uri
      request.body = data
      headers.each_key do |key|
        request.add_field key, headers[key]
      end
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request request
      end

      assert_equal data, @service.download(key)
    ensure
      @service.delete key
    end
  end
end

# frozen_string_literal: true

require "active_support/core_ext/securerandom"
require "activestorage-aliyun"
require "test_helper"
require "open-uri"

class ActiveStorageAliyun::Test < ActiveSupport::TestCase
  FIXTURE_KEY   = SecureRandom.base58(24)
  FIXTURE_DATA  = "\211PNG\r\n\032\n\000\000\000\rIHDR\000\000\000\020\000\000\000\020\001\003\000\000\000%=m\"\000\000\000\006PLTE\000\000\000\377\377\377\245\331\237\335\000\000\0003IDATx\234c\370\377\237\341\377_\206\377\237\031\016\2603\334?\314p\1772\303\315\315\f7\215\031\356\024\203\320\275\317\f\367\201R\314\f\017\300\350\377\177\000Q\206\027(\316]\233P\000\000\000\000IEND\256B`\202".dup.force_encoding(Encoding::BINARY)
  ALIYUN_CONFIG = {
    aliyun: {
      service: "Aliyun",
      access_key_id: ENV["ALIYUN_ACCESS_KEY_ID"],
      access_key_secret: ENV["ALIYUN_ACCESS_KEY_SECRET"],
      bucket: "carrierwave-aliyun-test",
      endpoint: "https://oss-cn-beijing.aliyuncs.com",
      path: "activestorage-aliyun-test",
      public: true
    }
  }
  ALIYUN_PRIVATE_CONFIG = {
    aliyun: {
      service: "Aliyun",
      access_key_id: ENV["ALIYUN_ACCESS_KEY_ID"],
      access_key_secret: ENV["ALIYUN_ACCESS_KEY_SECRET"],
      bucket: "carrierwave-aliyun-test",
      endpoint: "https://oss-cn-beijing.aliyuncs.com",
      path: "/activestorage-aliyun-test",
      public: false
    }
  }

  def content_disposition_with(type, filename)
    @service.send(:content_disposition_with, type: type, filename: ActiveStorage::Filename.wrap(filename))
  end

  def fixure_url_for(path)
    filename_key = File.join("activestorage-aliyun-test", path)
    host = ALIYUN_CONFIG[:aliyun][:endpoint].sub("://", "://#{ALIYUN_CONFIG[:aliyun][:bucket]}.")

    "#{host}/#{filename_key}"
  end

  def download_url_for(path, filename: nil, content_type: nil, disposition:, params: {})
    host_url = fixure_url_for(path)

    params["response-content-type"] = content_type if content_type
    params["response-content-disposition"] = content_disposition_with(disposition, filename) if filename

    "#{host_url}?#{params.to_query}"
  end

  setup do
    @service = ActiveStorage::Service.configure(:aliyun, ALIYUN_CONFIG)
    @private_service = ActiveStorage::Service.configure(:aliyun, ALIYUN_PRIVATE_CONFIG)

    @service.upload FIXTURE_KEY, StringIO.new(FIXTURE_DATA)
  end

  teardown do
    @service.delete FIXTURE_KEY
  end

  def mock_service_with_path(path)
    ActiveStorage::Service.configure(:aliyun,
      aliyun: { service: "Aliyun", path: path }
    )
  end

  test "path_for" do
    service = mock_service_with_path("/")
    assert_equal "foo/bar", service.send(:path_for, "foo/bar")

    service = mock_service_with_path("")
    assert_equal "foo/bar", service.send(:path_for, "/foo/bar")

    service = mock_service_with_path("/hello/world")
    assert_equal "hello/world/foo/bar", service.send(:path_for, "/foo/bar")

    service = mock_service_with_path("hello//world")
    assert_equal "hello/world/foo/bar", service.send(:path_for, "foo/bar")
  end

  test "get url for public mode" do
    url = @service.url(FIXTURE_KEY)
    assert_equal fixure_url_for(FIXTURE_KEY), url

    res = open(url)
    assert_equal ["200", "OK"], res.status

    url = @service.url(FIXTURE_KEY, params: {
      "x-oss-process": "image/resize,h_100,w_100"
    })
    assert_equal fixure_url_for(FIXTURE_KEY) + "?x-oss-process=image%2Fresize%2Ch_100%2Cw_100", url

    res = open(url)
    assert_equal ["200", "OK"], res.status

    url = @service.url(FIXTURE_KEY, filename: "foo.jpg", content_type: "image/jpeg", disposition: :attachment)
    assert_equal true, url.include?("response-content-type=image%2Fjpeg")
    assert_equal true, url.include?("response-content-disposition=attachment")

    res = open(url)
    assert_equal ["200", "OK"], res.status
  end

  test "get private mode url" do
    url = @private_service.url(FIXTURE_KEY, expires_in: 500, content_type: "image/png", disposition: :inline, filename: "foo.jpg")
    assert_equal true, url.include?("Signature=")
    assert_equal true, url.include?("OSSAccessKeyId=")
    assert_equal true, url.include?("response-content-disposition=inline")
    assert_equal true, url.include?("response-content-type=image%2Fpng")
    res = open(url)
    assert_equal ["200", "OK"], res.status
    assert_equal FIXTURE_DATA, res.read

    url = @private_service.url(FIXTURE_KEY, expires_in: 500, content_type: "image/png", disposition: :inline, params: { "x-oss-process" => "image/resize,h_100,w_100" })
    assert_equal true, url.include?("x-oss-process=")
    assert_equal true, url.include?("Signature=")
    assert_equal true, url.include?("OSSAccessKeyId=")
    assert_equal true, url.include?("response-content-type=image%2Fpng")
    assert_equal false, url.include?("response-content-disposition=")
    res = open(url)
    assert_equal ["200", "OK"], res.status
  end

  test "get url with oss image thumb" do
    url = @service.url(FIXTURE_KEY, params: { "x-oss-process" => "image/resize,h_100,w_100" })
    assert_equal fixure_url_for(FIXTURE_KEY) + "?x-oss-process=image%2Fresize%2Ch_100%2Cw_100", url
    res = open(url)

    assert_equal ["200", "OK"], res.status
  end

  test "get url with string :filename" do
    filename = "Test 中文 [100].zip"
    url = @service.url(FIXTURE_KEY, content_type: "image/jpeg", disposition: :attachment, filename: filename)
    res = open(url)

    assert_equal ["200", "OK"], res.status
    assert_equal "image/jpeg", res.content_type
    assert_equal "attachment; filename=\"Test %3F%3F %5B100%5D.zip\"; filename*=UTF-8''Test%20%E4%B8%AD%E6%96%87%20%5B100%5D.zip", res.meta["content-disposition"]
  end

  test "get url with attachment type disposition" do
    filename = ActiveStorage::Filename.new("Test 中文 [100].zip")
    url = @service.url(FIXTURE_KEY, expires_in: 500, content_type: "image/jpeg", disposition: :attachment, filename: filename)
    res = open(url)

    assert_equal ["200", "OK"], res.status
    assert_equal "image/jpeg", res.content_type
    assert_equal "attachment; filename=\"Test %3F%3F %5B100%5D.zip\"; filename*=UTF-8''Test%20%E4%B8%AD%E6%96%87%20%5B100%5D.zip", res.meta["content-disposition"]
  end

  test "get url with empty content-type" do
    filename = ActiveStorage::Filename.new("Test 中文 [100].zip")
    url = @service.url(FIXTURE_KEY, expires_in: 500, content_type: "", disposition: :attachment, filename: filename)
    assert_no_match "response-content-type", url
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
    assert_equal FIXTURE_DATA, @private_service.download(FIXTURE_KEY)
    assert_equal FIXTURE_DATA, @service.download(FIXTURE_KEY)
  end

  test "downloading in chunks" do
    chunks = []

    @service.download(FIXTURE_KEY) do |chunk|
      chunks << chunk
    end

    assert_equal [ FIXTURE_DATA ], chunks
  end

  test "downloading chunk" do
    chunk = @service.download_chunk(FIXTURE_KEY, 0..8)
    assert_equal 9, chunk.length
    assert_equal FIXTURE_DATA[0..8], chunk

    # exclude end
    chunk = @service.download_chunk(FIXTURE_KEY, 0...8)
    assert_equal 8, chunk.length
    assert_equal FIXTURE_DATA[0...8], chunk

    chunk = @service.download_chunk(FIXTURE_KEY, 10...15)
    assert_equal 5, chunk.length
    assert_equal FIXTURE_DATA[10..14], chunk
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
      headers = @service.headers_for_direct_upload(key, expires_in: 5.minutes, content_type: content_type, content_length: data.size, checksum: checksum)
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

      headers = @service.headers_for_direct_upload(key, expires_in: 5.minutes, content_type: "text/plain", content_length: data.size, checksum: checksum)

      uri = URI.parse url
      request = Net::HTTP::Put.new uri.request_uri
      request.body = data
      headers.each_key do |field|
        request.add_field field, headers[field]
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

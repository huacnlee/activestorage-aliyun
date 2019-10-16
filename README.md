# ActiveStorage Aliyun Service

Wraps the Aliyun OSS as an Active Storage service, use [Aliyun official Ruby SDK](https://github.com/aliyun/aliyun-oss-ruby-sdk) for upload.


[![Gem Version](https://badge.fury.io/rb/activestorage-aliyun.svg)](https://badge.fury.io/rb/activestorage-aliyun) [![Build Status](https://travis-ci.org/huacnlee/activestorage-aliyun.svg)](https://travis-ci.org/huacnlee/activestorage-aliyun) [![Code Climate](https://codeclimate.com/github/huacnlee/activestorage-aliyun/badges/gpa.svg)](https://codeclimate.com/github/huacnlee/activestorage-aliyun) [![codecov.io](https://codecov.io/github/huacnlee/activestorage-aliyun/coverage.svg?branch=master)](https://codecov.io/github/huacnlee/activestorage-aliyun?branch=master)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activestorage-aliyun'
```

And then execute:

```bash
$ bundle
```

## Usage

config/storage.yml

```yml
aliyun:
  service: Aliyun
  access_key_id: "your-oss-access-key-id"
  access_key_secret: "your-oss-access-key-secret"
  bucket: "bucket-name"
  endpoint: "https://oss-cn-beijing.aliyuncs.com"
  # path prefix, default: /
  path: "my-app-files"
  # Bucket public: true/false, default: true, for generate public/private URL.
  public: true
```

### Custom Domain

```yml
aliyun:
  service: Aliyun
  access_key_id: "your-oss-access-key-id"
  access_key_secret: "your-oss-access-key-secret"
  bucket: "bucket-name"
  endpoint: "https://file.myhost.com"
  public: false
  # Enable cname to use custom domain
  cname: true
```

### Use for image url

```erb
Original File URL:

<%= image_tag @photo.image.service_url %>
```

Thumb with OSS image service:

```rb
class Photo < ApplicationRecord
  def image_thumb_url(process)
    self.image.service_url(params: { "x-oss-process" => process })
  end
end
```

And then:

```erb
<%= image_tag @photo.image.image_thumb_url("image/resize,h_100,w_100") %>
```

### Use for file download

If you want to get original filename (Include Chinese and other UTF-8 chars), for example: `演示文件 download.zip`, you need present `disposition: :attachment` option.

```erb
#
<%= image_tag @photo.image.service_url(disposition: :attachment) %>
```

## Contributing

### Run test

```bash
$ bin/test test/activestorage_aliyun_test.rb
# run a line
$ bin/test test/activestorage_aliyun_test.rb:129
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

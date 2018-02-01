# ActiveStorage Aliyun Service

Wraps the Aliyun OSS as an Active Storage service.

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

```rb
production:
  service: Aliyun
  access_key_id: "your-oss-access-key-id"
  access_key_secret: "your-oss-access-key-secret"
  bucket: "bucket-name"
  endpoint: "https://oss-cn-beijing.aliyuncs.com"
  # path prefix, default: /
  path: "my-app-files"
```

Use image:

```erb
- Orignial File URL: <%= image_tag @photo.image.service_url %>
- Thumb with OSS image service: <%= image_tag @photo.image.service_url(filename: 'x-oss-process=image/resize,h_100,w_100') %>
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

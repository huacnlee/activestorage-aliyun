## 1.0.0

- Update for support Rals 6.1 permanent URL, and compatiable with Rails 6.0.
- `mode` config has deprecated, use `public: true` instead.

## 0.6.4

- Fix public url generate issue. #37

## 0.6.3

- Enable chunk (2m each) upload, for imporve the big files upload performance. #35

## 0.6.2

- Fix service_url generate to includes the content-disposition and filename with the `disposition: :inline` mode.
  This fix for PDF inline case, to keeps the origianal filename when user do save as.

## 0.6.1

- Fix signature issue when content-type is empty.

## 0.6.0

- Fix upload method option for Rails 5.2.1.1
- Fix signature issue when config path is / #20

## 0.5.1

- Set OSS Object `content-type` on uploading.

## 0.5.0

- Implement download_chunk method for fix #10 upload a large file by directly.

## 0.4.1

- Remove config.path `/` prefix for fix #7 issue.

## 0.4.0

- Support present `params` to `service_url` to oss image url.

for example:

```rb
@photo.image.service_url(params: { 'x-oss-process' => "image/resize,h_100,w_100" })
```

## 0.3.0

- Add `mode` config for setup OSS ACL, `mode: "private"` will always output URL that have signature info.
- Support `disposition: :attachment` option for `service_url` method for download original filename.

## 0.2.0

- Add url_for_direct_upload support.
- Fix delete_prefixed error when path not exists.

## 0.1.1

- Fix streaming upload.
- Fix delete by prefixed.
- Add full test.

## 0.1.0

- First release.

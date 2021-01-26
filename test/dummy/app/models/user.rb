class User < ApplicationRecord
  has_one_attached :avatar, service: :aliyun
  has_many_attached :files, service: :aliyun
end

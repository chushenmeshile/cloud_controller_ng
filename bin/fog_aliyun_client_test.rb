#!/usr/bin/env ruby

require File.expand_path('../config/boot', __dir__)

require 'cloud_controller'
require 'steno'
require 'cloud_controller/blobstore/fog/fog_client'
require 'cloud_controller/steno_configurer'

module VCAP::CloudController
  module Blobstore
    @log_counter = Steno::Sink::Counter.new
    @logger ||= Steno.logger('cc.runner')
    logconf = {
        level: "debug"
    }
    StenoConfigurer.new(logconf).configure do |steno_config_hash|
      steno_config_hash[:sinks] << @log_counter
    end
    bucket_name = ENV["aliyun_oss_bucket"]
    aliyun_accesskey_id = ENV["aliyun_accesskey_id"]
    aliyun_accesskey_secret = ENV["aliyun_accesskey_secret"]
    aliyun_region_id = ENV["aliyun_region_id"]
    opt = {
        provider: 'Aliyun',
        aliyun_accesskey_id: aliyun_accesskey_id,
        aliyun_accesskey_secret: aliyun_accesskey_secret,
        aliyun_oss_bucket: bucket_name,
        aliyun_region_id: aliyun_region_id,
    }
    # Fog client targeting root folder of bucket
    # ------------------------------------------
    # Fog client 指向bucket的根目录
    root_client = CloudController::Blobstore::FogClient.new(
        connection_config: opt,
        directory_key: bucket_name,
        cdn: nil,
        root_dir: nil,
        min_size: 0,
        max_size: 999999,
        storage_options: {},
        )


    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586b')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586c')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '026cdf95-7228-40a3-995a-cf94ce68586b')
    # local
    p root_client.local?
    # exists  判断文件是否存在
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '026cdf95-7228-40a3-995a-cf94ce68586b')
    p root_client.exists?("026cdf95-7228-40a3-995a-cf94ce68586b")
    #download_from_blobstore  下载文件 mode 修改文件权限
    root_client.download_from_blobstore("026cdf95-7228-40a3-995a-cf94ce68586b","1.txt",mode: 0777)
    #cp_r_to_blobstore 上传目录中的文件
    root_client.cp_r_to_blobstore("bin/dir1/")
    #cp_file_between_keys  两个文件之间copy
    root_client.cp_file_between_keys('016cdf95-7228-40a3-995a-cf94ce68586b','026cdf95-7228-40a3-995a-cf94ce68586b')
    #delete_all 删除所有文件
    root_client.delete_all
    #delete 删除指定文件
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586b')
    root_client.delete("016cdf95-7228-40a3-995a-cf94ce68586b")
    #blob,delete_blob
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586b')
    blob=root_client.blob("016cdf95-7228-40a3-995a-cf94ce68586b")
    root_client.delete_blob(blob)
    #files_for
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586c')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '026cdf95-7228-40a3-995a-cf94ce68586b')
    files=root_client.files_for("01")
    p files.size
    #root_dir
    p root_client.root_dir




    @logger.info("Finished")

  end
end

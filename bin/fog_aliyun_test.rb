#!/usr/bin/env ruby

require File.expand_path('../config/boot', __dir__)

require 'cloud_controller'
require 'steno'
require 'cloud_controller/blobstore/fog/fog_client'
require 'cloud_controller/steno_configurer'

module VCAP::CloudController
  module Blobstore

    # Configure CC Logger
    # ------------------------------------------
    # 配置CC记录器
    @log_counter = Steno::Sink::Counter.new
    @logger ||= Steno.logger('cc.runner')

    logconf = {
        level: "debug"
    }

    StenoConfigurer.new(logconf).configure do |steno_config_hash|
      steno_config_hash[:sinks] << @log_counter
    end

    # !! CHANGE ME !!
    # Bucket connection information 
    # ------------------------------------------
    # Bucket 连接信息， 修改成自己的信息，而不是用我的配置信息。例如：accesskey id 要修改成你的key id。否则连接会出现问题。
    BUCKET_NAME = 'YOUR_BUCKET_NAME'
    opt = {
        provider: 'Aliyun',
        aliyun_accesskey_id: 'YOUR_ACCESS_KEY',
        aliyun_accesskey_secret: 'YOUR_ACCESS_SECRET',
        aliyun_oss_bucket: BUCKET_NAME,
        aliyun_region_id: 'eu-central-1',
    }

    # Fog client targeting root folder of bucket
    # ------------------------------------------
    # Fog client 指向bucket的根目录
    root_client = CloudController::Blobstore::FogClient.new(
        connection_config: opt,
        directory_key: BUCKET_NAME,
        cdn: nil,
        root_dir: nil,
        min_size: 0,
        max_size: 999999,
        storage_options: {},
    )

    # Fog client targeting buildpack_cache subfolder of bucket
    # This is how CC does it internally so we use this config found trough debugging the code.
    # ------------------------------------------
    # Fog client 指向bucket的buildpack_cache的子文件夹，这是CC内部做的，但是我们用这个配置来debug code。
    blobstorecache_client = CloudController::Blobstore::FogClient.new(
        connection_config: opt,
        directory_key: BUCKET_NAME,
        cdn: nil,
        root_dir: 'buildpack_cache',
        min_size: 0,
        max_size: 999999,
        storage_options: {},
    )

    # Upload some files to the Buckets root folder (gets saved in subfolders according to first 4 letters of filename)
    # ------------------------------------------
    # 上传一些文件到bucket的根目录（根据文件的前4个字母，将文件存在子目录里，如果不清楚，请看下面的结构）
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586b')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586c')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '026cdf95-7228-40a3-995a-cf94ce68586b')

    # Save some file in blobstore_cache subfolder (gets saved in subfolders according to first 4 letters of filename)
    # -------------------------------------------------
    # 保存一些文件在blobstore_cache 的子目录（根据文件的前4个字母，将文件保存在子目录，如果不清楚，请看下面的结构）
    blobstorecache_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '926cdf95-7228-40a3-995a-cf94ce68586b/myfile')
    blobstorecache_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '926cdf95-7228-40a3-995a-cf94ce68586b/myfile2')
    blobstorecache_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', 'abcddf95-7228-40a3-995a-cf94ce68586b/myfile')
    blobstorecache_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', 'abcddf95-7228-40a3-995a-cf94ce68586b/myfile2')

    # We now have following structure inside the bucket:
    # 现在bucket的结构如下所示：
    # --------------------------------------------------
    # BUCKET:
    # - 01
    # |    | 6c
    # |        | 016cdf95-7228-40a3-995a-cf94ce68586b
    #          | 016cdf95-7228-40a3-995a-cf94ce68586c
    # - 02
    # |    | 6c
    # |        | 026cdf95-7228-40a3-995a-cf94ce68586b
    # - buildpack_cache
    # |    | 92
    # |        | 6c
    # |            | 926cdf95-7228-40a3-995a-cf94ce68586b
    # |                 | myfile
    # |                 | myfile2
    # |    | ab
    # |        | cd
    # |            | abcddf95-7228-40a3-995a-cf94ce68586b
    # |                 | myfile
    # |                 | myfile2


    # Now just delete the file in the blobstore_cache subfolder that we uploaded previously:
    # - buildpack_cache/92/6c/926cdf95-7228-40a3-995a-cf94ce68586b
    # The observable behaviour is that all files in the bucket get returned and thus deleted.
    # NOTE: As Pagination is not implemented this function will delete 100 files max at once as the api does not
    # return more files in a single response.
    # ------------------------------------------------
    # 现在删除我们之前上传到blobstore_cache子目录的文件，
    # - buildpack_cache/92/6c/926cdf95-7228-40a3-995a-cf94ce68586b（删除这个文件）
    # 我们发现：返回了所有在bucket的文件，并且所有这些文件都被删除了。
    blobstorecache_client.delete_all_in_path('926cdf95-7228-40a3-995a-cf94ce68586b')

    @logger.info("Finished")

  end
end

#!/usr/bin/env ruby

require File.expand_path('../config/boot', __dir__)

require 'cloud_controller'
require 'steno'
require 'cloud_controller/blobstore/fog/fog_client'
require 'cloud_controller/steno_configurer'

module VCAP::CloudController
  module Blobstore

    # Configure CC Logger
    @log_counter = Steno::Sink::Counter.new
    @logger ||= Steno.logger('cc.runner')

    logconf = {
        level: "debug"
    }

    StenoConfigurer.new(logconf).configure do |steno_config_hash|
      steno_config_hash[:sinks] << @log_counter
    end

    # Bucket connection information
    BUCKET_NAME = 'YOUR_BUCKET_NAME'
    opt = {
        provider: 'Aliyun',
        aliyun_accesskey_id: 'YOUR_ACCESS_KEY',
        aliyun_accesskey_secret: 'YOUR_ACCESS_SECRET',
        aliyun_oss_bucket: BUCKET_NAME,
        aliyun_region_id: 'eu-central-1',
    }

    # Fog client targeting root folder of bucket
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
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '016cdf95-7228-40a3-995a-cf94ce68586b')
    root_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '026cdf95-7228-40a3-995a-cf94ce68586b')

    # Save some file in blobstore_cache subfolder (gets saved in subfolders according to first 4 letters of filename)
    blobstorecache_client.cp_to_blobstore(__dir__ + '/fog_aliyun_test.rb', '926cdf95-7228-40a3-995a-cf94ce68586b')

    # We now have following structure inside the bucket:
    # BUCKET:
    # - 01
    # |    | 6c
    # |        | 026cdf95-7228-40a3-995a-cf94ce68586b
    # - 02
    # |    | 6c
    # |        | 026cdf95-7228-40a3-995a-cf94ce68586b
    # - buildpack_cache
    # |    | 92
    # |        | 6c
    # |            | 926cdf95-7228-40a3-995a-cf94ce68586b


    # Now just delete the file in the blobstore_cache subfolder that we uploaded previously:
    # - buildpack_cache/92/6c/926cdf95-7228-40a3-995a-cf94ce68586b
    # The observable behaviour is that all files in the bucket get returned and thus deleted.
    # NOTE: As Pagination is not implemented this function will delete 100 files max at once as the api does not
    # return more files in a single response.
    blobstorecache_client.delete_all_in_path('926cdf95-7228-40a3-995a-cf94ce68586b')

    @logger.info("Finished")

  end
end

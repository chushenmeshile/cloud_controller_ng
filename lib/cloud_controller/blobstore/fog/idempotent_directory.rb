# rubocop:disable Naming/AccessorMethodName
module CloudController
  module Blobstore
    class IdempotentDirectory
      def initialize(directory)
        @directory = directory
      end

      def get_or_create
        @directory.get || @directory.create
      end

      def key
        @directory.key
      end
    end
  end
end
# rubocop:enable Naming/AccessorMethodName

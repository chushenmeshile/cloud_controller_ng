require 'active_model'
require 'messages/validators'
require 'messages/base_message'

require 'cloud_controller/label_selector/label_selector_parser'

module VCAP::CloudController
  class ListMessage < BaseMessage
    include ActiveModel::Model
    include Validators

    ALLOWED_PAGINATION_KEYS = [:page, :per_page, :order_by].freeze

    register_allowed_keys ALLOWED_PAGINATION_KEYS

    # Disallow directly calling <any>ListMessage.new
    # All ListMessage classes should be instantiated via the from_params method
    private_class_method :new

    attr_accessor(*ALLOWED_PAGINATION_KEYS, :pagination_params)
    attr_reader :pagination_options
    attr_accessor :requirements, :label_selector_parser

    def initialize(params={})
      params = params.symbolize_keys
      @pagination_params = params.slice(*ALLOWED_PAGINATION_KEYS)
      @pagination_options = PaginationOptions.from_params(params)
      @requirements = parse_label_selector(params[:label_selector]) if params.key?(:label_selector)
      super(params)
    end

    def to_param_hash(exclude: [])
      super(exclude: ALLOWED_PAGINATION_KEYS + exclude)
    end

    class PaginationOrderValidator < ActiveModel::Validator
      def validate(record)
        order_by = record.pagination_params[:order_by]
        columns_allowed = record.valid_order_by_values.join('|')
        matcher = /\A(\+|\-)?(#{columns_allowed})\z/

        unless order_by.match?(matcher)
          valid_values_message = record.valid_order_by_values.map { |value| "'#{value}'" }.join(', ')
          record.errors.add(:order_by, "can only be: #{valid_values_message}")
        end
      end
    end

    class PaginationPageValidator < ActiveModel::Validator
      def validate(record)
        page = record.pagination_params[:page]
        per_page = record.pagination_params[:per_page]

        validate_page(page, record) if !page.nil?
        validate_per_page(per_page, record) if !per_page.nil?
      end

      def validate_page(value, record)
        record.errors.add(:page, 'must be a positive integer') unless value.to_i > 0
      end

      def validate_per_page(value, record)
        if value.to_i > 0
          record.errors.add(:per_page, 'must be between 1 and 5000') unless value.to_i <= 5000
        else
          record.errors.add(:per_page, 'must be a positive integer')
        end
      end
    end

    # override this to define valid fields to order by
    def valid_order_by_values
      [:created_at, :updated_at]
    end

    validates_with PaginationPageValidator
    validates_with PaginationOrderValidator, if: -> { @pagination_params[:order_by].present? }

    def self.from_params(params, to_array_keys)
      opts = params.dup
      to_array_keys.each do |attribute|
        to_array! opts, attribute
      end
      new(opts.symbolize_keys)
    end

    def parse_label_selector(label_selector)
      @label_selector_parser = LabelSelectorParser.new
      @label_selector_parser.parse(label_selector)
      @label_selector_parser.requirements
    end
  end
end

module VCAP::CloudController
  class BuildListFetcher
    def initialize(message:)
      @message = message
    end

    def fetch_all(eager_loaded_associations: [])
      filter(AppModel.dataset, eager_loaded_associations: eager_loaded_associations)
    end

    def fetch_for_spaces(space_guids:, eager_loaded_associations: [])
      app_dataset = AppModel.select(:id).where(space_guid: space_guids)
      filter(app_dataset, eager_loaded_associations: eager_loaded_associations)
    end

    private

    attr_reader :message

    def filter(app_dataset, eager_loaded_associations: [])
      dataset = BuildModel.dataset

      if message.requested?(:label_selector)
        dataset = LabelSelectorQueryGenerator.add_selector_queries(
          label_klass: BuildLabelModel,
          resource_dataset: dataset,
          requirements: message.requirements,
          resource_klass: BuildModel,
        )
      end

      if message.requested?(:states)
        dataset = dataset.where(state: message.states)
      end

      if message.requested?(:package_guids)
        dataset = dataset.where(package_guid: message.package_guids)
      end

      dataset.where(app_guid: filter_app_dataset(app_dataset).select(:guid)).eager(eager_loaded_associations).qualify
    end

    def filter_app_dataset(app_dataset)
      if message.requested? :app_guids
        app_dataset = app_dataset.where(guid: message.app_guids)
      end
      app_dataset
    end
  end
end

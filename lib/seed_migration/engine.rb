require 'rails'

module SeedMigration

  class << self
    mattr_accessor :extend_native_migration_task
    mattr_accessor :migration_table_name
    mattr_accessor :ignore_ids
    mattr_accessor :update_seeds_file
    mattr_accessor :migrations_path

    self.migration_table_name = 'seed_migration_data_migrations' # Hardcoded, evil!
    self.extend_native_migration_task = false
    self.ignore_ids = false
    self.update_seeds_file = true
    self.migrations_path = 'data'
  end

  def self.config(&block)
    yield self
    after_config
  end

  def self.after_config
    if self.extend_native_migration_task
      # require_relative '../extra_tasks.rb' # require_relative only available Ruby 1.9.2+
      require File.expand_path('../../extra_tasks.rb', __FILE__)
    end
  end

  class Engine < ::Rails::Engine
    isolate_namespace SeedMigration

    config.generators do |g|
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

  end
end

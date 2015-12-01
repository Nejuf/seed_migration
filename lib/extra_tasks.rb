# This task is manually loaded after the engine has been initialized
require 'rake'

begin
  # If a rake task is ran from the parent applicatiom, all Rails rasks are
  # already loaded.
  # But if `rails {s|c}` is ran from the parent application, then tasks are not
  # loaded
  Rake::Task['db:migrate']
rescue RuntimeError
  Rails.application.load_tasks
end

# Attempts to find all model classes defined in the Rails application and engines,
#   and invokes MyModel.reset_column_information
# This is required to use the model class effectively, after changing the table structure.
#   # E.g. after adding a new column ActiveRecord needs to reload to create the dynamic methods
task :reload_model_classes do
  def lchomp(base, arg)
    base.to_s.reverse.chomp(arg.to_s.reverse).reverse
  end
  # Inspired by RailsAdmin #viable_models https://github.com/sferik/rails_admin/blob/master/lib/rails_admin/config.rb 
  potential_model_names = ([Rails.application] + Rails::Engine.subclasses.collect(&:instance)).map do |app|
    (app.paths['app/models'].to_a + app.config.autoload_paths).collect do |load_path|
      Dir.glob(app.root.join(load_path)).collect do |load_dir|
        Dir.glob(load_dir + '/**/*.rb').collect do |filename|
          # app/models/module/class.rb => module/class.rb => module/class => Module::Class
          lchomp(filename, "#{app.root.join(load_dir)}/").chomp('.rb').camelize
        end
      end
    end
  end.flatten.reject { |m| m.starts_with?('Concerns::') } # rubocop:disable MultilineBlockChain
 
  puts "Reloading column information for models" 
  potential_model_names.each do |class_name|
    begin
      class_name.constantize.reset_column_information
    rescue LoadError, NoMethodError, NameError, TypeError => e
      # Must not be a model class
      next
    end
  end 
end

if SeedMigration.extend_native_migration_task
  Rake::Task['db:migrate'].enhance do
    Rake::Task['reload_model_classes'].execute
    Rake::Task['seed:migrate'].invoke
  end
end


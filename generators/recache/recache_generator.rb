class RecacheGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # Model folder
      m.directory File.join('app/models')
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "create_recache_stores"
    end
  end

protected
  def banner
    "Usage: ruby script/generate recache - Creates the migration needed for recached and does nothing else."
  end
end
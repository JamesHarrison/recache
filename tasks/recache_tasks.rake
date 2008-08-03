
# Erases all cached data in the store
namespace :recache do
  desc "Erase cached data"
  task (:purge => :environment) do 
    RecacheStore.destroy_all
  end
end
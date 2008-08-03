# The RecacheStore is an ActiveRecord model definition used for storing cache data.
# To create the recache_stores table run the recache_migration generator 
#  ruby script/generate recache
#  rake db:migrate
class RecacheStore < ActiveRecord::Base
  serialize :data
end

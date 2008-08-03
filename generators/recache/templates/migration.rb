class CreateRecacheStores < ActiveRecord::Migration
  def self.up
    create_table :recache_stores do |t|
      t.string :request_hash
      t.text :data
      t.datetime :cached_until
    end
    add_index :recache_stores, :request_hash
  end

  def self.down
    drop_table :recache_stores
  end
end

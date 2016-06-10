require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'jinsei'
)

ActiveRecord::Migration.create_table :tweets do |t|
  t.string :jinsei_id
  t.text :tweet
  t.string :url
  t.integer :label
end

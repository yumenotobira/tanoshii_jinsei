require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter: 'mysql2',
  database: 'jinsei'
)

class Tweet < ActiveRecord::Base
end

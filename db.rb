require 'rubygems'
require 'active_record'

ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "db.sqlite"
)

ActiveRecord::Schema.define do
    unless ActiveRecord::Base.connection.table_exists?(:activities)
        create_table :activities do |table|
            table.column :name, :string
        end
    end
 
    unless ActiveRecord::Base.connection.table_exists?(:activities_times)
        create_table :activities_times do |table|
            table.column :activity_id, :integer
            table.column :start, :datetime
            table.column :stop, :datetime
        end
    end
end

class Activity < ActiveRecord::Base
    self.table_name = "activities"
    has_many :activities_times
end

class ActivityTime < ActiveRecord::Base
    self.table_name = "activities_times"
    belongs_to :activity
end

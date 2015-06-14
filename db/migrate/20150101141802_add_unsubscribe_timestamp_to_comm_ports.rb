class AddUnsubscribeTimestampToCommPorts < ActiveRecord::Migration
  def change
    add_column :comm_ports, :unsubscribe_ts, :datetime
  end
end

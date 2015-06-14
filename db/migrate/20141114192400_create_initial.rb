LOAD_DATA_STATEMENTS = <<LDS
CREATE DATABASE voyagex_development CHARACTER SET utf8  COLLATE utf8_unicode_ci;
GRANT ALL ON voyagex_development.* TO sko_voyagex@localhost IDENTIFIED BY '76$sko';
CREATE DATABASE voyagex_test CHARACTER SET utf8  COLLATE utf8_unicode_ci;
GRANT ALL ON voyagex_test.* TO sko_voyagex@localhost IDENTIFIED BY '76$sko';
CREATE DATABASE sko_voyagex CHARACTER SET utf8  COLLATE utf8_unicode_ci;
GRANT ALL ON sko_voyagex.* TO voyagex@localhost IDENTIFIED BY '76$sko';

dbName=voyagex_development &&
outDir="/tmp" &&
#rm -f $outDir/*_dump.sql &&
#structureDump=$dbName"_structure_dump.sql" &&
dataDump=$dbName"_data_dump.sql" &&
#mysqldump -u root -p -d --result-file=$outDir/$structureDump --add-drop-table $dbName &&
mysqldump -u root -p -t --result-file=$outDir/$dataDump $dbName

dbName=voyagex_development &&
outDir="/tmp" &&
#structureDump=$dbName"_structure_dump.sql" &&
dataDump=$dbName"_data_dump.sql" &&
#mysql -u root -p $dbName < $outDir/$structureDump &&
mysql -u root -p $dbName < $outDir/$dataDump

delete from roles;
load data local infile '/tmp/roles.csv' replace into table roles fields terminated by ',' optionally enclosed by '"' ignore 1 lines;
delete from users;
load data local infile '/tmp/users.csv' replace into table users fields terminated by ',' optionally enclosed by '"' ignore 1 lines;
update users set created_at=now(),updated_at=now() where created_at='0000-00-00 00:00:00';
LDS

class CreateInitial < ActiveRecord::Migration
  
  def change
    create_table :roles do |t|
      t.string :name, null: false
    end

    create_table(:users) do |t|
      t.string :username

      ## Database authenticatable
      t.string :email,              null: false
      t.string :encrypted_password, null: false

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, default: 0, null: false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      t.timestamps
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    # add_index :users, :confirmation_token,   unique: true
    # add_index :users, :unlock_token,         unique: true
  end
  
end
 

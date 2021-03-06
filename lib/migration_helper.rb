module MigrationConstraintHelpers

   # Creates a foreign key from +table+.+field+ against referenced_table.referenced_field
   #
   # table: The tablename
   # field: A field of the table
   # referenced_table: The table which contains the field referenced
   # referenced_field: The field (which should be part of the primary key) of the referenced table
   # cascade: delete & update on cascade?
   def foreign_key(table, field, referenced_table, referenced_field = :id, cascade = true)
      execute "ALTER TABLE #{table} ADD CONSTRAINT #{constraint_name(table, field)}
               FOREIGN KEY #{constraint_name(table, field)} (#{field_list(field)})
               REFERENCES #{referenced_table}(#{field_list(referenced_field)})
               #{(cascade ? 'ON DELETE CASCADE ON UPDATE CASCADE' : '')}"
   end

   # Drops a foreign key from +table+.+field+ that has been created before with
   # foreign_key method
   #
   # table: The table name
   # field: A field (or array of fields) of the table
   def drop_foreign_key(table, field)
      execute "ALTER TABLE #{table} DROP FOREIGN KEY #{constraint_name(table, field)}"
   end

   # Creates a primary key for +table+, which right now HAS NOT primary key defined
   #
   # table: The table name
   # field: A field (or array of fields) of the table that will be part of the primary key
   def primary_key(table, field)
      execute "ALTER TABLE #{table} ADD PRIMARY KEY(#{field_list(field)})"
   end

   # Modifies the primary key of +table+, which right now has already a primary key defined
   #
   # table: The table name
   # field: A field (or array of fields) of the table that will be part of the primary key
   def change_primary_key(table, field)
      execute "ALTER TABLE #{table} DROP PRIMARY KEY, ADD PRIMARY KEY(#{field_list(field)})"
   end

   # Execute REPAIR TABLE in each table given as parameter or in all of them
   # if none is indicated
   #
   # tables: list of tables
   def repair_tables(*tables)
      ActiveRecord::Migration.say("Reparing tables...", true)
      each_table do |table|
         if tables.empty? || tables.include?(table.to_s)
            ActiveRecord::Migration.say(table, true)
            execute "REPAIR TABLE #{table}"
         end
      end
   end

   # Execute OPTIMIZE TABLE in each table given as parameter or in all of them
   # if none is indicated
   #
   # tables: list of tables
   def optimize_tables(*tables)
      each_table do |table|
         if tables.empty? || tables.include?(table.to_s)
            ActiveRecord::Migration.say(table, true)
            execute "OPTIMIZE TABLE #{table}"
         end
      end
   end

   # Yields for each table defined in the database
   # The name of the table is given as parameter
   def each_table
      execute("SHOW TABLES").each do |row|
         a = row.is_a?(Hash) ? row.values : row
         yield a.first
      end
   end

   private

   # Creates a constraint name for table and field given as parameters
   #
   # table: The table name
   # field: A field of the table
   def constraint_name(table, field)
      "fk_#{table}_#{field_list_name(field)}"
   end

   def field_list(fields)
      fields.is_a?(Array) ? fields.join(',') : fields
   end

   def field_list_name(fields)
      fields.is_a?(Array) ? fields.join('_') : fields
   end

end

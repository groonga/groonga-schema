# Copyright (C) 2016  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "groonga-schema/column"
require "groonga-schema/plugin"
require "groonga-schema/table"

module GroongaSchema
  class Schema
    attr_reader :plugins
    attr_reader :tables
    attr_reader :columns
    def initialize
      @plugins = []
      @tables = {}
      @columns = {}
    end

    def apply_command(command)
      case command.command_name
      when "register"
        plugin = Plugin.new(command.path)
        @plugins << plugin
      when "plugin_register"
        plugin = Plugin.new(command.name)
        @plugins << plugin
      when "table_create"
        apply_command_table_create(command)
      when "column_create"
        apply_command_column_create(command)
      end
    end

    private
    def apply_command_table_create(command)
      table = Table.new(command.name)
      table.apply_command(command)
      refered_table = @tables[table.key_type]
      if refered_table
        table.reference_key_type = true
        refered_table.related_tables << table
      end
      @tables[table.name] = table
      @columns[table.name] ||= {}
    end

    def apply_command_column_create(command)
      column = Column.new(command.table, command.name)
      column.apply_command(command)

      table = @tables[column.table_name]
      if table
        table.columns << column
      end

      refered_table = @tables[column.value_type]
      if refered_table
        column.reference_value_type = true
        refered_table.related_columns << column
        refered_columns = @columns[column.value_type] || {}
        column.sources.each do |source|
          next if source == "_key"
          source_column = refered_columns[source]
          if source_column
            source_column.related_columns << column
          end
        end
      end

      @columns[column.table_name] ||= {}
      @columns[column.table_name][column.name] = column
    end
  end
end

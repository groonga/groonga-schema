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

require "groonga-schema/table"
require "groonga-schema/column"

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
      when "table_create"
        table = Table.new(command.name)
        table.apply_command(command)
        @tables[table.name] = table
      when "column_create"
        column = Column.new(command.table, command.name)
        column.apply_command(command)
        @columns[column.table_name] ||= {}
        @columns[column.table_name][column.name] = column
      end
    end
  end
end

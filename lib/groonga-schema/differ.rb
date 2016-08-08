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

require "groonga-schema/diff"

module GroongaSchema
  class Differ
    # @param from [Schema] The original schema.
    # @param to [Schema] The changed schema.
    def initialize(from, to)
      @from = from
      @to = to
    end

    def diff
      diff = Diff.new
      diff_plugins(diff)
      diff_tables(diff)
      diff_columns(diff)
      diff
    end

    private
    def diff_plugins(diff)
      diff.removed_plugins.concat(@from.plugins - @to.plugins)
      diff.added_plugins.concat(@to.plugins - @from.plugins)
    end

    def diff_tables(diff)
      from_tables = @from.tables
      to_tables = @to.tables

      from_tables.each do |name, from_table|
        to_table = to_tables[name]
        if to_table.nil?
          diff.removed_tables[name] = from_table
        end
      end

      to_tables.each do |name, to_table|
        from_table = from_tables[name]
        if from_table.nil?
          diff.added_tables[name] = to_table
        end
      end
    end

    def diff_columns(diff)
    end
  end
end

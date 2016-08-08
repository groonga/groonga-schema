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

module GroongaSchema
  class Column
    attr_reader :table_name
    attr_reader :name
    attr_accessor :type
    attr_accessor :flags
    attr_accessor :value_type
    attr_accessor :sources
    def initialize(table_name, name)
      @table_name = table_name
      @name = name
      @type = :scalar
      @flags = []
      @value_type = "ShortText"
      @sources = []
    end

    def apply_command(command)
      applier = CommandApplier.new(self, command)
      applier.apply
    end

    def ==(other)
      return false unless other.is_a?(self.class)

      @table_name == other.table_name and
        @name == other.name and
        @type == other.type and
        @flags.sort == other.flags.sort and
        @value_type == other.value_type and
        @sources == other.sources
    end

    class CommandApplier
      def initialize(column, command)
        @column = column
        @command = command
      end

      def apply
        apply_flags
        apply_value_type
        apply_sources
      end

      private
      def apply_flags
        @type = :scalar
        @flags = []
        @command.flags.each do |flag|
          parse_flag(flag)
        end

        @column.type = @type
        @column.flags = @flags
      end

      def parse_flag(flag)
        case flag
        when "COLUMN_SCALAR"
          @type = :scalar
        when "COLUMN_VECTOR"
          @type = :vector
        when "COLUMN_INDEX"
          @type = :index
        else
          @flags << flag
        end
      end

      def apply_value_type
        # TODO: Validate for index column. Index column must have table as
        # value type.
        @column.value_type = @command.type
      end

      def apply_sources
        case @type
        when :index
          @column.sources = @command.sources
        else
          @column.sources = []
        end
      end
    end
  end
end

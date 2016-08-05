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
    def initialize(schema1, schema2)
      @schema1 = schema1
      @schema2 = schema2
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
      diff.removed_plugins += @schema1.plugins - @schema2.plugins
      diff.added_plugins   += @schema2.plugins - @schema1.plugins
    end

    def diff_tables(diff)
    end

    def diff_columns(diff)
    end
  end
end

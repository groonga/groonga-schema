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

class ColumnTest < Test::Unit::TestCase
  def column_create(arguments)
    Groonga::Command::ColumnCreate.new(arguments)
  end

  sub_test_case "#apply_command" do
    test "index" do
      arguments = {
        "table"  => "Words",
        "name"   => "entries_text",
        "flags"  => "COLUMN_INDEX|WITH_POSITION|WITH_SECTION|INDEX_TINY",
        "type"   => "Entries",
        "source" => "title, content",
      }
      command = column_create(arguments)
      column = GroongaSchema::Column.new("Words", "entries_text")
      column.apply_command(command)
      assert_equal({
                     :table_name => "Words",
                     :name       => "entries_text",
                     :type       => :index,
                     :flags      => ["WITH_POSITION", "WITH_SECTION", "INDEX_TINY"],
                     :value_type => "Entries",
                     :sources    => ["title", "content"],
                   },
                   {
                     :table_name => column.table_name,
                     :name       => column.name,
                     :type       => column.type,
                     :flags      => column.flags,
                     :value_type => column.value_type,
                     :sources    => column.sources,
                   })
    end
  end
end

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

class TableTest < Test::Unit::TestCase
  def table_create(arguments)
    Groonga::Command::TableCreate.new("table_create", arguments)
  end

  sub_test_case "#apply_command" do
    test "lexicon" do
      arguments = {
        "name"              => "Words",
        "flags"             => "TABLE_PAT_KEY",
        "key_type"          => "ShortText",
        "default_tokenizer" => "TokenBigram",
        "normalizer"        => "NormalizerAuto",
        "token_filters"     => "TokenStem|TokenStopWord",
      }
      command = table_create(arguments)
      table = GroongaSchema::Table.new("Words")
      table.apply_command(command)
      assert_equal({
                     :name              => "Words",
                     :type              => :pat_key,
                     :flags             => [],
                     :key_type          => "ShortText",
                     :value_type        => nil,
                     :default_tokenizer => "TokenBigram",
                     :normalizer        => "NormalizerAuto",
                     :token_filters     => ["TokenStem", "TokenStopWord"],
                   },
                   {
                     :name              => table.name,
                     :type              => table.type,
                     :flags             => table.flags,
                     :key_type          => table.key_type,
                     :value_type        => table.value_type,
                     :default_tokenizer => table.default_tokenizer,
                     :normalizer        => table.normalizer,
                     :token_filters     => table.token_filters,
                   })
    end
  end
end

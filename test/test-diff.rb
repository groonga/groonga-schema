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

class DiffTest < Test::Unit::TestCase
  def setup
    @diff = GroongaSchema::Diff.new
  end

  def plugin(name)
    GroongaSchema::Plugin.new(name)
  end

  def table(name, options)
    table = GroongaSchema::Table.new(name)
    options.each do |key, value|
      table.__send__("#{key}=", value)
    end
    table
  end

  def column(table_name, name, options)
    column = GroongaSchema::Column.new(table_name, name)
    options.each do |key, value|
      column.__send__("#{key}=", value)
    end
    column
  end

  sub_test_case "#same?" do
    test "same" do
      assert do
        @diff.same?
      end
    end

    test "different" do
      @diff.added_plugins << plugin("token_filters/stem")
      assert do
        not @diff.same?
      end
    end
  end

  sub_test_case "#to_groonga_command_list" do
    test "plugins" do
      @diff.added_plugins << plugin("token_filters/stem")
      @diff.removed_plugins << plugin("token_filters/stop_word")
      assert_equal(<<-LIST, @diff.to_groonga_command_list)
plugin_register --name "token_filters/stem"

plugin_unregister --name "token_filters/stop_word"
      LIST
    end

    test "added tables - without column" do
      token_filters = [
        "TokenFilterStopWord",
        "TokenFilterStem",
      ]
      @diff.added_tables["Words"] = table("Words",
                                          :type => :pat_key,
                                          :key_type => "ShortText",
                                          :default_tokenizer => "TokenBigram",
                                          :normalizer => "NormalizerAuto",
                                          :token_filters => token_filters)
      @diff.added_tables["Names"] = table("Names",
                                          :type => :hash_key,
                                          :flags => "KEY_LARGE",
                                          :key_type => "ShortText",
                                          :normalizer => "NormalizerAuto")
      @diff.added_tables["Commands"] = table("Commands",
                                             :type => :hash_key,
                                             :key_type => "Names",
                                             :reference_key_type => true)

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names" \\
  --normalizer "NormalizerAuto"

table_create \\
  --default_tokenizer "TokenBigram" \\
  --flags "TABLE_PAT_KEY" \\
  --key_type "ShortText" \\
  --name "Words" \\
  --normalizer "NormalizerAuto" \\
  --token_filters "TokenFilterStopWord|TokenFilterStem"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands"
      LIST
    end

    test "added tables - with column" do
      @diff.added_tables["Names"] = table("Names",
                                          :type => :hash_key,
                                          :flags => "KEY_LARGE",
                                          :key_type => "ShortText",
                                          :normalizer => "NormalizerAuto")
      @diff.added_tables["Commands"] = table("Commands",
                                             :type => :hash_key,
                                             :key_type => "Names",
                                             :reference_key_type => true)
      @diff.added_columns["Commands"] = {
        "description" => column("Commands", "description",
                                :value_type => "Text"),
      }
      token_filters = [
        "TokenFilterStopWord",
        "TokenFilterStem",
      ]
      @diff.added_tables["Words"] = table("Words",
                                          :type => :pat_key,
                                          :key_type => "ShortText",
                                          :default_tokenizer => "TokenBigram",
                                          :normalizer => "NormalizerAuto",
                                          :token_filters => token_filters)
      @diff.added_columns["Words"] = {
        "commands_description" => column("Words", "commands_description",
                                         :type => :index,
                                         :flags => ["WITH_POSITION"],
                                         :value_type => "Commands",
                                         :sources => ["description"],
                                         :reference_value_type => true),
      }

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names" \\
  --normalizer "NormalizerAuto"

table_create \\
  --default_tokenizer "TokenBigram" \\
  --flags "TABLE_PAT_KEY" \\
  --key_type "ShortText" \\
  --name "Words" \\
  --normalizer "NormalizerAuto" \\
  --token_filters "TokenFilterStopWord|TokenFilterStem"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands"
column_create \\
  --flags "COLUMN_SCALAR" \\
  --name "description" \\
  --table "Commands" \\
  --type "Text"

column_create \\
  --flags "COLUMN_INDEX|WITH_POSITION" \\
  --name "commands_description" \\
  --source "description" \\
  --table "Words" \\
  --type "Commands"
      LIST
    end

    test "removed columns" do
      @diff.removed_columns["Words"] = {
        "weight" => column("Words", "weight",
                           :value_type => "Float"),
        "commands_description" => column("Words", "commands_description",
                                         :type => :index,
                                         :flags => ["WITH_POSITION"],
                                         :value_type => "Commands",
                                         :sources => ["description"],
                                         :reference_value_type => true),
      }
      @diff.removed_columns["Commands"] = {
        "description" => column("Commands", "description",
                                :value_type => "Text"),
        "comment" => column("Commands", "comment",
                            :value_type => "ShortText"),
      }

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
column_remove \\
  --name "commands_description" \\
  --table "Words"

column_remove \\
  --name "comment" \\
  --table "Commands"
column_remove \\
  --name "description" \\
  --table "Commands"

column_remove \\
  --name "weight" \\
  --table "Words"
      LIST
    end

    test "removed tables" do
      @diff.removed_tables["Names"] = table("Names",
                                            :type => :hash_key,
                                            :flags => "KEY_LARGE",
                                            :key_type => "ShortText",
                                            :normalizer => "NormalizerAuto")
      @diff.removed_tables["Commands"] = table("Commands",
                                               :type => :hash_key,
                                               :key_type => "Names",
                                               :reference_key_type => true)

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_remove \\
  --name "Commands"

table_remove \\
  --name "Names"
      LIST
    end

    test "changed tables - without columns" do
      @diff.changed_tables["Names"] = table("Names",
                                            :type => :hash_key,
                                            :flags => "KEY_LARGE",
                                            :key_type => "ShortText",
                                            :normalizer => "NormalizerAuto")
      @diff.changed_tables["Commands"] = table("Commands",
                                               :type => :hash_key,
                                               :key_type => "Names",
                                               :reference_key_type => true)

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names_new" \\
  --normalizer "NormalizerAuto"
table_copy \\
  --from_name "Names" \\
  --to_name "Names_new"
table_rename \\
  --name "Names" \\
  --new_name "Names_old"
table_rename \\
  --name "Names_new" \\
  --new_name "Names"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands_new"
table_copy \\
  --from_name "Commands" \\
  --to_name "Commands_new"
table_rename \\
  --name "Commands" \\
  --new_name "Commands_old"
table_rename \\
  --name "Commands_new" \\
  --new_name "Commands"

table_remove \\
  --name "Names_old"

table_remove \\
  --name "Commands_old"
      LIST
    end

    test "changed tables - with columns" do
      @diff.changed_tables["Names"] = table("Names",
                                            :type => :hash_key,
                                            :flags => "KEY_LARGE",
                                            :key_type => "ShortText",
                                            :normalizer => "NormalizerAuto")
      commands_columns = [
        column("Commands", "description",
               :value_type => "Text"),
        column("Commands", "comment",
               :value_type => "ShortText"),
      ]
      @diff.changed_tables["Commands"] = table("Commands",
                                               :type => :hash_key,
                                               :key_type => "Names",
                                               :reference_key_type => true,
                                               :columns => commands_columns)

      assert_equal(<<-LIST.gsub(/\\\n\s+/, ""), @diff.to_groonga_command_list)
table_create \\
  --flags "TABLE_HASH_KEY|KEY_LARGE" \\
  --key_type "ShortText" \\
  --name "Names_new" \\
  --normalizer "NormalizerAuto"
table_copy \\
  --from_name "Names" \\
  --to_name "Names_new"
table_rename \\
  --name "Names" \\
  --new_name "Names_old"
table_rename \\
  --name "Names_new" \\
  --new_name "Names"

table_create \\
  --flags "TABLE_HASH_KEY" \\
  --key_type "Names" \\
  --name "Commands_new"
column_create \\
  --flags "COLUMN_SCALAR" \\
  --name "comment" \\
  --table "Commands_new" \\
  --type "ShortText"
column_copy \\
  --from_name "comment" \\
  --from_table "Commands" \\
  --to_name "comment" \\
  --to_table "Commands_new"
column_create \\
  --flags "COLUMN_SCALAR" \\
  --name "description" \\
  --table "Commands_new" \\
  --type "Text"
column_copy \\
  --from_name "description" \\
  --from_table "Commands" \\
  --to_name "description" \\
  --to_table "Commands_new"
table_rename \\
  --name "Commands" \\
  --new_name "Commands_old"
table_rename \\
  --name "Commands_new" \\
  --new_name "Commands"

table_remove \\
  --name "Names_old"

table_remove \\
  --name "Commands_old"
      LIST
    end
  end
end

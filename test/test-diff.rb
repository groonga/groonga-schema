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
plugin_register token_filters/stem

plugin_unregister token_filters/stop_word
      LIST
    end
  end
end

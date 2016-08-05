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
  class Diff
    attr_reader :removed_plugins
    attr_reader :added_plugins

    attr_reader :removed_tables
    attr_reader :added_tables
    attr_reader :renamed_tables

    attr_reader :removed_columns
    attr_reader :added_columns
    attr_reader :renamed_columns
    def initialize
      @removed_plugins = []
      @added_plugins = []

      @removed_tables = {}
      @added_tables = {}
      @renamed_tables = {}

      @removed_columns = {}
      @added_columns = {}
      @renamed_columns = {}
    end
  end
end

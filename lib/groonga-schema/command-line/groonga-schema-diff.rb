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

require "optparse"

require "groonga/command/parser"

require "groonga-schema/differ"

module GroongaSchema
  module CommandLine
    class GroongaSchemaDiff
      class << self
        def run(args=ARGV)
          new(args).run
        end
      end

      def initialize(args)
        @args = args
        @format = :command
      end

      def run
        parse_arguments

        from_schema = parse_schema(@from_path)
        to_schema = parse_schema(@to_path)
        differ = GroongaSchema::Differ.new(from_schema, to_schema)
        diff = differ.diff(:format => @format)
        $stdout.print(diff.to_groonga_command_list)

        if diff.same?
          0
        else
          1
        end
      end

      private
      def parse_arguments
        parser = OptionParser.new
        parser.banner += " FROM_SCHEMA TO_SCHEMA"

        available_formats = [:command, :uri]
        parser.on("--format=FORMAT", available_formats,
                  "Specify output Groonga command format.",
                  "Available formats: #{available_formats.join(", ")}",
                  "(#{@format})") do |format|
          @format = format
        end

        rest_args = parser.parse(@args)

        if rest_args.size != 2
          $stderr.puts("Error: Both FROM_SCHEMA and TO_SCHEMA are required.")
          $stderr.puts(parser.help)
          exit(false)
        end
        @from_path, @to_path = rest_args
      end

      def parse_schema(path)
        File.open(path) do |file|
          schema = GroongaSchema::Schema.new
          parser = Groonga::Command::Parser.new
          parser.on_command do |command|
            schema.apply_command(command)
          end
          file.each_line do |line|
            parser << line
          end
          parser.finish
          schema
        end
      end
    end
  end
end

# README

[![Gem Version](https://badge.fury.io/rb/groonga-schema.svg)](http://badge.fury.io/rb/groonga-schema)
[![Build Status](https://travis-ci.org/groonga/groonga-schema.svg?branch=master)](https://travis-ci.org/groonga/groonga-schema)

## Name

groonga-schema

## Description

Groonga-schema is a Ruby library and tool to processes [Groonga](http://groonga.org/)'s schema.

## Install

    % gem install groonga-schema

## Usage

### As a tool

Here are command lines provided by groonga-schema:

  * `groonga-schema-diff`: It reports difference between 2 schema.

#### `groonga-schema-diff`

`groonga-schema-diff` reports difference between 2 schema:

```text
% groonga-schema-diff FROM_SCHEMA TO_SCHEMA
```

The output of `groonga-schema-diff` is a Groonga command list. It
means that you can apply difference by processing the output of
`groonga-schema-diff` by Groonga. The relation of them are similar to
`diff` and `patch`.

The following example shows about it.

Here are sample schema:

`current.grn`:

```text
table_create Logs TABLE_NO_KEY
column_create Logs timestamp COLUMN_SCALAR ShortText
```

`new.grn`:

```text
table_create Logs TABLE_NO_KEY
column_create Logs timestamp COLUMN_SCALAR Time
```

In the `current.grn` schema, `Logs.timestamp` column's value type is
`ShortText`. In the `new.grn` schema, it's `Time`.

Here is the output of `groonga-schema-diff`:

```text
% groonga-schema-diff current.grn new.grn
column_create --flags "COLUMN_SCALAR" --name "timestamp_new" --table "Logs" --type "Time"
column_copy --from_name "timestamp" --from_table "Logs" --to_name "timestamp_new" --to_table "Logs"
column_rename --name "timestamp" --new_name "timestamp_old" --table "Logs"
column_rename --name "timestamp_new" --new_name "timestamp" --table "Logs"

column_remove --name "timestamp_old" --table "Logs"
```

The output Groonga command list does the followings:

  1. Create a new column `Logs.timestamp_new`. The value type of the new column is `Time` not `ShortText`.

  2. Copy data to `Logs.timestamp_new` from `Logs.timestamp`.

  3. Rename `Logs.timestamp` to `Logs.timestamp_old`.

  4. Rename `Logs.timestamp_new` to `Logs.timestamp`.

  5. Remove `Logs.timestamp_old`.

It means that the output Groonga command list supports data migration.

Here is a sample database to show data migration:

```text
% groonga DB_PATH dump
table_create Logs TABLE_NO_KEY
column_create Logs timestamp COLUMN_SCALAR ShortText

load --table Logs
[
["_id","timestamp"],
[1,"2016-08-16 00:00:01"],
[2,"2016-08-16 00:00:02"],
[3,"2016-08-16 00:00:03"],
[4,"2016-08-16 00:00:04"],
[5,"2016-08-16 00:00:05"]
]
```

You can apply the change by the following command lines:

```text
% groonga-schema-diff current.grn new.grn > diff.grn
% groonga --file diff.grn DB_PATH
```

Or:

```text
% groonga-schema-diff current.grn new.grn | groonga DB_PATH
```

Here is the sample database after applying the changes:

```text
% groonga DB_PATH dump
table_create Logs TABLE_NO_KEY
column_create Logs timestamp COLUMN_SCALAR Time

load --table Logs
[
["_id","timestamp"],
[1,1471273201.0],
[2,1471273202.0],
[3,1471273203.0],
[4,1471273204.0],
[5,1471273205.0]
]
```

`Logs.timestamp` column's value type is changed to `Time` from
`ShortText` and data are also converted.

You can also use `groonga-schema-diff` to remote databases.

The following command line shows difference between databases served
at `http://192.168.0.1:10041` and `http://192.168.0.2:10041/`:

```text
% groonga-schema-diff \
    'http://192.168.0.1:10041/d/dump?dump_records=no' \
    'http://192.168.0.2:10041/d/dump?dump_records=no'
```

You can apply the output Groonga command list by `groonga-client`
command provided by `groonga-client-cli` gem:

```text
% groonga-client --host 192.168.0.1 diff.grn
```

The following command synchronizes schema at
`http://192.168.0.1:10041/` with schema at `http://192.168.0.1:10042/`:

```text
% groonga-schema-diff \
    'http://192.168.0.1:10041/d/dump?dump_records=no' \
    'http://192.168.0.2:10041/d/dump?dump_records=no' |
  groonga-client --host 192.168.0.1
```

After this command line, the following command line outputs nothing
because there are no difference between schema at
`http://192.168.0.1:10041/` and `http://192.168.0.1:10042/`:

```text
% groonga-schema-diff \
    'http://192.168.0.1:10041/d/dump?dump_records=no' \
    'http://192.168.0.2:10041/d/dump?dump_records=no'
%
```

NOTE: You should use database carefully while applying
changes. Because some tables and columns may be removed while applying
changes. If you touch removed tables and/or columns from another
threads, Groonga may be crashed. It's better that you reduce the max
number of threads to 1 while applying changes like the following:

```text
% echo thread_limit 1 | groonga-client --host 192.168.0.1
% groonga-schema-diff \
    'http://192.168.0.1:10041/d/dump?dump_records=no' \
    'http://192.168.0.2:10041/d/dump?dump_records=no' |
  groonga-client --host 192.168.0.1
% echo thread_limit 8 | groonga-client --host 192.168.0.1
```

NOTE: You can't use the `thread_limit` technique with `groonga-httpd`
because `groonga-httpd` is multi-process model not multi-threading
model. You need to reduce the number of workers by changing
`worker_processes` to `1` in `groonga-httpd.conf` and reload the
configuration file. You also need to increase the number of workers
after you apply the changes.

### As a library

TODO...

## Dependencies

* Ruby

## Mailing list

* English: [groonga-talk@lists.sourceforge.net](https://lists.sourceforge.net/lists/listinfo/groonga-talk)
* Japanese: [groonga-dev@lists.sourceforge.jp](http://lists.sourceforge.jp/mailman/listinfo/groonga-dev)

## Chat

* English: [Gitter:groonga/en](https://gitter.im/groonga/en)
* Japanese: [Gitter:groonga/ja](https://gitter.im/groonga/ja)

## Authors

* Kouhei Sutou \<kou@clear-code.com\>

## License

LGPLv2.1 or later. See doc/text/lgpl-2.1.txt for details.

(Kouhei Sutou has a right to change the license including contributed patches.)

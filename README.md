# snaptime

**This Gem is still in an early stage of development. Please not use this in production yet.**

Snaptime lets you versionize Active Record models using single table versioning.
Records are identified by a `natural_id` and their validity is controlled via
`valid_from` and `valid_to`. Snaptime also supports associations between
versioned models as well as associations to and from unversioned models.

## Reasons for snaptime

* Most of Snaptime's operation is transparent, so you won't even notice that
  a certain model is versioned if you don't explicitely want to.

* Associations between, to and from versioned models are automatically handeled.
  This lets Snaptime version entire, complex hierarchies.

* It is very lightweight.

* It is non-intrusive. It does not overwrite a single Rails method without
  you explicitly telling it to do so.

* It can be easily extended to support other database adapters.

## Basic concept

Snaptime can be enabled on a per-model basis. Using dedicated migration methods,
each versioned table is complemented with the following fields:

- `natural_id`

  This is the ID that does not change between versions. This is also the ID
  that is referenced when pointing to a versioned model.

- `valid_from`, `valid_to`

  These are UTC timestamps in milliseconds that specify a specific version's
  validity. The field `valid_from` always specifies the point in time at which
  a certain version has been created, while `valid_to` says when the version
  got outdated. This can happen by deleting the record (which does not actually
  delete it but just sets `valid_to`) or when a new version arises. There can't
  be any gaps between the validity fields of a version string.

Snaptime works by hooking into your versioned models at *creation*, *update* and
*deletion*:

- At creation, it automatically generates a new `natural_id` and sets
  `valid_from` to the current time.

- At update, `valid_from` is again set to the current time and the record is
  updated as usual. But before the record gets updated, Snaptime creates a copy
  of the record's current state and sets `valid_from` and `valid_to`
  accordingly. The copy is created in-db (using `insert ... select`) and does
  not call any application side logic.

- At deletion, all it does is setting `valid_to` of the current record to the
  current time again.

What this means is that the original record always stays the newest one. This
has many advantages, as the record itself can be updated as usual and if another
model would ever point at the `id` instead the `natural_id`, it would always
point to the newest one.

## Basic setup

### Gemfile

Add the following to your application's Gemfile:

```ruby
gem :snaptime
```

You can also specify a fixed version:

```ruby
gem :snaptime, '~> 1.0.0'
```

### Setup task

Snaptime needs to generate a `natural_id` next to your `id`. In some adapters,
this can be done using database sequences, while other databases require a
custom setup (i.e. MySQL let's you workaround this by adding a dedicated
sequence table as well as a custom procedure).

Using the following rake task, Snaptime automatically generates the required
migrations. Note that this migration only performs a basic setup and does not
enable any of your models to be versioned. This happens using separate
migrations as described in the following chapters.

```bash
rake snaptime:setup -- <adapter-name>
```

Replace `<adapter-name>` with the name of your database adapter. Spell it
exactly as the `adapter` setting of your database configuration reads. If the
specific adapter does not require any setup, you will get a respective message.

## Versionizing a model

### Performing the database migrations

TODO

### Include the versionize module

```ruby
class YourModel < ActiveRecord::Base
  include Snaptime::Versioned
end
```

## Caveats

- Do not use `def self.default_scope` but `default_scope do` in versioned models
  if you need to extend the default scope.
- `.unscoped` also removes the default scope added by snaptime.

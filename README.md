# RedmineConceptualAttachments

This is a [Redmine](https://www.redmine.org/) plugin. It providing additional level of abstraction for attach files, using default `Attachment` class.

## Aim and purpose

Plugin provide new abstraction level over `Arrachment` class and have own interface for CRUD operations over files for achievement the following goals:
* ability to split files on groups for implement validations and custom logic of CRUD operation for each group separately;
* simple and homogeneous interface for creating file from any source (even from Form, File System, other `Attachment`, [Dragonfly](https://github.com/markevans/dragonfly) or from anythere else) and easy interface for copy too;
* ability to reduce duplicate entries in file storage, i.e. store only file with unique content, but evade from thinking about counting reference and related with it CRUD routines.

## Compatibility

Plugin tested with `2.6.*` and `2.5.*` versions of Redmine. But there is a high probability of proper working with other versions of Redmine (`3.2.*`, `3.1.*`, `3.0.*` etc) due to absence of major changes in `Attachment` class.

## Installation

Use a common Redmine [installation guide](http://www.redmine.org/projects/redmine/wiki/Plugins). This plugin has an migration. So, you need to copy source code into a proper folder, run `bundle` for install required gems and then run `migration`.

## Simple example

After install plugin you can do follows in any [ActiveRecord](https://github.com/rails/rails/tree/master/activerecord) model:

```ruby
class MyDocument < ActiveRecord::Base
  # allow to attach one text-note file
  upload_handler :my_note,
                 SmartUploadHandler,
                 multiple_files: false,
                 extensions: %w(txt)
  # and allow to attach one photo-file with proper content types
  upload_handler :my_photo,
                 SmartUploadHandler,
                 multiple_files: false,
                 content_types: ['image/jpeg', 'image/png']
end
```

Then, write something like this in view:

```ruby
= f.input :my_note,
          label: 'Note file',
          input_html: { accept: 'text/plain' },
          as: :file
= f.input :my_photo,
          label: 'Photo file',
          as: :file
```

And finally, do somewhere in controller follows:

```ruby
def update_files
  @my_codument = MyDocument.find(params[:id])
  # assign files, received from form
  @my_document.my_note = params[:my_note]
  @my_document.my_photo = params[:my_photo]

  unless @my_document.save
    flash[:errors] = @my_document.errors.full_messages
  end
end
```

If something goes wrong (for example, user upload note in `pdf` format and/or `binary` file instead of photo), in errors of `@my_document` appear all messages from `upload_handler` validations.

## Interface

Below describes the methods provided by the plugin, and their arguments.

### Initialization

There is a method `upload_hander`, which available for any subclass of `ActiveRecord::Base`:

```ruby
class MyDocument < ActiveRecord::Base
  upload_handler :my_note,
                 SmartUploadHandler,
                 multiple_files: false,
                 extensions: %w(txt),
                 content_types: ['text/plain']
end
```

Arguments of `upload_handler` is follows:

1. `:my_note` - name of pseudo relation and a basis for naming other methods, provided by `upload_handler`;
2. `SmartUploadHandler` - one of default `UploadHandler` class; this prodive defailt CRUD logic and files are grouped on the basis of of this class;
3. `options` - hash with additional options; this can contain follows keys:
  * `:multiple_files` - boolean property; allow attach more then one file to an `upload_handler` pseudo relation (**WARNING:** logic for `true` value still under construction, use on your own risk)
  * `:dirtify_column` - column of model for marking as [dirty](http://api.rubyonrails.org/classes/ActiveModel/Dirty.html); required for initiate callback chain for validate and save an assigned into `upload_handler` file;
  * `:extensions` - string array with allowed extensions for file; values is case insensitive, i.e. `extensions: [pdf]` allows to add file like follows: `preview.pdf`, `test.PdF`, `GRADE.PDF` and so on; by default there is no validation on extension;
  * `:content_types` - string array with allowed content types; behaviour is same as for `:extensions`.

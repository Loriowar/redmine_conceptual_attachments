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


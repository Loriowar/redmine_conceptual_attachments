module RedmineConceptualAttachments::AttachmentPatch
  extend ActiveSupport::Concern

  included do
    # выключаем дефолтный callback на удаление файла
    skip_callback :destroy, :after, :delete_from_disk
    # и заменяем его callback-ом по коммиту, чтобы после rollback-а файл сохранялся
    after_commit :delete_from_disk, on: :destroy
    # аналогично, удаляем файл при откате транзакции по созданию
    after_rollback :delete_from_disk, on: :create
  end

  #instance methods were here

  module ClassMethods
    #class methods were here
  end
end
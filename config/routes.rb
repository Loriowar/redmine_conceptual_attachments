# copypast from Redmine routes
get 'parametrized_attachments/:id/:filename', to: 'parametrized_attachments#show',
                                              id: /\d+/,
                                              filename: /.*/,
                                              as: 'named_parametrized_attachment'
class DropboxImageImports::Source
  require 'dropbox_image_imports/source' 
  require 'dropbox_image_imports/product' 
  require 'dropbox_image_imports/import' 
  require 'dropbox_image_imports/notification' 
  require 'dropbox_image_imports/crunch' 

  
  def initialize(path,token)
    @path = path
    @token = token
  end

end

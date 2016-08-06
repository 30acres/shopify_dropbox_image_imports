require 'dropbox_image_imports/product' 
require 'dropbox_image_imports/import' 
require 'dropbox_image_imports/notification' 
require 'dropbox_image_imports/crunch' 

class DropboxImageImports
  
  def initialize(path, token)
    @path = path
    @token = token
  end
  # require "dropbox_image_imports/product"
  # require "dropbox_image_imports/process"
  # require "dropbox_image_imports/import"
  # require "dropbox_image_imports/notification"
  
  def update_all_products
    Crunch.process_all_images(@path,@token)
  end

 def update_missing_products
   Crunch.process_missing_images(@path,@token)
 end


end

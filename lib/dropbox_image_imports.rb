class DropboxImageImports
  require 'dropbox_image_imports/product' 
  require 'dropbox_image_imports/import' 
  require 'dropbox_image_imports/notification' 
  require 'dropbox_image_imports/crunch' 

  def initialize(path, token)
    Source.new(path,token)
  end
  
  def update_all_products
    Crunch.process_all_images
  end

 def update_missing_products
   Crunch.process_missing_images
 end

end

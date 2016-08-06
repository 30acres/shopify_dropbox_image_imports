class DropboxImageImports
  require 'dropbox_image_imports/source' 
  require 'dropbox_image_imports/product' 
  require 'dropbox_image_imports/import' 
  require 'dropbox_image_imports/image' 
  require 'dropbox_image_imports/notification' 
  require 'dropbox_image_imports/crunch' 

  def initialize(path, token)
    @source = Source.new(path,token)
  end
  
  def update_all_products
    Crunch.process_all_images(@source)
  end

 def update_missing_products
   Crunch.process_missing_images(@source)
 end

 def reorder_images
   DropboxImageImports::Image.reorder
 end

end

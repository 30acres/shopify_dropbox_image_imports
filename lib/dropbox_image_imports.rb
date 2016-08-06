class DropboxImageImports
  # require "dropbox_image_imports/product"
  # require "dropbox_image_imports/process"
  # require "dropbox_image_imports/import"
  # require "dropbox_image_imports/notification"
  
  def self.update_all_products(path=nil, token=nil)
    ImageImports.process_all_images(path,token)
  end

 def self.update_missing_products(path=nil, token=nil)
    ImageImports.process_missing_images(path,token)
 end


end

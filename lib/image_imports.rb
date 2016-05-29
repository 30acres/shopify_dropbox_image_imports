require "image_imports/version"



module ImageImports
  require "product/product"
  require "import_image/import_image"

  def self.update_all_products(path=nil, token=nil)
    ImportImage.process_all_images(path,token)
  end

  # def self.update_recent_products
  #   ImportImage.process_recent_images
  # end

end

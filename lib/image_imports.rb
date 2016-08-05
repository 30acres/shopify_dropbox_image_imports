require "image_imports/version"



module ImageImports
  require "image_imports/product"
  require "image_imports/import_image"

  def self.update_all_products(path=nil, token=nil)
    puts '----------------------------------------------------'
    puts '|  To reprocess images remove tag: image-processed  |'
    puts '----------------------------------------------------'
    ImageImports.process_all_images(path,token)
  end

 def self.update_missing_products(path=nil, token=nil)
    ImageImports.process_missing_images(path,token)
  end


end

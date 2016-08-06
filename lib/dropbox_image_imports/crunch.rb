require 'net/http'
require 'dropbox_sdk'
require "fastimage"

class DropboxImageImports::Crunch  < DropboxImageImports::Source
  require 'dropbox_image_imports/source' 
  require 'dropbox_image_imports/product' 
  require 'dropbox_image_imports/import' 
  require 'dropbox_image_imports/notification' 
  require 'dropbox_image_imports/crunch' 


  def self.process_all_images
    Notification.notify('Process Started')
    process_all
    Notification.notify('Process Finished')
  end

  def self.process_missing_images
    process_all_images ## Same for now
  end

  def self.process_all
    if @path and @token
      Product.all_products_array.each do |page|
        page.each do |product|
          Import.new(product,@path,@token).update_images
        end
      end
    end
  end


end


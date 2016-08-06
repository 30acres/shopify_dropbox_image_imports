require 'net/http'
require 'dropbox_sdk'
require "fastimage"

class DropboxImageImports::Crunch < DropboxImageImports::Source

  def self.process_all_images
    DropboxImageImports::Notification.notify('Process Started')
    process_all
    DropboxImageImports::Notification.notify('Process Finished')
  end

  def self.process_missing_images
    process_all_images ## Same for now
  end

  def self.process_all
    if path and token
      DropboxImageImports::Product.all_products_array.each do |page|
        page.each do |product|
          DropboxImageImports::Import.new(product,path,token).update_images
        end
      end
    end
  end


end


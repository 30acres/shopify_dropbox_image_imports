require 'net/http'
require 'dropbox_sdk'
require "fastimage"

class DropboxImageImports::Crunch < DropboxImageImports::Source
  def self.process_all_images(src)
    @source = src
    DropboxImageImports::Notification.notify('Process Started')
    process_all
    DropboxImageImports::Notification.notify('Process Finished')
  end

  def self.process_missing_images(src)
    process_all_images(src) ## Same for now
  end

  def self.process_all
    if @source.valid?
      DropboxImageImports::Product.all_products_array.each do |page|
        page.each do |product|
          DropboxImageImports::Import.new(product,@source).update_images
        end
      end
    end
  end


end


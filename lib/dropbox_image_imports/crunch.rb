require 'net/http'
require 'dropbox_sdk'
require "fastimage"

class DropboxImageImports::Crunch < DropboxImageImports::Source
  def self.process_all_images(src,slack)
    @source = src
    @slack = slack
    DropboxImageImports::Notification.notify('Process Started',:update, slack)
    process_all
    DropboxImageImports::Notification.notify('Process Finished',:update, slack)
  end

  def self.process_missing_images(src,slack)
    process_all_images(src,slack) ## Same for now
  end

  def self.process_all
    if @source.valid?
      DropboxImageImports::Product.all_products_array.each do |page|
        page.each do |product|
          DropboxImageImports::Import.new(product,@source,@slack).update_images
        end
      end
    end
  end

  def self.process_one_product(src,product_id=nil, slack=nil)
    @source = src
    DropboxImageImports::Notification.notify("Process Started : #{product_id}", :update, @slack)
    process_one(product_id)
    DropboxImageImports::Notification.notify("Process Finished : #{product_id}", :update, @slack)
  end

  def self.process_one(product_id)
    if @source.valid?
      DropboxImageImports::Import.new(DropboxImageImports::Product.one_product_by_id(product_id),@source).update_images
    end
  end

end


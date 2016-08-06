require 'net/http'
require 'dropbox_sdk'
require "product/product"
require "fastimage"
require 'slack-notifier'

class DropboxImageImports::Crunch

  def initialize(path,token)
    @path = path
    @token = token
  end

  def process_all_images
    Notification.notify('Process Started')
    process_all
    Notification.notify('Process Finished')
  end

  def process_missing_images
    process_all_images ## Same for now
  end

  def process_all
    if @path and @token
      Product.all_products_array.each do |page|
        page.each do |product|
          Import.new(product,@path,@token).update_images
        end
      end
    end
  end


end


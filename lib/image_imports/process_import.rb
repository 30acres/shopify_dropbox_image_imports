require 'net/http'
require 'dropbox_sdk'
require "product/product"
require "fastimage"
require 'slack-notifier'

module ImageImports
  def self.process_all_images(path, token)
    if path and token
      ImageImports::Product.all_products_array.each do |page|
        page.each do |product|
          ImportImage.new(product,path,token).update_images
        end
      end
    end
  end
  def self.process_missing_images(path, token)
    
    Notification.notify('Process Started')
    
    if path and token
      ImageImports::Product.all_products_array.each do |page|
        page.each_with_index do |product,index|
          puts "======== Processing Product: #{index + 1}: #{product.title} ============"
          ImportImage.new(product,path,token).update_images
          puts "========================================================================"
        end
      end
    end
    
    Notification.notify('Process Finished')
  end
end


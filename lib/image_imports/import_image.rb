require 'net/http'
require 'dropbox_sdk'
require "product/product"
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
    if path and token
      ImageImports::Product.all_products_array.each do |page|
        page.each do |product|
          if product.images.count <= 2
            puts "Skipping, has image #{product.title}"
          else
            ImportImage.new(product,path,token).update_images
          end
        end
      end
    end
  end
end

class ImportImage
  def initialize(product,path,token)
    @product = product
    @path = path
    @token = token
  end

  def update_images
    if has_dropbox_images
      upload_images
    end
  end

  def connect_to_source
    # w = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET)
    # authorize_url = flow.start()
    DropboxClient.new(@token)
  end

  def has_dropbox_images
    if dropbox_images.any?
      puts "Found match (#{@product.title})"
      match = true
    else
      puts "No match (#{@product.title})"
      match = false
    end
    match
  end

  def dropbox_images
    if @product.variants.any? and @product.variants.first.sku.length >= 5 ## Just to make sure its not an accident
      connect_to_source.metadata(@path)['contents'].select { |image| image['path'].include?(@product.variants.first.sku + '-')   }
    else
      []
    end
  end

  def upload_images
    remove_all_images if dropbox_images.any?
    dropbox_images.each do |di|
      url = connect_to_source.media(di['path'])['url']
      if url
        image = ShopifyAPI::Image.new(product_id: @product.id, src: url)
        image.save!
      end
    end
  end

  def remove_all_images
    ## this will delete your images!
    @product.images = []
    @product.save!
  end
end

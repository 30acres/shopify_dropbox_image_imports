require 'net/http'
require 'dropbox_sdk'
require "product/product"
require "fastimage"
require 'slack-notifier'

class DropboxImageImports::Import < DropboxImageImports::Source
  def initialize(product,src)
    @product = product
    @source = src
  end

  def update_images
    if has_dropbox_images
      upload_images
    end
  end

  def connect_to_source
    # w = DropboxOAuth2FlowNoRedirect.new(APP_KEY, APP_SECRET) 
    # authorize_url = flow.start()
    DropboxClient.new(@source.token)
  end

  def has_dropbox_images
    if dropbox_images.any? 
      if dropbox_images.count != @product.images.count
        puts "Images Updated (#{@product.title})"
        DropboxImageImports::Notification.notify "Updated : #{@product.title}"
        match = true
      end
      match = false
    else
      puts "No matching image in Dropbox for added product: (#{@product.title} - #{@product.published_at})"
      DropboxImageImports::Notification.notify "No match : #{@product.title}"
      match = false
    end
    match
  end

  def dropbox_images
    if @product.variants.any? and @product.variants.first.sku.length >= 5 ## Just to make sure its not an accident
      paths = @source.path.split(',')
      images = []
      paths.each do |path|
        images = images + connect_to_source.metadata(path)['contents'].select { |image| image['path'].downcase.include?(@product.variants.first.sku.downcase + '-')   }
      end
      images
    else
      []
    end
  end

  def upload_images
    remove_all_images if dropbox_images.any?
    failed = []
    tagged = 'image-checked'
    dropbox_images.each do |di|
      url = connect_to_source.media(di['path'])['url']
      
      if url
        if FastImage.size(url) and FastImage.size(url).inject(:*) <= 19999999
          image = ShopifyAPI::Image.new(product_id: @product.id, src: url)
          tagged = 'image-processed'
          if ShopifyAPI.credit_left <= 39
            puts 'Snoozed'
            sleep(20)
          end
          image.save!
        else
          puts 'IMAGE TOO BIG!'
          tagged = 'image-failed'
          
          DropboxImageImports::Notification.notify("Failed: #{@product.title}\n Img: #{url}" ,:alert)

          failed << url
        end
      end
      update_image_tags(tagged)
      reorder_images

      if ShopifyAPI.credit_used >= 38
        puts 'WOAH! Slow down abuser.'
        DropboxImageImports::Notification.notify("Hit API Limit :: Having a 20 second nap")
        sleep(20)
        DropboxImageImports::Notification.notify("Nap done.")
      end
    end

    DropboxImageImports::Notification.notify("Import Complete")
  end

  def reorder_images
    #reload the product and check on the images
    @product = ShopifyAPI::Product.find(@product.id)
    @product.images.each do |img|
      puts 'GOT HERE'
      binding.pry
      if intended_position != img.position
        img.position = intented_position
        DropboxImageImports::Notification.notify("Reordered: #{@product.title}")
        img.save!
      end
    end
  end

  def update_image_tags(tagged)
    ## reload the product heres
    @product = ShopifyAPI::Product.find(@product.id)
    @product.tags = @product.tags + ", #{tagged}"
    @product.save!
  end

  def remove_all_images
    ## this will delete your images!
    @product.images = []
    @product.save!
  end
end

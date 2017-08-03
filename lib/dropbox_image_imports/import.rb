require 'net/http'
require 'dropbox_sdk'
require "product/product"
require "fastimage"
require 'slack-notifier'

class DropboxImageImports::Import < DropboxImageImports::Source
  def initialize(product,src,slack)
    @product = product
    @source = src
    @slack = slack
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
      match = false
      puts "Product Images: #{@product.images.to_s}"
      if dropbox_images.count != @product.images.count or changed_images?
        puts "Images Updated (#{@product.title})"
        # DropboxImageImports::Notification.notify "Updated : #{@product.title}", :update, @slack
        match = true
      end
    else
      puts "No matching image in Dropbox for added product: (#{@product.title} - #{@product.published_at})"
      # DropboxImageImports::Notification.notify "No match : #{@product.title} (#{@product.published_at ? @product.published_at : 'Not Published'})", :update, Shop.where(dropbox_path: 'I.AM.GIA BULK IMAGE UPLOADS').last
      match = false
    end
    match
  end

  def dropbox_images
    # binding.pry
    if @product.variants.any? and @product.variants.first.sku.length >= 5 ## Just to make sure its not an accident
      paths = @source.path.split(',')
      images = []
      paths.each do |path|
        puts "PATH: " + path
        # binding.pry
        images = images + connect_to_source.metadata(path)['contents'].select { |image| image['path'] if image['path'].downcase.include?(@product.title.split('(').first.downcase.gsub(' ','').gsub('/','') + '-')   }
        # images = images + connect_to_source.metadata(path)['contents'].select { |image| image['path'] if image['path'].downcase.include?(@product.variants.first.sku.downcase)   }
      end
      puts images.to_s
      images
    else
      puts 'Empty?'
      []
    end
  end

  def fast_image(url)
    begin
    tries ||= 3
    FastImage.size(url).count
    rescue NoMethodError => e
      puts 'Retrying...'
      retry unless (tries -= 1).zero?
    else
      FastImage.size(url)
    end
  end

  def is_fast?(url)
    fast_image(url) and fast_image(url).present? and fast_image(url).count >= 1 and fast_image(url).inject(:*) <= 19999999
  end

  def upload_images
    remove_all_images if dropbox_images.any?
    failed = []
    tagged = 'image-checked'
    dropbox_images.each do |di|
      url = connect_to_source.media(di['path'])['url']
      modified = connect_to_source.metadata(di['path'])['modified']
      if url
        # binding.pry
        puts "url: #{url}"
        puts "FastImage: #{fast_image(url)}"

        if is_fast?(url) 
          product = ShopifyAPI::Product.find(@product.id)
          intended_position = url.split('-').last.split('.').first.gsub(/[^0-9,.]/,'').to_i + 1
          metafields = [
            {
              "key": "dropbox_modified",
              "value": modified,
              "value_type": "string",
              "namespace": "global"
            }
          ]
          image = ShopifyAPI::Image.new(product_id: @product.id, src: url, position: intended_position, metafields: metafields)
          tagged = 'image-processed'
          if ShopifyAPI.credit_left <= 2
            puts 'Snoozin'
            # DropboxImageImports::Notification.notify("Over Capacity" ,:alert, Shop.where(dropbox_path: 'I.AM.GIA BULK IMAGE UPLOADS').last.slack_webhook_url)
            sleep(20)
          end
          image.save!
        else
          ##binding.pry
          puts 'IMAGE TOO BIG!'
          tagged = 'image-failed'
          DropboxImageImports::Notification.new("Failed (TOO BIG?): #{@product.title}\n Img: #{url}" ,:alert, Shop.where(dropbox_path: 'I.AM.GIA BULK IMAGE UPLOADS').last.slack_webhook_url).send_message

          failed << url
        end
      end

      if ShopifyAPI.credit_used >= 38
        puts 'WOAH! Slow down speedy.'
        # DropboxImageImports::Notification.notify("Hit API Limit :: Having a 20 second nap", :alert, @slack)
        sleep(20)
        # DropboxImageImports::Notification.notify("Nap done.", :alert, @slack)
      end
    end

    DropboxImageImports::Notification.new("Import Completed", nil, Shop.where(dropbox_path: 'I.AM.GIA BULK IMAGE UPLOADS').last.slack_webhook_url).send_message
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

  def changed_images?
    # binding.pry
    changed = false
    puts 'Checking for Changes'
    if @product.images and dropbox_images
      dim = dropbox_images.map { |di| di["modified"].to_time.to_i }.sort { |x, y| x.to_i <=> y.to_i }
      puts 'DIM'
      puts dim
      pim = @product.images.map { |pi| ShopifyAPI::Metafield.find(:first,:params=>{:resource => "product_images", :resource_id => pi.id } ).value.to_time.to_i if ShopifyAPI::Metafield.find(:first,:params=>{:resource => "product_images", :resource_id => pi.id} )  }.sort { |x, y| x.to_i <=> y.to_i }
      puts "PIM"
      puts pim
      # binding.pry
        if (!dim or !pim) or (dim and pim and dim.compact.uniq.sort != pim.compact.uniq.sort)
        # DropboxImageImports::Notification.notify("New Image Found #{@product.title}", :update, @slack)
        puts "Changed = true"
        changed = true
      else 
        puts "Changed = false"
      end
      changed
    end
    changed
  end
end

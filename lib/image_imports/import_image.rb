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
    @notifier = Slack::Notifier.new ENV['SLACK_IMAGE_WEBHOOK'], channel: '#product_data_feed',
      username: 'Image Notifier', icon_url: 'https://cdn.shopify.com/s/files/1/1290/9713/t/4/assets/favicon.png?3454692878987139175'
    @notifier.ping "[Image Import] Process Started"
    if path and token
      ImageImports::Product.all_products_array.each do |page|
        page.each_with_index do |product,index|
          puts "======== Processing Product: #{index + 1}: #{product.title} ============"
          ImportImage.new(product,path,token).update_images
          puts "=========================================================="
        end
      end
    end
    @notifier.ping "[Image Import] Process Finished"
  end
end

class ImportImage
  def initialize(product,path,token)
    @product = product
    @path = path
    @token = token
    @notifier = Slack::Notifier.new ENV['SLACK_IMAGE_WEBHOOK'], channel: '#product_data_feed',
      username: 'Image Notifier', icon_url: 'https://cdn.shopify.com/s/files/1/1290/9713/t/4/assets/favicon.png?3454692878987139175'
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
      if dropbox_images.count != @product.images.count
        puts "Images Updated (#{@product.title})"
        match = true
      end
      match = false
    else
      puts "No matching image in Dropbox for added product: (#{@product.title} - #{@product.published_at})"
      @notifier.ping "Image Import: No match (#{@product.title})"
      match = false
    end
    match
  end

  def dropbox_images
    if @product.variants.any? and @product.variants.first.sku.length >= 5 ## Just to make sure its not an accident
      paths = @path.split(',')
      images = []
      paths.each do |path|
        images = images + connect_to_source.metadata(path)['contents'].select { |image| image['path'].include?(@product.variants.first.sku + '-')   }
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
      puts "========"
      puts url
      puts "========"
      if url
        if FastImage.size(url) and FastImage.size(url).inject(:*) <= 19999999
          image = ShopifyAPI::Image.new(product_id: @product.id, src: url)
          tagged = 'image-processed'
          # @notifier.ping "Image Import [#{tagged}]: #{@product.title}"
          if ShopifyAPI.credit_left <= 39
            sleep(20)
          end
          image.save!
        else
          puts 'IMAGE TOO BIG!'
          tagged = 'image-failed'
          @notifier = Slack::Notifier.new ENV['SLACK_IMAGE_WEBHOOK'], channel: '#data_alerts',
      username: 'Data Notifier', icon_url: 'https://cdn.shopify.com/s/files/1/1290/9713/t/4/assets/favicon.png?3454692878987139175'
          @notifier.ping "Image Import [FAILED]: #{@product.title}\n Img: #{url}"

          failed << url
        end
      end
    end

    if ShopifyAPI.credit_used >= 38
      puts 'WOAH! Slow down abuser.'
      sleep(20)
    end
    update_image_tags(tagged)

    puts '----------------------'
    puts failed
    puts '--- FAILED SO FAR ----'
    puts failed.count
    @notifier.ping "Image Import Complete :: #{failed.count} Failed"
    puts '----------------------'
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

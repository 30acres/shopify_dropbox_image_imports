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
    if path and token
      ImageImports::Product.all_products_array.each do |page|
        page.each_with_index do |product,index|
          puts "======== Processing Product: #{index}: #{product.title} ============"
          if product.images.count >= 2 or product.tags.include?('image-processed')
            puts "Skipping:: #{product.title}"
          else
            puts "Processing:: #{product.title}"
            ImportImage.new(product,path,token).update_images
          end
          puts "=========================================================="
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
    @notifier = Slack::Notifier.new ENV['SLACK_IMAGE_WEBHOOK'], channel: '#image_imports',
                                              username: 'notifier'
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
      @notifier.ping "No match (#{@product.title})"
      match = false
    end
    match
  end

  def dropbox_images
    if @product.variants.any? and @product.variants.first.sku.length >= 5 ## Just to make sure its not an accident
      # binding.pry
      paths = @path.split(',')
      images = []
      paths.each do |path|
        images = images + connect_to_source.metadata(path)['contents'].select { |image| image['path'].include?(@product.variants.first.sku + '-')   }
      end
      images
    else
      []
      #['http://www.endlessicons.com/wp-content/uploads/2013/10/clothes-hanger-icon.png']
    end
  end

  def upload_images
    remove_all_images if dropbox_images.any?
    failed = []
    dropbox_images.each do |di|

      url = connect_to_source.media(di['path'])['url']
      # binding.pry
      puts "========"
      puts url
      puts "========"
      if url
        if FastImage.size(url) and FastImage.size(url).inject(:*) <= 19999999
          image = ShopifyAPI::Image.new(product_id: @product.id, src: url)
          tagged = 'image-processed'
          image.save!
        else
          tagged = 'image-failed'
          puts 'IMAGE TOO BIG!'
          @notifier.ping "Failed Image Import: #{@product.title} Img: #{url}"
          
          failed << url
        end
      end
    end
    @product.tags = @product.tags + ", #{tagged}"
    @product.save
    puts '----------------------'
    puts failed
    puts '--- FAILED SO FAR ----'
    puts failed.count
    puts '----------------------'
  end

  def remove_all_images
    ## this will delete your images!
    @product.images = []
    @product.save!
  end
end

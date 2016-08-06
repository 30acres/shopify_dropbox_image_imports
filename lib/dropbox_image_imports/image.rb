class DropboxImageImports::Image

  def self.all_images_array(params={})
    p_arr = []
    find_params = { limit: limit }.merge(params)
    pages.times do |p|
      p_arr << ShopifyAPI::Image.find(:all, params: find_params.merge({ page: p}) ) 
    end
    p_arr
  end

  def self.recent_images_array
    params = { updated_at_min: 15.minutes.ago }
    all_products_array(params)
  end

  def self.pages
    count/limit + 1
  end

  def self.limit
    50
  end

  def self.count
    ShopifyAPI::Image.count
  end

  def self.reorder_images
    #reload the product and check on the images
    DropboxImageImports::Notification.notify("Image Order Check")
    self.all_images_array.each do |img|
      intended_position = img.src.split('-').last.split('.').first.gsub(/[^0-9,.]/,'').to_i + 1
      if intended_position != img.position
        img.position = intented_position
        DropboxImageImports::Notification.notify("Reordered: #{@product.title}")
        if ShopifyAPI.credit_left <= 39
          puts 'Snoozed'
          sleep(20)
        end
        img.save!
      end
    end
  end



  

end

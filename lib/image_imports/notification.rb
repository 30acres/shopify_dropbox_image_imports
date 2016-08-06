require 'slack-notifier'

class Notification
  def initialize(message, type = :update)
    @type = type
    @message = message
  end

  def notifier
    Slack::Notifier.new ENV['SLACK_IMAGE_WEBHOOK'], channel: channel,
      username: 'Image Notifier', icon_url: 'https://cdn.shopify.com/s/files/1/1290/9713/t/4/assets/favicon.png?3454692878987139175'
  end

  def channel
    if @type == :alert
      '#product_data_feed'
    else
      '#product_data_feed'
    end
  end

  def send_message
    notifier.ping(formatted_message)
  end

  def formatted_message
    "[Image Import] #{@message}"
  end
  
  def self.notify(message, type=nil)
    Notification.new(message, type).send_message
  end
  


end

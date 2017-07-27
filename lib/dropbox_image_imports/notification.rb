require 'slack-notifier'

class DropboxImageImports::Notification
  def initialize(message, type = :update)
    @type = type
    @message = message
  end

  def notifier
    Slack::Notifier.new @slack, channel: channel,
      username: 'Image Notifier'
  end

  def channel
    if @type == :alert
      '#data_alerts'
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
    DropboxImageImports::Notification.new(message, type).send_message
  end
  


end

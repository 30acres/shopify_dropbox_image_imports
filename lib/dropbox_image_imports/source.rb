class DropboxImageImports::Source
  def initialize(p,t)
    @path = p
    @token = t
  end

  def path
    @path
  end

  def token
    @token
  end

  def valid?
    path and token
  end
end

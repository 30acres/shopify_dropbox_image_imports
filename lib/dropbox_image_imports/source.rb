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
end

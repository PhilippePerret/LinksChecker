module LinksChecker
class Url
class Link

  attr_reader :url, :ini_uri

  def initialize(url, ini_uri)
    @url = url
    @ini_uri = ini_uri
  end

  ##
  # Pour checker si cette page existe
  # 
  def check
    Checker.check(uri)
  end

  def uri
    @uri ||= begin
      if ini_uri.start_with?('http')
        ini_uri
      else
        cuni = ini_uri
        cuni = cuni[1..-1] if cuni.start_with?('.')
        cuni = cuni[1..-1] if cuni.start_with?('/')
        File.join(LinksChecker.base, cuni)
      end
    end
  end
end #/class Link
end #/class Url
end #/module LinksChecker

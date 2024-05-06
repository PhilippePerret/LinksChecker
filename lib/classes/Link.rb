require 'net/http'
module LinksChecker
class Link

  # Une instance [Link]
  # C’est une URL complète (c’est-à-dire sans ancre mais avec le
  # query-string exact) pour vraiment considérer comme page 
  # différente des pages qui n’ont pas les mêmes paramètres.
  # 
  # @count permet de savoir combien de fois elle a été appelée
  # 

  # [Array[LinksChecker::Link]] Array de URI de toutes les sources 
  # qui contiennent ce lien.
  attr_reader :sources

  # [String] L’URI initial. C’est @uri qui contient la vraie 
  # adresse à prendre en compte
  attr_reader :ini_uri

  # [Integer] Le nombre de fois où ce lien a été appelé
  attr_reader :count

  def initialize(ini_uri, source)
    @sources  = [source]
    @ini_uri  = ini_uri
    @count    = 1
  end

  ##
  # = main =
  # 
  # Checker ce lien (est-ce qu’il existe ? est-ce qu’il renvoie à 
  # une page contenant d’autres liens ?)
  # 
  def check
    puts "Je dois apprendre à checker #{url.inspect}".jaune

    @inaccessibility = nil
    
    uri = URI("https://www.atelier-icare.net/icare_editions_dev/")
    begin
      response = Net::HTTP.get_response(uri)
    rescue SocketError => e
      @inaccessibility = "Socket Error".rouge
      return false
    end

    # Étude de la réponse
    case response
    when Net::HTTPSuccess
      get_all_links_in(response)
    when Net::HTTPMovedPermanently
      @inaccessibility = "Déplacer de façon permanente."
    when Net::HTTPNotFound
      @inaccessibility = "URL non trouvée"
    else
      @inaccessibility = "#{response.class}"
      puts "La réponse est de type #{response.class}".rouge
    end

    true # <==== TODO
  end


  # -- Predicate Methods --

  def accessible?
    @inaccessibility == nil
  end

  # -- Links Methods --

  # @main
  # 
  # Récupère tous les liens (HREF) de la page
  # 
  # @param response [Net::HTTPOK] La réponse à la requête url
  #                               courante
  def get_all_links_in(response)
    puts "Classe : #{response.class}"
    puts "BODY:\n#{response.body}"
    # @note: response.body contient tout le code HTML, en fait
    response.body.scan(/href="(.+?)"/i).each do |find|
      href = find[0]
      thelink = Link.new(href, self)
      if (err = self.class.href_uncheckable?(href)).nil?
        puts "Bon: #{href}".vert
      else
        EXCLUDED_LINKS << thelink
        puts "Bad: #{href} (#{err})".rouge
      end
    end

  end

  def self.href_uncheckable?(href)
    if href.start_with?('mailto:')
      return "BAD PROCOLE: mailto"
    elsif href.start_with?('https://fonts.')
      return "URL AVOIDED: google (or other) font"
    elsif BAD_EXTENSIONS[(ext = File.extname(href).downcase)]
      return "BAD EXTNAME: #{ext}"
    end
    return nil # OK
  end

  BAD_EXTENSIONS = {
    '.css'  => true,
    '.sass' => true,
    '.js'   => true,
    '.png'  => true,
    '.jpg'  => true,
    '.jpeg' => true,
    '.svg'  => true,
    '.web'  => true,
    '.pdf'  => true,
  }

  # -- Data Methods --


  # L’URI, avec le query-string
  def url
    @url ||= begin
      if ini_uri.start_with?('http')
        ini_uri.split('#')[0]
      else
        cuni = ini_uri
        cuni = cuni[1..-1] if cuni.start_with?('.')
        cuni = cuni[1..-1] if cuni.start_with?('/')
        cuni = cuni.split('#')[0]
        File.join(LinksChecker.base, cuni)
      end.freeze
    end
  end
end #/class Link
end #/module LinksChecker

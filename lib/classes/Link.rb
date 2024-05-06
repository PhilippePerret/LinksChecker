require 'net/http'
module LinksChecker
class Link

  # Une instance [Link]
  # C’est une URL complète (c’est-à-dire sans ancre mais avec le
  # query-string exact) pour vraiment considérer comme page 
  # différente des pages qui n’ont pas les mêmes paramètres.
  # 
  # count permet de savoir combien de fois elle a été appelée
  # 

  # [Array[LinksChecker::Link]] Array de URI de toutes les sources 
  # qui contiennent ce lien.
  attr_reader :sources

  # [String] La base du lien, qui peut être défini dans la page
  # Dans le cas contraire, c’est la base LinksChecker@base.
  attr_reader :base

  # [String] L’URI initial. C’est @uri qui contient la vraie 
  # adresse à prendre en compte
  attr_reader :ini_uri

  # [Boolean] True si le lien est OK
  attr_reader :success
  # [String|NilClass] L’erreur rencontrée (if any)
  attr_reader :error
  # [String|NilClass] Contient la raison de l’inaccessibilité du lien
  attr_reader :inaccessibility

  def initialize(ini_uri, base, source)
    @base     = base
    @ini_uri  = ini_uri
    # Les sources qui sont identiques
    # (pas sûr que ça serve à quelque chose)
    @sources  = [] 
    if source.nil?
      @isorigine = true
    else
      @isorigine = false
      @sources << source unless source.nil?
    end
  end

  ##
  # = main =
  # 
  # Checker ce lien (est-ce qu’il existe ? est-ce qu’il renvoie à 
  # une page contenant d’autres liens ?)
  # 
  def check
    @success = false # par défaut
    @inaccessibility = nil # par défaut
    
    uri = URI(url)
    begin
      response = Net::HTTP.get_response(uri)
    rescue SocketError => e
      @inaccessibility = "Socket Error".rouge
      return false
    end

    # Étude de la réponse
    case response
    when Net::HTTPSuccess
      # 
      # Cet lien a retourné un succès, c’est-à-dire que la page
      # a pu être chargée. Mais ça n’est pas forcément la page
      # attendue. Pour ça, il faut vérifier si les sélecteurs définis
      # par les paramètres (--exclude et --require) sont bien 
      # présents ou absents. C’est l’instance [Link::Page] qui s’en
      # charge, évidemment.
      # @note: response.body contient tout le code HTML, en fait
      @page = Page.new(self, response.body)
      if (error = LinksChecker.page_invalid?(@page))
        @error = error
      else
        # 
        # === SUCCÈS ===
        # 
        # (on peut checker ses liens — sauf si c’est un controle 
        # "flat" — pas "deep" et que la source de ce lien n’est pas
        # nil)
        @success = true
        if not(App.option?(:flat)) || origine?
          page.get_and_check_all_links_in_code
        else
          puts "On ne check pas les liens car :"
          puts "la source n’est pas nil (#{sources.inspect}" unless sources.nil?
          puts "L’option :flat n’est pas activée" unless App.option?(:flat)
          sleep 5
        end
      end
    when Net::HTTPMovedPermanently
      @inaccessibility = "Déplacer de façon permanente."
    when Net::HTTPNotFound
      @inaccessibility = "URL non trouvée"
    else
      @inaccessibility = "#{response.class}"
      puts "La réponse est de type #{response.class}".rouge
    end

    @success
  end


  # -- Predicate Methods --

  def accessible?
    @inaccessibility == nil
  end

  def success?
    success === true
  end

  # @return true si c’est le premier lien envoyé
  # (pour savoir, quand c’est :flat, s’il faut traiter ses liens)
  def origine?
    :TRUE === @isorigine
  end

  # -- Links Methods --


  # -- Link’s Page Data --

  # [Link::Page|NilClass] Page HTML du lien
  # Elle n’existe que si la page a pu être atteinte
  def page; @page end

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
        File.join(base, cuni)
      end.freeze
    end
  end

  def count
    sources.count
  end

end #/class Link
end #/module LinksChecker

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

  # [Array<LinksChecker::Link>] Array de URI de toutes les sources 
  # qui contiennent ce lien.
  attr_reader :sources

  # [LinksChecker::Link] La première source
  attr_reader :source

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
  # [String|NilClass] Contient le motif éventuel pour lequel le lien
  # n’a pas été checké
  attr_reader :motif_not_check

  def initialize(ini_uri, base, source)
    @base     = base
    @ini_uri  = ini_uri
    # Les sources qui sont identiques
    # (pas sûr que ça serve à quelque chose)
    @sources  = []
    @source   = source
    if source.nil?
      @isorigine = :TRUE
    else
      @isorigine = :FALSE
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
    log("-> check avec #{url.inspect}")

    # Si c’est un lien à éviter
    if (erreur = self.class.href_uncheckable?(ini_uri))
      raise NotCheckableLink.new(erreur)
    end

    # Si c’est un lien dont on n’a pas pu déterminer l’URL
    if url == :UNDEFINED_URL
      raise NotCheckableLink.new(@error)
    end

    begin
      uri = URI(url)
    rescue URI::InvalidURIError => e
      if url.start_with?('https://fr.wikipedia')
        check_with_browser("Invalid URI: #{e.message}")
      else
        raise KnownNetError.new("Invalid URI: #{e.message}")
      end
    rescue Exception => e
      raise UnknownError.new("Erreur URI inconnue : #{e.message} [#{e.class}]\nIl faut la prendre en compte ici : #{__FILE__}:#{__LINE__}")
    end

    begin
      response = Net::HTTP.get_response(uri)
    rescue SocketError => e
      raise KnownNetError.new("Socket Error: #{e.message}")
    rescue NoMethodError => e
      raise KnownNetError.new("No Method Error: #{e.message}")
    rescue Exception => e
      raise UnknownError.new("Erreur HTTP inconnue : #{e.message} [#{e.class}]\nIl faut la prendre en compte ici : #{__FILE__}:#{__LINE__}")
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

      # Validité de la page
      if (error = LinksChecker.page_invalid?(@page))
        raise KnownNetError.new(error)
      else
        # 
        # === SUCCÈS ===
        # 
        # (on peut checker ses liens — sauf si c’est un controle 
        # "flat" — pas "deep" et que la source de ce lien n’est pas
        # nil)
        @success = true
        STDOUT.write(POINT_VERT)
        unless App.option?(:flat) && not(origine?) && not(in_base?)
          page.get_and_check_all_links_in_code
        else
          motif = not(in_base? ? MOTIF_PAGE_HORS_SITE : MOTIF_OPTION_FLAT)
          log(LOG_LINK_NOT_CHECKED % {i:self.object_id,u:url.inspect,m:motif})
        end
      end
    when Net::HTTPMovedPermanently
      check_with_browser("Moved Permanently")
    when Net::HTTPNotFound
      raise KnownNetError.new("HTTP Not Found")
    when Net::HTTPInternalServerError
      check_with_browser("Internal Server Error")
    when Net::HTTPServiceUnavailable
      check_with_browser("Service Unavailable")
    when Net::HTTPForbidden
      check_with_browser("HTTP Forbidden")
    else
      raise UnknownError.new("#{response.class}\nIl faut la prendre en compte ici : #{__FILE__}:#{__LINE__}")
    end

  rescue NotCheckableLink => e
    @success = true
    STDOUT.write(POINT_GRIS)
    @motif_not_check = e.message
    return true
  rescue UnknownError => e
    STDOUT.write(POINT_ROUGE)
    @error = e.message
    log("ERREUR INCONNUE : #{e.message}")
    return false
  rescue KnownNetError => e
    STDOUT.write(POINT_ROUGE)
    @error = e.message
    log("ERREUR NORMALE : #{e.message}")
    return false
  else
    return true
  end

  # On passe par ici quand c’est une lien Amazon, par exemple,
  # qui interdit d’atteindre ses pages sans navigateur
  def check_with_browser(erreur)
    case (retour = Browser.check_with_browser(self))
    when true   then @success = true
    when false  then raise KnownNetError.new(erreur)
    when String then raise KnownNetError.new(retour)
    else
      raise "Je ne sais pas interpréter le retour de Browser#check_with_browser"
    end
    
  end

  LOG_LINK_NOT_CHECKED = <<~TXT.strip.freeze
  Link non checké [LinksChecker::Link #%{i}]
  TAB  URL  : %{u}
  TAB  MOTIF: %{m}
  TXT
  MOTIF_OPTION_FLAT     = "Options -f/--flat et pas le lien originel.".freeze
  MOTIF_PAGE_HORS_SITE  = "Page hors-site"

  # -- Helper Methods --

  # Pour afficher les sources dans un message d’erreur
  def sources_for_error(tab = '')
    stab = "\n#{tab}  - "
    "#{tab}Sources :#{stab}" + sources.map{|s| s.url}.join(stab)
  end

  # -- Predicate Methods --

  def success?
    success === true
  end

  # @return true si c’est le premier lien envoyé
  # (pour savoir, quand c’est :flat, s’il faut traiter ses liens)
  def origine?
    :TRUE === @isorigine
  end

  # @return true si le lien concerne une page du site ou de
  # la partie du site checkée
  def in_base?
    url.start_with?(LinksChecker.base)
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
        if base.nil?
          raise UrlError.new("La base ne peut être NIL…")
        end
        if cuni.nil?
          raise UrlError.new("L’URL relative calculée à partir de #{ini_uri.inspect} est NIL. Impossible de calculer l’URL du [LinksChecker::link ##{object_id}]")
        end
        File.join(base, cuni)
      end.freeze
    rescue UrlError => e
      @error = e.message
      :UNDEFINED_URL
    end
  end

  def count
    sources.count
  end

end #/class Link
end #/module LinksChecker

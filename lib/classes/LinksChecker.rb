module LinksChecker
class << self

  attr_reader :base

  # [Array<Link>] Les liens à checker, éliminter au fur et à 
  # mesure
  LINKS_TO_CHECK = []

  # [Hash<String => Link>] Pour mettre les Links traités (avec en 
  # clé l’URL complète et en valeur l’instance LINK — à incrémenter)
  CHECKED_LINKS   = {}

  # [Array<Link>] Pour mettre les href exclus
  EXCLUDED_LINKS  = []

  # = main =
  # 
  # Méthode principale qui checke tous les liens.
  # 
  # Pour fonctionner, elle tient à jour une liste des liens à 
  # checker qu’elle consulte jusqu’à épuisement
  def check_all_links_from(uri)

    # La page de départ
    add_link_to_check(uri, base, nil)

    while link = LINKS_TO_CHECK.shift
      break if link.nil?
      if CHECKED_LINKS.key?(link.url)
        # HREF déjà connu
        first_link = CHECKED_LINKS[link.url]
        first_link.sources << link.sources.first
        next
      else
        CHECKED_LINKS.merge!(link.url => link)
        # On doit checker ce lien
        link.check
      end
    end

  end

  # Pour ajouter un lien à checker
  # 
  def add_link_to_check(uri, base, source)
    link = Link.new(uri, base, source)
    LINKS_TO_CHECK << link
    return link
  end

  # Pour afficher le résultat final
  # 
  def display_report
    puts "\n---".bleu
    puts "RÉSULTATS\n---------".bleu
    puts "Nombre de liens checkés : #{CHECKED_LINKS.count}".bleu
    puts "\n---".bleu
    puts "LIENS CHECKÉS\n#{'-'*13}".bleu
    CHECKED_LINKS.each do |url, link|
      puts "- #{url}".send(link.success? ? :vert : :rouge)
      unless link.success?
        puts "  #{link.error}".rouge
      end
    end    
  end


  # Définir la base de la recherche, qui n’est pas forcément la
  # base (HOST) du site.
  # 
  def define_base(uri)
    # Pour retirer les ancres et les query-strings
    uri = uri.split('?')[0].split('#')[0]
    # Si uri termine par un fichier .html, .htm, .asp, etc., c’est
    # un fichier, donc pas la base
    uris = uri.split('/')
    last = uris.pop
    exts = File.extname(last)
    if FILE_URI_EXTNAMES[exts]
      @base = uris.join('/')
    else
      uri = uri[0..-2] if uri.end_with?('/')
      @base = uri
    end
    puts "Base = #{@base}".jaune
  end


  # -- Predicate Methods --

  # @param page [Link::Page] Instance de la link-page à checker
  #             Elle est valide si elle contient les sélecteurs
  #             requis et si elle ne contient pas les sélecteurs à
  #             ne pas trouver.
  # @rappel
  #   Les requis sont définis par -r/--require
  #   Les exclus sont définis par -e/--exclude
  def page_invalid?(page)
    if (selectors_requis = App.options[:require])
      # Si un seul sélecteur n’est pas trouvé, on retourne faux
      selectors_requis.each do |selector|
        return "Sélecteur introuvable : #{selector.inspect}" if not(page.contains?(selector))
      end
    end
    if (selectors_error = App.options[:exclude])
      # Si un seul sélecteur est trouvé, on retourne faux
      selectors_error.each do |selector|
        return "Sélecteur indésirable : #{selector.inspect}" if page.contains?(selector)
      end
    end
    return nil
  end


  def bad_extension?(uri)
    file = uri.split('/').last
    ext  = File.extname(file)
    return BAD_EXTENSIONS.key?(ext)
  end

  def same_base?(uri)
    uri.start_with?(base)
  end

  def excluded_base?(uri)
    @excluded_bases ||= ['https://fonts.googleapis.com'].freeze
    @excluded_bases.each do |ebase|
      return true if uri.start_with?(ebase)
    end
    return false
  end

  # def bad_protocol?(uri)
  #   last = uri.split('/').last
  #   return BAD_PROTOCOLS[last.split(':')[0]]
  # end

end #/ << self LinksChecker



  FILE_URI_EXTNAMES = {
    '.htm'  => true,
    '.html' => true,
    '.rb'   => true,
    '.asp'  => true,
  }

  BAD_PROTOCOLS = {
    'mailto' => true
  }

end #/module CheckLinks

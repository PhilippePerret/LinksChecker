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
    source = LINKS_TO_CHECK << Link.new(uri, nil)
    
    while link = LINKS_TO_CHECK.shift
      break if link.nil?
      link.check
      # Si l’option :flat (not :deep) est active et que
      # le lien n’est pas dans la source, on passe à la
      # suite. Note : peut-être qu’on pourrait tout de suite
      # breaker, mais je ne suis pas sûr que les liens se mettent
      # toujours dans l’ordre voulu, donc prudence.
      next if App.option?(:flat) && not(link.sources.include?(source))
    end

  end

  # Pour ajouter un lien à checker
  # 
  def add_link_to_check(uri, source)
    link = Link.new(uri, source)
    LINKS_TO_CHECK << link
    return link
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

  def bad_protocol?(uri)
    last = uri.split('/').last
    return BAD_PROTOCOLS[last.split(':')[0]]
  end

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

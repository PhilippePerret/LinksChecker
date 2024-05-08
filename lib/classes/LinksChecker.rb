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

  # Pour mettre les erreurs dans le rapport final
  TABLEAU_DES_ERREURS = []

  # = main =
  # 
  # Méthode principale qui checke tous les liens.
  # 
  # Pour fonctionner, elle tient à jour une liste des liens à 
  # checker qu’elle consulte jusqu’à épuisement
  def check_all_links_from(uri)

    # La page de départ
    add_link_to_check(uri, base, nil)

    # 
    # == Contrôle de tous les liens ==
    # 
    while link = LINKS_TO_CHECK.shift
      break if link.nil?
      is_known_link = CHECKED_LINKS.key?(link.url)
      log(LOG_CHECKED_LINK % {i:link.object_id, u:link.url.inspect, k: (is_known_link ? "KNOWN LINK [Link ##{CHECKED_LINKS[link.url].object_id}" : "NEW LINK")})
      if is_known_link
        #
        # HREF déjà connu
        # 
        # => On ajoute simplement la source
        # 
        known_link = CHECKED_LINKS[link.url]
        known_link.sources << link.sources.first
        STDOUT.write(POINT_GRIS)
        next
      else
        #
        # Nouveau HREF
        # 
        CHECKED_LINKS.merge!(link.url => link)
        # On doit checker ce lien
        link.check
      end
    end

  end

  LOG_CHECKED_LINK = <<~TXT.strip.freeze
  CHECK LINK [LinksChecker::Link #%{i}] %{u}
  TAB %{k}
  TXT
  
  # Pour ajouter un lien à checker
  # 
  # @note
  #   On les met absolument tous, même si ce sont des liens déjà
  #   checkés. C’est ensuite seulement qu’on procède à la simpli-
  #   fication et qu’on ne checke que les url non traitées.
  # 
  def add_link_to_check(uri, base, source)
    link = Link.new(uri, base, source)
    log(LOG_ADD_LINK_TO_CHECK % {i: link.object_id, u:uri.inspect, b:base.inspect, s:"#{source.class} ##{source.object_id}", l:link.url})
    LINKS_TO_CHECK << link
    return link
  end

  LOG_ADD_LINK_TO_CHECK = <<~TXT.freeze
  LINKS_TO_CHECK << link [Link #%{i}]
  TAB  uri :   %{u}
  TAB  base:   %{b}
  TAB  url :   %{l}
  TAB  source: [%{s}]
  TXT

  # Pour afficher le résultat final
  # 
  def display_report
    # S’il faut afficher les sources
    afficher_sources = App.option?(:sources)

    # Calcul du nombre d’erreurs rencontrées
    nombre_erreurs = 0
    CHECKED_LINKS.each do |url, link|
      link.success? || (nombre_erreurs += 1)
    end
    nombre_erreurs_str = nombre_erreurs.to_s.send(nombre_erreurs > 0 ? :rouge : :vert)
    zero_erreurs = nombre_erreurs == 0

    unless verbose?
      clear clear
    end

    # 
    # Tableau final
    # 
    puts "\n---".bleu
    titre = "RÉSULTAT DU CHECK DES LIENS DU #{Time.now.strftime(SIMPLE_TIME_FORMAT)}"
    puts "#{titre}\n#{'-'*titre.length}".bleu
    
    # Origine
    puts "ORIGINE : #{App.origine}".bleu

    # Titre des liens checkés
    puts "LIENS CHECKÉS\n#{'-'*13}".bleu

    index_len = 2 + CHECKED_LINKS.count.to_s.length
    tab_info  = ' ' * (index_len + 1)
    en_mode_deep = not(App.option?(:flat))

    TABLEAU_DES_ERREURS.clear

    # Boucle sur tous les liens checkés
    CHECKED_LINKS.each_with_index do |dlink, idx|
      
      url, link = dlink
      failed = not(link.success?)

      # La couleur en fonction du succès du lien
      color = link.success? ? :vert : :rouge

      # L’index du lien
      index_lien = "[#{idx+1}]".ljust(index_len)
      
      # Titre du lien
      str = "#{index_lien} #{url}".send(color) 
      puts str
      TABLEAU_DES_ERREURS << str if failed

      # En cas d’échec, on affiche l’erreur
      if failed
        str = "  #{link.error || "- erreur indéfinie -"}".rouge
        puts str
        TABLEAU_DES_ERREURS << str
      end

      # Sources (nombre ou détail)
      if en_mode_deep
        if afficher_sources || failed
          str = link.detailled_sources(tab_info).send(color)
          puts str
          TABLEAU_DES_ERREURS << str if failed
        else
          puts "#{tab_info}Sources : #{link.count}".send(color)
        end
      else
        # Si on n’est pas en mode profond, on s’assure juste
        # qu’il y a bien une seule source (l’origine donnée)
        if link.count > 1
          raise ERRORS[7000] % {n: link.count}
        end
      end
    end #/boucle sur CHECKED_LINKS
  
    # On remet les erreurs à la fin si on en a trouvées.
    if TABLEAU_DES_ERREURS.any?
      puts "---".bleu
      tit = "LISTE DES ERREURS (#{nombre_erreurs})"
      puts tit.rouge
      puts ('-'*tit.length).rouge
      puts TABLEAU_DES_ERREURS.join("\n")
    end

    # Le résumé final
    puts "\n\n"
    puts "RÉSUMÉ FINAL".bleu
    puts "------------".bleu
    puts "ORIGINE : #{App.origine}".jaune
    puts "MODE    : #{en_mode_deep ? "PROFOND" : "PAGE SEULE"}".bleu
    puts "NOMBRE DE LIENS CHECKÉS  : #{CHECKED_LINKS.count}".bleu
    if zero_erreurs
      puts "🍺 Tous les liens/pages testés sont valides".vert
    else
      puts "💣 NOMBRE TOTAL D’ERREURS : #{nombre_erreurs_str}".bleu
    end
    puts "---".bleu

  end #/display_report


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

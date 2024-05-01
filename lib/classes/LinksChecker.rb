module LinksChecker

  def self.run
    clear
    clear
    uri = check_console

    if options['h']
      afficher_aide
      return
    end

    # uri ||= Q.ask("URL à checker : ".jaune, **{default:'https://www.atelier-icare.net/4pour2/index.htm'})
    uri ||= Q.ask("URL à checker : ".jaune, **{default:'https://www.icare-editions.fr'})
    
    clear
    puts "CHECK DES LIENS DE : #{uri}".jaune
    puts "Options : #{options.keys.join(', ')}".jaune unless options.empty?
    puts "(options -h pour voir l’aide)".gris
    puts "---".jaune

    define_base(uri)
    # uri = Q.ask("URL à checker : ".jaune, **{default:'https://rien.com'})
    begin
      checker = Checker.check(uri)
      if checker
        # L’URL a pu être checkée (même si des liens n’ont pas été trouvés)
        checker.display_report
      else
        puts "Entrez une URL valide.".rouge
        puts "(erreur : #{Checker::CHECKED_LINKS[uri][:error]})".rouge
      end
    rescue Interrupt => e
      self.report_on_interrupt
    # rescue Exception => e
    #   puts "class erreur : #{e.class}"
    end
  end


  def self.base; @@base end
  def self.options; @@options end


  def self.define_base(uri)
    # Si uri termine par un fichier .html, .htm, .asp, etc., c’est
    # un fichier, donc pas la base
    uris = uri.split('/')
    last = uris.pop
    exts = File.extname(last)
    if FILE_URI_EXTNAMES[exts]
      @@base = uris.join('/')
      # On entre la base comme bon lien (c’est surtout utile
      # lorsque l’on donne une adresse avec un fichier)
      url     = LinksChecker::Url.new(@@base)
      checker = Checker.new(url)
      Checker::CHECKED_LINKS.merge!(@@base => {
        url: url,
        checker: checker,
        count: 1,
        ok: true,
        error: nil,
        owner: nil
      })
    else
      @@base = uri
    end
    puts "Base = #{@@base}".jaune
  end


  def self.report_on_interrupt
    clear
    puts "Interruption du test… Rapport actuel :"
    Checker::CHECKED_LINKS.each do |uri, duri|
      puts "URI : #{uri}"
    end
  end

  # -- Functional Methods --

  # @return [String|Nil] Éventuellement l’adresse (URI) fournie
  # en premier argument
  def self.check_console
    @@options = {}
    uri = nil
    ARGV.each_with_index do |v, idx|
      if v.start_with?('--')
        @@options.merge!(v[2..-1] => true)
      elsif v.start_with?('-')
        @@options.merge!(v[1..-1] => true)
      else
        uri = v
      end
    end
    return uri
  end

  # -- Predicate Methods --

  def self.bad_extension?(uri)
    file = uri.split('/').last
    ext  = File.extname(file)
    return BAD_EXTENSIONS.key?(ext)
  end

  def self.same_base?(uri)
    uri.start_with?(base)
  end

  def self.excluded_base?(uri)
    @@excluded_bases ||= ['https://fonts.googleapis.com'].freeze
    @@excluded_bases.each do |ebase|
      return true if uri.start_with?(ebase)
    end
    return false
  end

  def self.bad_protocol?(uri)
    last = uri.split('/').last
    return BAD_PROTOCOLS[last.split(':')[0]]
  end

  def self.verbose?
    options['v']||options['verbose']
  end

  # -- Aide --

  def self.afficher_aide
    puts <<~TXT
    La commande #{j'check-links'} permet de vérifier la validité des
    liens d’un site internet.

    Arguments
    ---------

    On peut mettre en premier argument l’adresse (URL) du site. Par
    exemple : #{j'check-links https://www.atelier-icare.net'}.

    l’URI peut être aussi un fichier précis, de type HTML, ruby ou
    asp par exemple.

    Options
    -------

      #{j'-v/--verbose'} 
         En fin de processus, affiche toutes les URI traitées.
         En mode verbose, lorsque la liste des liens vérifié est
         affichée, on indique par "[deep]" le fait qu’on vérifie
         aussi la page du lien pour voir les href qu’elle contient.
         
    TXT
  end

  def self.j(str)
    str.jaune
  end


  BAD_EXTENSIONS = {
    '.css'  => true,
    '.js'   => true,
    '.png'  => true,
    '.jpg'  => true,
    '.jpeg' => true,
    '.web'  => true,
  }

  FILE_URI_EXTNAMES = {
    '.htm'  => true,
    '.html' => true,
    '.rb'   => true,
    '.asp'  => true,
  }

  BAD_PROTOCOLS = {
    'mailto' => true
  }
end

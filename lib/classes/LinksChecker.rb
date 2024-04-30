module LinksChecker

  def self.run
    clear
    clear
    # uri = Q.ask("URL à checker : ".jaune, **{default:'https://www.atelier-icare.net/4pour2/index.htm'})
    uri = Q.ask("URL à checker : ".jaune, **{default:'https://www.icare-editions.fr'})
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
  end


  def self.report_on_interrupt
    clear
    puts "Interruption du test… Rapport actuel :"
    Checker::CHECKED_LINKS.each do |uri, duri|
      puts "URI : #{uri}"
    end
  end


  def self.bad_extension?(uri)
    file = uri.split('/').last
    ext  = File.extname(file)
    return BAD_EXTENSIONS.key?(ext)
  end

  def self.same_base?(uri)
    uri.start_with?(base)
  end

  def self.bad_protocol?(uri)
    last = uri.split('/').last
    return BAD_PROTOCOLS[last.split(':')[0]]
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

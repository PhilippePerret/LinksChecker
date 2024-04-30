module LinksChecker

  def self.run
    clear
    clear
    uri = Q.ask("URL à checker : ".jaune, **{default:'https://www.atelier-icare.net'})
    define_base(uri)
    # uri = Q.ask("URL à checker : ".jaune, **{default:'https://rien.com'})
    begin
      checker = Checker.check(uri)
      if checker
        # L’URL a pu être checkée (même si des liens n’ont pas été trouvés)
        checker.display_report
      else
        puts "Entrez une URL valide.".rouge
      end
    rescue Interrupt => e
      self.report_on_interrupt
    # rescue Exception => e
    #   puts "class erreur : #{e.class}"
    end
  end

  def self.same_base?(uri)
    uri.start_with?(base)
  end

  def self.base; @@base end

  def self.define_base(uri)
    @@base = uri
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
  BAD_EXTENSIONS = {
    '.css'  => true,
    '.js'   => true,
    '.png'  => true,
    '.jpg'  => true,
    '.jpeg' => true,
    '.web'  => true,
  }
end

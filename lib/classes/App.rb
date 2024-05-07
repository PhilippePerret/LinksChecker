module LinksChecker

  def option?(opt)
    return App.option?(opt)
  end

class App
class << self

  attr_reader :options

  # -- Predicate Methods --

  def option?(opt)
    options[opt]
  end

  def verbose?
    options[:verbose] === true
  end

  # -- Functional Methods --

  def run
    clear
    clear

    uri = check_console

    return afficher_aide if option?(:help)

    # uri ||= Q.ask("URL à checker : ".jaune, **{default:'https://www.atelier-icare.net/4pour2/index.htm'})
    uri ||= Q.ask("URL à checker : ".jaune, **{default:'https://www.icare-editions.fr'})
    
    clear
    puts "CHECK DES LIENS DE : #{uri}".jaune
    puts "Options : #{options.keys.join(', ')}".jaune unless options.empty?
    puts "(option -h/--help pour voir l’aide)".gris
    puts "---".jaune

    LinksChecker.define_base(uri)

    # uri = Q.ask("URL à checker : ".jaune, **{default:'https://rien.com'})
    begin
      LinksChecker.check_all_links_from(uri)
      LinksChecker.display_report
    rescue Interrupt => e
      report_on_interrupt
    rescue Exception => e
      err = LOG_ERROR % {m:e.message,c:e.class, b:e.backtrace.join(RET)}
      log(err)
      puts err.rouge
    end
  end

  LOG_ERROR = <<~TXT.freeze
  # ERROR: %{m} [%{c}]
  %{b}
  TXT

  ##
  # Affiche le rapport de check du lien 
  # 
  def display_report

    nombre_total = 0
    CHECKED_LINKS.values.each {|d| nombre_total += d[:count] }
    puts "Nombre de liens différents vérifiés  : #{CHECKED_LINKS.count}".bleu
    puts "Nombre total de liens HREF consultés : #{nombre_total}".bleu
    bad_links = CHECKED_LINKS.values.reject do |durl|
      durl[:ok]
    end
    if bad_links.count > 0
      puts "NOMBRE DE LIENS ERRONÉS : #{bad_links.count}".rouge
      bad_links.each do |durl|
        url = durl[:url]
        puts "- #{url.uri_string} (#{url. class_error} #{url.rvalue})".rouge
        puts "  (dans #{durl[:owner].uri_string})".gris
      end
      puts "\nCes liens sont à corriger."
    else
      puts "🎉 TOUS LES LIENS SONT VALIDES. 👍".vert
    end

    if verbose?
      puts "---\nLIENS VÉRIFIÉS\n#{'-'*14}".jaune
      CHECKED_LINKS.each do |uri, duri|
        deep = duri[:url].same_base? ? " [deep]" : ""
        puts "- #{uri}#{duri[:error] ? " (#{duri[:error]})" : ""}#{deep}".send(duri[:ok] ? :vert : :rouge)
      end
      puts "\nHREF EXCLUS\n#{'-'*11}".jaune
      EXCLUDED_LINKS.each do |href, dhref|
        puts "- #{href} (#{dhref[:raison]})".orange
      end
    end

  end

  def report_on_interrupt
    clear
    puts "Interruption du test… Rapport actuel :"
    LinksChecker::CHECKED_LINKS.each do |uri, duri|
      puts "URI : #{uri}"
    end
  end

  # -- Functional Methods --

  # @return [String|Nil] Éventuellement l’adresse (URI) fournie
  # en premier argument
  def check_console(arguments = ARGV)
    @options ||= {}
    uri = nil
    @args = arguments.dup # ARGV.dup

    while (arg = @args.shift)
      if arg.start_with?('--')
        k = arg[2..-1].to_sym
        define_key_option(k)
      elsif arg.start_with?('-')
        k = arg[1..-1]
        k = OPTS_SHORT_TO_LONG[k] || k
        define_key_option(k)
      else
        uri = arg
      end
    end

    # Si les données sont dans un fichier infos (chargé avec
    # l’option ’-i <fichier>’ )
    if option?(:infos)
      path_infos = File.expand_path(File.join('.', options[:infos]))
      File.exist?(path_infos) || begin
        raise "Le fichier d’info #{path_infos.inspect} est introuvable."
      end
      ars = IO.read(path_infos).gsub(/\n/,' ').strip.split(' ')
      options.delete(:infos)
      uri = check_console(ars)
    end


    return uri
  end

  def define_key_option(k)
    value = 
      case k
      when :infos
        @args.shift
      when :require, :exclude
        selector = @args.shift
        (@options[k]||[]) << selector
      else
        true
      end

    @options.merge!(k => value)    
  end

  # -- Aide --

  def afficher_aide
    path_help = File.join(LOCALES_FOLDER,'help.rb.txt')
    txt = eval('"'+IO.read(path_help).gsub(/"/,'\"')+'"')
    less txt
  end

  def j(str)
    str.jaune
  end

end #/ << self LinksChecker::App


  OPTS_SHORT_TO_LONG = {
    'h' => :help,
    'i' => :infos,
    'f' => :flat,
    'r' => :require,
    'e' => :exclude,
    'v' => :verbose,
  }

end #/class App
end #/module CheckLinks

module LinksChecker

  def option?(opt)
    return App.option?(opt)
  end

class App
class << self

  attr_reader :options

  # [String] Origine (lien) fournie au départ
  attr_reader :origine

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
      @origine = uri
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

  def report_on_interrupt
    clear
    puts "Interruption du test… Rapport actuel :".rouge
    LinksChecker.display_report
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
    'e' => :exclude,
    'f' => :flat,
    'h' => :help,
    'i' => :infos,
    'r' => :require,
    's' => :sources,
    'v' => :verbose,
  }

end #/class App
end #/module CheckLinks

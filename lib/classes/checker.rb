module LinksChecker
class Checker

  CHECKED_LINKS = {}

  ##
  # Méthode principale qui checker TOUS les liens
  # 
  def self.check(uri)
    uri = uri[0..-2] if uri.end_with?('/')
    # 
    # On ne fouille que les pages de même origine
    # On ne fouille pas les scripts et les css
    # 
    if not(LinksChecker.same_base?(uri)) || LinksChecker.bad_extension?(uri)
      STDOUT.write POINT_GRIS
      return false
    end

    if CHECKED_LINKS.key?(uri)
      # 
      # Une URI déjà connue
      # 
      CHECKED_LINKS[uri][:count] += 1
      STDOUT.write CHECKED_LINKS[uri][:ok] ? POINT_VERT : POINT_ROUGE
      return true
    else
      # 
      # Une nouvelle URI à checker
      # 
      url = LinksChecker::Url.new(uri)
      checker = Checker.new(url)
      res = nil
      begin
        Timeout.timeout(20, TimeoutError) do
          CHECKED_LINKS.merge!(uri => {url: url, checker: checker, count: 1, ok: "-en cours de test-"})
          res = checker.check_links
        end
      rescue TimeoutError => e
        res = false
        CHECKED_LINKS[uri].merge!(error: "timeout")
      end
      CHECKED_LINKS[uri].merge!(ok: res, error: checker.error)
      STDOUT.write res ? POINT_VERT : POINT_ROUGE
      return res ? checker : false
    end
  end

  # === INSTANCE ===

  attr_reader :url

  attr_reader :error

  # Instanciation d'un test
  # 
  # @param url [LinksChecker::Url] Instance URL ou code
  # 
  def initialize(url)
    @url = url
  end

  ##
  # Affiche le rapport de check du lien 
  # 
  def display_report
    puts "\n---"
    puts "Nombre de liens checkés : #{CHECKED_LINKS.count}".bleu
    bad_links = CHECKED_LINKS.values.reject do |durl|
      durl[:ok]
    end
    puts "Liens erronés : #{bad_links.count}"
    bad_links.each do |durl|
      puts "- #{durl[:url].uri_string}".rouge
    end
  end

  # @return true si le lien n’a pas été trouvé
  def not_ok?
    not(error.nil?)
  end

  ##
  # Méthode principale pour checker les liens
  # 
  # @api
  # 
  def check_links
    if url.ok?
      # 
      # On peut checker les liens
      # 
      url.links.each(&:check)
      return true
    else
      if url.redirection?
        puts "Je dois rediriger ’#{uri}’ vers ’#{url.redirect_to}’.".orange
        return true
      else
        @error = url.rvalue
        return false
      end
    end    
  end

  def uri
    @uri ||= url.uri_string.freeze
  end

end #/class Checker
end #/module LinksChecker

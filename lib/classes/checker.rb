module LinksChecker
class Checker

  # Pour mettre les href traités
  CHECKED_LINKS   = {}

  ##
  # Méthode principale qui checker TOUS les liens
  # 
  # @param params [Hash]
  #   owner: [LinksChecker::Url] La page propriétaire du lien uri
  # 
  def self.check(uri, **params)
    uri = uri[0..-2] if uri.end_with?('/')
    # 
    # On ne fouille que les pages de même origine
    # On ne fouille pas les scripts et les css
    # 
    begin
      if LinksChecker.bad_protocol?(uri) 
        raise "protocol"
      elsif LinksChecker.bad_extension?(uri)
        raise "extension"
      elsif LinksChecker.excluded_base?(uri)
        raise "autre site"
      end
    rescue Exception => e
      EXCLUDED_LINKS.merge!(uri => {raison: e.message})
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
          CHECKED_LINKS.merge!(uri => {url: url, owner: params[:owner], checker: checker, count: 1, ok: "-en cours de test-"})
          res = url.ok?
          # On ne teste ses liens que si la page appartient à la
          # base et que l’option --flat (-f) n’est pas utilisée
          if res && url.same_base?
            res = checker.check_links
          end
        end
      rescue TimeoutError => e
        res = false
        CHECKED_LINKS[uri].merge!(error: "-timeout-")
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

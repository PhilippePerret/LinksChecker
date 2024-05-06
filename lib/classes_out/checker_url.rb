require 'net/http'
require 'nokogiri'

module LinksChecker
class Url

  attr_reader :uri_string
  alias :base :uri_string

  # @return la response.value et la classe de l’erreur
  # @note Il faut que #code_html ou #read ait été appelé avant pour
  # que ces valeurs soient définies
  attr_reader :rvalue, :class_error


  # Instanciation d'un test
  # 
  # @param uri [String] URL ou code
  # 
  def initialize(uri)
    uri = uri.strip
    uri = uri[0..-2] if uri.end_with?('/')
    uri = immediate_transformations(uri)
    @uri_string = uri.strip
  end

  GOOD_YT_LINKS = 'https://www.youtube.com/watch?v=%{ytid}'.freeze

  # Certains liens qu’on connait, comme ceux vers une vidéo youtube
  # peuvent être transformés tout de suite.
  def immediate_transformations(uri)
    if uri.start_with?('https://youtu.be')
      ytid = uri.split('/').last
      uri = GOOD_YT_LINKS % {ytid: ytid}
    end
    return uri
  end

  # @return Nokogiri Document
  def nokogiri
    @nokogiri ||= Nokogiri::XML(code_html)#.tap { |n| dbg("Classe : #{n.class}".bleu)}
  end

  # @return [Array<Url::Link>] La liste des liens de la page
  # 
  def links
    nokogiri.css("*[href]").map do |node|
      href = node.attribute('href').to_s
      # href = href.split('?')[0] if href.match?(/\?/) # On garde les query-string
      href = href.split('#')[0] if href.match?(/\#/)
      Link.new(self, href)
    end
  end

  # -- Predicate Methods --

  # @return true si ce lien est sur la même base (donc si c’est une
  # page du site checké)
  def same_base?
    LinksChecker.same_base?(uri_string)
  end

  # @return true si la page a pu être chargée correctement
  def ok?
    not(code_html.nil?)
  end

  # @return true si la page est une redirection
  # @note la redirection se trouve dans @redirect_to
  def redirection?
    code_html.nil? && not(@redirect_to.nil?)
  end

  # @return la redirection
  # 
  # @note Il faut avoir appelé #code_html ou #read avant de
  # pouvoir l'utiliser.
  def redirect_to
    @redirect_to
  end


  def code_html
    @code_html ||= readit
  end
  
  def readit

    if uri_string.start_with?('http')
      #
      # Une URI valide avec le bon protocole 'http'
      # 

      # Si c’est une adresse Amazon, il faut utiliser Selenium
      # car Amazon ne laisse pas atteindre ses pages sans passer
      # par un navigateur
      if uri_string.start_with?('https://www.amazon.')
        asin = uri_string.split('/').last
        require "#{MODULES_PATH}/Amazon_checker"
        if Amazon::AsinChecker.check(asin)
          # OK
          @rvalue = "200"
          return "<Page Amazon Atteinte>"
        else
          # Not OK
          @rvalue = "404 Page Amazon introuvable"
          return
        end
      end

      # Un URI normale
      begin
        uri = URI(uri_string)
      rescue URI::InvalidURIError => e
        @rvalue = "URL invalide : #{e.message}"
        return
      end
      
      begin
        response = Net::HTTP.get_response(uri)
      rescue SocketError => e
        @rvalue = e.message.match(/([4][0-9][0-9])/).to_a[1].to_i
        @class_error = "SocketError"
        return
      rescue Net::HTTPServerException => e
        @rvalue = e.message.match(/([4][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPServerException"
        return
      rescue Net::HTTPClientException => e
        @rvalue = e.message.match(/([4][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPClientException"
        return
      end

      begin

        # Pour laisser sa chance à CURL
        begin
          @rvalue = response.value
        rescue Exception => e
          # -I => seulement l’entête
          # -L => suivre les redirections
          # -k => apparemment, pour https, mais ça semble marcher sans
          res = `cUrl -k -I -L #{uri_string}`
          raise e if res.match?(/HTTP\/[0-9] 404/) || res.match?(/Error 404/)
          return # ok
        end

      rescue Net::HTTPFatalError => e
        @rvalue = e.message.match(/([0-7][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPFatalError"
        return
      rescue Net::HTTPRetriableError => e
        @rvalue = e.message.match(/([0-7][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPRetriableError"
        return
      rescue Net::HTTPServerException => e
        @rvalue = e.message.match(/([4][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPServerException"
        return
      rescue Net::HTTPClientException => e
        @rvalue = e.message.match(/([4][0-9][0-9])/).to_a[1].to_i
        @class_error = "Net::HTTPClientException"
        return
      end

      case response
      when Net::HTTPSuccess
        body = response.body # toute la page html
        @rvalue = response.code.to_i
        # dbg("response.value = #{response.methods.inspect}".bleu)
        # dbg("response.code = #{response.code.inspect}".bleu)
        if body.match?(REG_REDIRECTION)
          #
          # -- la page html définit une redirection par
          #    balise meta --
          # 
          @redirect_to = body.match(REG_REDIRECTION).to_a[1].strip
          return nil
        else
          # 
          # Un corps de page normal (note : <html>...</html>)
          # 
          return body
        end
      when Net::HTTPRedirect
        @redirect_to = response['location']
        return nil
      else
        return nil
      end
    elsif uri_string.start_with?('<') && uri_string.end_with?('>')
      uri_string
    else
      raise ArgumentError.new(ERRORS[201] % {a:uri_string.inspect})
    end
  end

  REG_REDIRECTION = /<meta.+http-equiv="refresh".+content="[0-9]+;(.+)">/.freeze


end #/class Url
end #/module LinksChecker

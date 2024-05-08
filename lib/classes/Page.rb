require 'nokogiri'
module LinksChecker
class Link
class Page

  # Une instance [Link::Page]
  # La page correspondant à un lien [Link]. C’est la page en temps 
  # qu’élément HTML


  # [LinksChecker::Link] Le link contenant la page
  # Plus exactement : qui permet d’obtenir la page HTML courante,
  # qui y conduit quand elle a pu être lue.
  attr_reader :source

  # [String] Le code HTML complet de la page
  # Noter que ça peut être une page contenant une erreur et ne 
  # correspondant pas à la page recherchée.
  attr_reader :code_html

  def initialize(source, code_html)
    @source     = source
    @code_html  = code_html
  end

  # [Nokogiri Document]
  def html
    @html ||= Nokogiri::XML(code_html)#.tap { |n| dbg("Classe : #{n.class}".bleu)}
  end

  # @main
  # 
  # Méthode permettant de relever tous les liens HREF dans la page
  # et de les injecter dans les liens à contrôler
  # 
  # @note
  #   Nokogiri est déficiant ici car il remplace les :
  #     ?s=var&t=valeur&x=autre
  #   … par :
  #     ?s=var=valeur=autre
  # 
  # @return [Anything]
  # 
  def get_and_check_all_links_in_code
    hfl = {} # Pour Href Found List
    body.scan(REG_HREF).each do |href| 
      href = href[0]
      hfl.key?(href) ? next : hfl.merge!(href => true)
      LinksChecker.add_link_to_check(href, base, source)
    end
  end
  REG_HREF = /href=\"(.+?)\"/.freeze

  def body
    @body ||= begin
      code_html_min = code_html.downcase
      input = code_html_min.index('<body'.freeze)
      if input.nil?
        # <= On ne trouve pas la balise body
        # => On retourne le code entier
        return code_html_min
      end
      input   = code_html_min.index('>'.freeze, input)
      output  = code_html_min.index('</body>')
      code_html[input+1...output]
    end
  end

  # -- Predicate Methods --

  def contains?(selector)
    res = html.css("BODY,body").css(selector)
    return not(res.empty?)
  end

  def head_contains?(selector)
    res = html.css("HEAD,head").css(selector)
    return not(res.empty?)
  end

  # -- Data Methods --


  # [String] Base de la page. Soit celle définie dans sa 
  # balise meta, soit la base principale, de LinksChecker
  def base
    @base ||= begin
      if (found = code_html.match(REG_BASE))
        found = found[1]
        found = found[0..-2] if found.end_with?('/')
      end
      found || LinksChecker.base
    end
  end

  REG_BASE = /<base href="(.+)">/.freeze


end #/class Page
end #/class Link
end #/module LinksChecker

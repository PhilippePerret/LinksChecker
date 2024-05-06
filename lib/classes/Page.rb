require 'nokogiri'
module LinksChecker
class Link
class Page

  # Une instance [Link::Page]
  # La page correspondant à un lien [Link]. C’est la page en temps 
  # qu’élément HTML


  # [LinksChecker::Link] La lien virtuel contenant la page
  # Plus exactement : qui permet d’obtenir la page courante
  attr_reader :owner_link

  # [String] Le code HTML complet de la page
  # Noter que ça peut être une page contenant une erreur et ne 
  # correspondant pas à la page recherchée.
  attr_reader :code_html

  def initialize(owner_link, code_html)
    @owner_link = owner_link
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
  def get_and_check_all_links_in_code
    html.css("BODY,body").css("*[href]").map do |node|
      href = node.attribute('href').to_s
      href = href.split('#')[0] if href.match?(/\#/)
      # Link.new(href, base, owner_link)
      LinksChecker.add_link_to_check(href, base, owner_link)
    end

    # code_html.scan(/href="(.+?)"/i).each do |find|
    #   href = find[0]
    #   thelink = Link.new(href, self)
    #   if (err = self.class.href_uncheckable?(href)).nil?
    #     puts "Bon: #{href}".vert
    #   else
    #     EXCLUDED_LINKS << thelink
    #     puts "Bad: #{href} (#{err})".rouge
    #   end
    # end
  end

  # -- Predicate Methods --

  def contains?(selector)
    res = html.css("BODY,body").css(selector)
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

  REG_BASE = /<base href="(.+)">/
end #/class Page
end #/class Link
end #/module LinksChecker

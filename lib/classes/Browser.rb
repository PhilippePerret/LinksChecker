require 'selenium-webdriver'    

module LinksChecker
class Browser
class << self
  # 
  # Pour checker une URL not avalaible (comme une URL Amazon)
  # avec un browser par le biais de Selenium
  # 

  ##
  # = main =
  # 
  # Check le lien +link+ [LinksChecker::Link] avec un navigateur
  # 
  # @param link [LinksChecker::Link] Le lien à checker
  # 
  # @return
  #   - true  si la page a pu être atteinte
  #   - false si la page n’a pas pu être atteinte
  #   - Un message d’erreur en cas d’erreur particulière
  # 
  def check_with_browser(link)
    result = {}
    begin
      driver.get link.url
    rescue Exception => e
      return "Impossible d’atteindre la page #{link.url.inspect} : #{e.message} [#{e.class}]"
    end
    # On attend le chargement de la page
    begin
      wait.until { driver.find_element(css: "BODY,body") }
    rescue Selenium::WebDriver::Error::TimeoutError => e
      return "La page ne contient pas de balise body…"
    end

    # On check la page
    if link.url.match?(/amazon\./)
      check_as_amazon_page(link)
    else
      # Pour le moment, si on a pu rejoindre la page par ce biais,
      # on considère qu’elle est bonne.
      return true
    end
  end

  def check_as_amazon_page(link)
    asin = link.url.split('/').last
    # On prend le lien
    begin
      canon_href = driver.find_element(css: 'link[rel="canonical"]')
    rescue Selenium::WebDriver::Error::NoSuchElementError
      canon_href = nil
    end
    if canon_href
      canon_href = canon_href.attribute('href') if canon_href
      ok = canon_href && canon_href.is_a?(String) && canon_href.match?(/#{asin}/)
    else
      ok = false
    end
    if not(ok)
      begin
        span_asin = driver.find_element(css: 'div#rpi-attribute-book_details-isbn10 div.rpi-attribute-value span')
      rescue Selenium::WebDriver::Error::NoSuchElementError
        span_asin = nil
      end
      ok = span_asin && span_asin.text == asin
      if not(ok)
        begin
          span_asin = driver.find_element(tag_name: 'span').find_element(:xpath, ".//*[contains(., \"#{asin}\")]")
        rescue Selenium::WebDriver::Error::NoSuchElementError
          span_asin = nil
        end
        ok = not(span_asin.nil? || span_asin.empty?)
      end
    end
    return ok
  end

  def reset
    driver && driver.close
    @driver = nil
  end

  def driver
    @driver ||= Selenium::WebDriver.for(:firefox)
  end

  def wait
    @wait ||= Selenium::WebDriver::Wait.new(:timeout => 20)
  end

end #/<< self class Browser
end #/class Browser
end #/module LinksChecker

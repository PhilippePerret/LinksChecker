#
# Pour tester les liens Amazon, il faut passer par Selenium, car on
# ne peut pas utiliser URI ou cUrl
# 
# 
require 'selenium-webdriver'    
module Amazon
class AsinChecker
class << self
  # Reçoit une [Array<String>] Liste d’Asin et
  # @return une [Hash] Table avec en clé l’Asin et en valeur true
  # si la page a été trouvé et false dans le cas contraire.
  def check(asin)
    result = {}
    driver.get "https://www.amazon.fr/dp/#{asin}"
    # On attend le chargement de la page
    sleep 1
    wait.until { driver.find_element(css: "body") }
    # On prend le lien
    canon_href = driver.find_element(css: 'link[rel="canonical"]').attribute('href')
    ok = canon_href && canon_href.is_a?(String) && canon_href.match?(/#{asin}/)
    if not(ok)
      span_asin = driver.find_element(css: 'div#rpi-attribute-book_details-isbn10 div.rpi-attribute-value span')
      ok = span_asin && span_asin.text == asin
      if not(ok)
        span_asin = driver.find_element(tag_name: 'span').find_element(:xpath, ".//*[contains(., \"#{asin}\")]")
        ok = not(span_asin.nil? || span_asin.empty?)
        if not(ok)
          puts "Impossible de trouver #{asin.inspect} dans #{canon_href.inspect}".rouge
          sleep 2
        end
      end
    end
    return ok
  end

  def driver
    @driver ||= Selenium::WebDriver.for(:firefox)
  end

  def wait
    @wait ||= Selenium::WebDriver::Wait.new(:timeout => 20)
  end

end #/<< self
end #/class AsinChecker
end #/module Amazon

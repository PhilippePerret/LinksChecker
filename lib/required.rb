require 'clir'
require 'date'
require 'yaml'
require 'timeout'

require_relative 'constants'
require_relative 'divers/Log'
require_relative 'classes/App'
require_relative 'classes/LinksChecker'
# require_relative 'classes/checker_url'
# require_relative 'classes/checker'
require_relative 'classes/Link'
require_relative 'classes/Page'
require_relative 'classes/Browser'

# Redéfinition de la méthode de clir
def verbose?
  LinksChecker::App.verbose?
end

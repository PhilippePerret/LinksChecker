
LIB_FOLDER  = __dir__
APP_FOLDER  = File.dirname(LIB_FOLDER)
MODULES_PATH = File.join(LIB_FOLDER,'modules')

LANG = 'fr'

YAML_OPTIONS = {symbolize_names:true, aliases:true, permitted_classes:[Date,Integer,Float]}


LOCALE_PATH     = File.join(LIB_FOLDER,'locales')
LOCALES_FOLDER  = File.join(LOCALE_PATH,LANG)
LOCALE_ERR_PATH = File.join(LOCALES_FOLDER,'errors.yaml')
LOCALE_MSG_PATH = File.join(LOCALES_FOLDER,'messages.yaml')
# ERRORS = YAML.safe_load(IO.read(LOCALE_ERR_PATH), **YAML_OPTIONS)
ERRORS = YAML.safe_load(IO.read(LOCALE_ERR_PATH))
# MESSAGES = YAML.safe_load(IO.read(LOCALE_MSG_PATH), **YAML_OPTIONS)
MESSAGES = YAML.safe_load(IO.read(LOCALE_MSG_PATH))


POINT_VERT = '.'.vert.freeze
POINT_ROUGE = '.'.rouge.freeze
POINT_GRIS = '.'.gris.freeze

class TimeoutError < StandardError; end

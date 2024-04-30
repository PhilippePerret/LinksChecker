
LIB_FOLDER  = __dir__
APP_FOLDER  = File.dirname(LIB_FOLDER)
LOCALE_PATH = File.join(LIB_FOLDER,'locales')

LANG = 'fr'

YAML_OPTIONS = {symbolize_names:true, aliases:true, permitted_classes:[Date,Integer,Float]}


LOCALE_ERR_PATH = File.join(LOCALE_PATH,LANG,'errors.yaml')
LOCALE_MSG_PATH = File.join(LOCALE_PATH,LANG,'messages.yaml')
# ERRORS = YAML.safe_load(IO.read(LOCALE_ERR_PATH), **YAML_OPTIONS)
ERRORS = YAML.safe_load(IO.read(LOCALE_ERR_PATH))
# MESSAGES = YAML.safe_load(IO.read(LOCALE_MSG_PATH), **YAML_OPTIONS)
MESSAGES = YAML.safe_load(IO.read(LOCALE_MSG_PATH))


POINT_VERT = '.'.vert.freeze
POINT_ROUGE = '.'.rouge.freeze
POINT_GRIS = '.'.gris.freeze

class TimeoutError < StandardError; end

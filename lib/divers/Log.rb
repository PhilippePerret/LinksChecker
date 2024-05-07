# Exposée
def log(msg)
  CheckLinks::Log.log(msg)
end

module CheckLinks
class Log
class << self
  def log(msg)
    msg = msg.gsub(/^TAB/, TAB).strip
    reff.write("#{Time.now.strftime(TIME_FORMAT)} #{msg}\n") 
  end
  TIME_FORMAT = '%d-%m %H:%M:%S.%L'.freeze
  TAB = (' '*18).freeze
  def reff
    @reff ||= begin
      delete
      File.open(path,'a')
    end
  end
  def delete
    File.delete(path) if File.exist?(path)
  end
  def path
    @path ||= File.expand_path(File.join('.','check-links.log')).freeze
  end
end #/ << self
end #/class Log
end #/module CheckLinks

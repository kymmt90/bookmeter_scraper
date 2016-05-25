module BookmeterScraper
  USER_ATTRIBUTES = %i(name id uri)
  User = Struct.new(*USER_ATTRIBUTES)
end

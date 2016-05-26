require 'forwardable'

module BookmeterScraper
  BOOK_ATTRIBUTES = %i(name author read_dates uri image_uri)
  Book = Struct.new(*BOOK_ATTRIBUTES)

  class Books
    extend Forwardable

    def_delegator :@books, :[]
    def_delegator :@books, :[]=
    def_delegator :@books, :<<
    def_delegator :@books, :each
    def_delegator :@books, :flatten!
    def_delegator :@books, :empty?

    def initialize; @books = []; end

    def append(books)
      books.each do |book|
        next if @books.any? { |b| b.name == book.name && b.author == book.author }
        @books << book
      end
    end

    def to_a; @books; end
  end
end

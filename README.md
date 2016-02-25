# Bookmeter Scraper

A library for scraping [Bookmeter](http://bookmeter.com).

Japanese README is [here](https://github.com/kymmt90/bookmeter_scraper/blob/master/README.ja.md).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bookmeter_scraper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bookmeter_scraper


## Usage

Add this line to your code before using this library:

```ruby
require 'bookmeter_scraper'
```

### Log in

You need to log in Bookmeter to get books and followings / followers information by `Bookmeter.log_in`:

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'password')
bookmeter.logged_in?    # true
```

`Bookmeter#log_in` is also available:

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
bookmeter.log_in('example@example.com', 'password')
```

### Get books information

You can get books information:

- read books
- reading books
- tsundoku (stockpile)
- wish list

You need to log in Bookmeter in advance to get these information.

You can get read books information by `Bookmeter#read_books`:

```ruby
books = bookmeter.read_books        # get read books of the logged in user
bookmeter.read_books('01010101')    # get read books of a user specified by ID
```

Books infomation is an array of `Struct` which has `name` and `read_dates` as attributes.
`read_dates` is an array of finished reading dates (first finished date and reread dates):

```ruby
books[0].name
books[0].read_dates
```

You can also get other information:

- `Bookmeter#reading_books`
- `Bookmeter#tsundoku`
- `Bookmeter#wish_list`

```ruby
books = bookmeter.reading_books
books[0].name
books[0].read_dates    # this array is empty

bookmeter.tsundoku
bookmeter.wish_list
```

### Get followings users / followers information

You can get following users (followings) and followers information by `Bookmeter#followings` and `Bookmeter#followers`:

```ruby
following_users = bookmeter.followings
followers = bookmeter.followers
```

You need to log in Bookmeter in advance to get these information.

Users information is an array of `Struct` which has `name` and `id` as attributes.

```ruby
following_users[0].name
following_users[0].id
followers[0].name
followers[0].id
```

#### Notice

**`Bookmeter#followings` and `Bookmeter#followers` have not supported paginated followings / followers pages yet.**

### Get user profile

You can get a user profile by `Bookmeter#profile`:

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
user_id = '000000'
profile = bookmeter.profile(user_id)    # You can specify arbitrary user ID
```

You do not need to log in to get user profiles.
Profile information is `Struct` which has these attributes:

```ruby
profile.name
profile.gender
profile.age
profile.blood_type
profile.job
profile.address
profile.url
profile.description
profile.first_day
profile.elapsed_days
profile.read_books_count
profile.read_pages_count
profile.reviews_count
profile.bookshelfs_count
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kymmt90/bookmeter_scraper.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

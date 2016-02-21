# Bookmeter Scraper

A library for scraping [Bookmeter](http://bookmeter.com).


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

### Get user profile

You can get a user profile.

```ruby
require 'bookmeter_scraper'

bookmeter = BookmeterScraper::Bookmeter.new
user_id = '000000'
profile = bookmeter.profile(user_id)

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

### Get books information only accessible by logged in users

You can get books information which can be browsed by logged in users:

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'password')
bookmeter.logged_in?    # true

user_id = bookmeter.log_in_user_id
books = bookmeter.read_books(user_id)
```

Each book has its name and finished reading dates.
Finished reading dates are ones read by the user specified in an argument `read_books`.

```ruby
books[0].name
books[0].read_dates
```

You can also get other book information:

```ruby
books = bookmeter.reading_books(user_id)
books[0].name
books[0].read_dates    # read_dates is empty

# you can also use these methods
bookmeter.tsundoku(user_id)
bookmeter.wish_list(user_id)
```

### Get followings users / followers information only accessible by logged in users

You can get following users (followings) and followers information which can be browsed by logged in users:

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'password')
bookmeter.logged_in?    # true

following_users = bookmeter.followings
followers = bookmeter.followers
```

Each user struct has its name and user ID:

```ruby
following_users[0].name
following_users[0].id
followers[0].name
followers[0].id
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kymmt90/bookmeter_scraper.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

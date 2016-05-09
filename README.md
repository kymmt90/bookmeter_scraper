# Bookmeter Scraper

[![Gem Version](https://badge.fury.io/rb/bookmeter_scraper.svg)](https://badge.fury.io/rb/bookmeter_scraper)
[![Build Status](https://travis-ci.org/kymmt90/bookmeter_scraper.svg?branch=master)](https://travis-ci.org/kymmt90/bookmeter_scraper)
[![Code Climate](https://codeclimate.com/github/kymmt90/bookmeter_scraper/badges/gpa.svg)](https://codeclimate.com/github/kymmt90/bookmeter_scraper)
[![Test Coverage](https://codeclimate.com/github/kymmt90/bookmeter_scraper/badges/coverage.svg)](https://codeclimate.com/github/kymmt90/bookmeter_scraper/coverage)

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

You need to log in Bookmeter to get books and followings / followers information by `Bookmeter.log_in` or `Bookmeter#log_in`.

There are 3 ways to input authentication information:

1. Passing as arguments
2. Writing out to `config.yml`
3. Configuring in a block

#### 1. Passing as arguments

You can log in Bookmeter by passing mail address and password to `Bookmeter.log_in`:

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in('example@example.com', 'your_password')
bookmeter.logged_in?    # true
```

`Bookmeter#log_in` is also available:

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
bookmeter.log_in('example@example.com', 'password')
```

#### 2. Writing out to `config.yml`

Create `config.yml` as followings and save it to the same directory as your Ruby script:

```yml
mail: example@example.com
password: your_password
```

Now you can log in Bookmeter by calling `Bookmeter.log_in` or `Bookmeter#log_in` with no arguments:

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in
bookmeter.logged_in?    # true
```

#### 3. Configuring in a block

You can configure mail address and password in a block.

```ruby
bookmeter = BookmeterScraper::Bookmeter.log_in do |configuration|
  configuration.mail = 'example@example.com'
  configuration.password = 'password'
end
bookmeter.logged_in?    # true
```

`Bookmeter#log_in` is also available:

```ruby
bookmeter = BookmeterScraper::Bookmeter.new
bookmeter.log_in do |configuration|
  configuration.mail = 'example@example.com'
  configuration.password = 'password'
end
```

### Get books information

You can get books information:

- read books
- reading books
- tsundoku (stockpile)
- wish list

You need to log in Bookmeter in advance to get these information.

#### Read books

You can get read books information by `Bookmeter#read_books`:

```ruby
books = bookmeter.read_books        # get read books of the logged in user
bookmeter.read_books('01010101')    # get read books of a user specified by ID
```

Books infomation is an array of `Book` which has these attributes:

- `name`
- `read_dates`
- `uri`
- `image_uri`

`read_dates` is an array of finished reading dates (first finished date and reread dates):

```ruby
books[0].name
books[0].read_dates
books[0].uri
books[0].image_uri
```

To specify year-month for read books, you can use `Bookmeter#read_books_in`:

```ruby
books = bookmeter.read_books_in(2016, 1)                # get read books of the logged in user in 2016-01
books = bookmeter.read_books_in(2016, 1, '01010101')    # get read books of a user in 2016-01
```

#### Reading books / Tsundoku / Wish list

You can get other books information:

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

Users information is an array of `Struct` which has following attributes:

- `name`
- `id`
- `uri`

```ruby
following_users[0].name
following_users[0].id
following_users[0].uri
followers[0].name
followers[0].id
followers[0].uri
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

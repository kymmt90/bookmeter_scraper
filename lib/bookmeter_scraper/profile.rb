module BookmeterScraper
  PROFILE_ATTRIBUTES = %i(
      name
      gender
      age
      blood_type
      job
      address
      url
      description
      first_day
      elapsed_days
      read_books_count
      read_pages_count
      reviews_count
      bookshelfs_count
    )

  JP_ATTRIBUTE_NAMES = {
    gender: '性別',
    age: '年齢',
    blood_type: '血液型',
    job: '職業',
    address: '現住所',
    url: 'URL / ブログ',
    description: '自己紹介',
    first_day: '記録初日',
    elapsed_days: '経過日数',
    read_books_count: '読んだ本',
    read_pages_count: '読んだページ',
    reviews_count: '感想/レビュー',
    bookshelfs_count: '本棚',
  }

  Profile = Struct.new(*PROFILE_ATTRIBUTES)
end

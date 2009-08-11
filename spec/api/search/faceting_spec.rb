require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'faceting', :type => :search do
  it 'returns field name for facet' do
    stub_facet(:title_ss, {})
    result = session.search Post do
      facet :title
    end
    result.facet(:title).field_name.should == :title
  end

  it 'returns string facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_values(result, :title).should == ['Author 1', 'Author 2']
  end

  it 'returns counts for facet' do
    stub_facet(:title_ss, 'Author 1' => 2, 'Author 2' => 1)
    result = session.search Post do
      facet :title
    end
    facet_counts(result, :title).should == [2, 1]
  end

  it 'returns integer facet' do
    stub_facet(:blog_id_i, '3' => 2, '1' => 1)
    result = session.search Post do
      facet :blog_id
    end
    facet_values(result, :blog_id).should == [3, 1]
  end

  it 'returns float facet' do
    stub_facet(:average_rating_f, '9.3' => 2, '1.1' => 1)
    result = session.search Post do
      facet :average_rating
    end
    facet_values(result, :average_rating).should == [9.3, 1.1]
  end

  it 'returns time facet' do
    stub_facet(
      :published_at_d,
      '2009-04-07T20:25:23Z' => 3,
      '2009-04-07T20:26:19Z' => 1
    )
    result = session.search Post do
      facet :published_at
    end
    facet_values(result, :published_at).should ==
      [Time.gm(2009, 04, 07, 20, 25, 23),
       Time.gm(2009, 04, 07, 20, 26, 19)]
  end

  it 'should return date facet' do
    stub_facet(
      :expire_date_d,
      '2009-07-13T00:00:00Z' => 3,
      '2009-04-01T00:00:00Z' => 1
    )
    result = session.search(Post) do
      facet :expire_date
    end
    facet_values(result, :expire_date).should ==
      [Date.new(2009, 07, 13),
       Date.new(2009, 04, 01)]
  end

  it 'should return boolean facet' do
    stub_facet(:featured_b, 'true' => 3, 'false' => 1)
    result = session.search(Post) { facet(:featured) }
    facet_values(result, :featured).should == [true, false]
  end

  it 'should return class facet' do
    stub_facet(:class_name, 'Post' => 3, 'Namespaced::Comment' => 1)
    result = session.search(Post) { facet(:class) }
    facet_values(result, :class).should == [Post, Namespaced::Comment]
  end

  it 'should return date range facet' do
    stub_date_facet(:published_at_d, 60*60*24, '2009-07-08T04:00:00Z' => 2, '2009-07-07T04:00:00Z' => 1)
    start_time = Time.utc(2009, 7, 7, 4)
    end_time = start_time + 2*24*60*60
    result = session.search(Post) { facet(:published_at, :time_range => start_time..end_time) }
    facet = result.facet(:published_at)
    facet.rows.first.value.should == (start_time..(start_time+24*60*60))
    facet.rows.last.value.should == ((start_time+24*60*60)..end_time)
  end

  it 'should return query facet' do
    stub_query_facet(
      'average_rating_f:[3\.0 TO 5\.0]' => 3,
      'average_rating_f:[1\.0 TO 3\.0]' => 1
    )
    search = session.search(Post) do
      facet :average_rating do
        row 3.0..5.0 do
          with :average_rating, 3.0..5.0
        end
        row 1.0..3.0 do
          with :average_rating, 1.0..3.0
        end
      end
    end
    facet = search.facet(:average_rating)
    facet.rows.first.value.should == (3.0..5.0)
    facet.rows.first.count.should == 3
    facet.rows.last.value.should == (1.0..3.0)
    facet.rows.last.count.should == 1
  end

  it 'returns instantiated facet values' do
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    result = session.search(Post) { facet(:blog_id) }
    result.facet(:blog_id).rows.map { |row| row.instance }.should == blogs
  end

  it 'only queries the persistent store once for an instantiated facet' do
    query_count = Blog.query_count
    blogs = Array.new(2) { Blog.new }
    stub_facet(:blog_id_i, blogs[0].id.to_s => 2, blogs[1].id.to_s => 1)
    result = session.search(Post) { facet(:blog_id) }
    result.facet(:blog_id).rows.each { |row| row.instance }
    (Blog.query_count - query_count).should == 1
  end
end
require 'spec_helper'

describe Chewy::Query::Loading, :orm do
  before { Chewy.massacre }

  before do
    stub_model(:city)
    stub_model(:country)
  end

  context 'multiple types' do
    let(:cities) { 6.times.map { |i| City.create!(rating: i) } }
    let(:countries) { 6.times.map { |i| Country.create!(rating: i) } }

    before do
      stub_index(:places) do
        define_type City do
          field :rating, type: 'integer', value: ->(o){ o.rating }
        end

        define_type Country do
          field :rating, type: 'integer', value: ->(o){ o.rating }
        end
      end
    end

    before { PlacesIndex.import!(cities: cities, countries: countries) }

    describe '#load' do
      specify { expect(PlacesIndex.order(:rating).limit(6).load.total_count).to eq(12) }
      specify { expect(PlacesIndex.order(:rating).limit(6).load).to match_array(cities.first(3) + countries.first(3)) }

      context 'mongoid', :mongoid do
        specify { expect(PlacesIndex.order(:rating).limit(6).load(city: { scope: ->{ where(:rating.lt => 2) } }))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
        specify { expect(PlacesIndex.limit(6).load(city: { scope: ->{ where(:rating.lt => 2) } }).order(:rating))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
        specify { expect(PlacesIndex.order(:rating).limit(6).load(scope: ->{ where(:rating.lt => 2) }))
          .to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }
        specify { expect(PlacesIndex.order(:rating).limit(6).load(city: { scope: City.where(:rating.lt => 2) }))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
      end

      context 'active record', :active_record do
        specify { expect(PlacesIndex.order(:rating).limit(6).load(city: { scope: ->{ where('rating < 2') } }))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
        specify { expect(PlacesIndex.limit(6).load(city: { scope: ->{ where('rating < 2') } }).order(:rating))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
        specify { expect(PlacesIndex.order(:rating).limit(6).load(scope: ->{ where('rating < 2') }))
          .to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }
        specify { expect(PlacesIndex.order(:rating).limit(6).load(city: { scope: City.where('rating < 2') }))
          .to match_array(cities.first(2) + countries.first(3) + [nil]) }
      end
    end

    describe '#preload' do
      context 'mongoid', :mongoid do
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(scope: ->{ where(:rating.lt => 2) })
          .map(&:_object)).to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }
        specify { expect(PlacesIndex.limit(6).preload(scope: ->{ where(:rating.lt => 2) }).order(:rating)
          .map(&:_object)).to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }

        specify { expect(PlacesIndex.order(:rating).limit(6).preload(only: :city, scope: ->{ where(:rating.lt => 2) })
          .map(&:_object)).to match_array(cities.first(2) + [nil] * 4) }
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(except: [:city], scope: ->{ where(:rating.lt => 2) })
          .map(&:_object)).to match_array(countries.first(2) + [nil] * 4) }
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(only: [:city], except: :city, scope: ->{ where(:rating.lt => 2) })
          .map(&:_object)).to match_array([nil] * 6) }
      end

      context 'active record', :active_record do
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(scope: ->{ where('rating < 2') })
          .map(&:_object)).to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }
        specify { expect(PlacesIndex.limit(6).preload(scope: ->{ where('rating < 2') }).order(:rating)
          .map(&:_object)).to match_array(cities.first(2) + countries.first(2) + [nil] * 2) }

        specify { expect(PlacesIndex.order(:rating).limit(6).preload(only: :city, scope: ->{ where('rating < 2') })
          .map(&:_object)).to match_array(cities.first(2) + [nil] * 4) }
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(except: [:city], scope: ->{ where('rating < 2') })
          .map(&:_object)).to match_array(countries.first(2) + [nil] * 4) }
        specify { expect(PlacesIndex.order(:rating).limit(6).preload(only: [:city], except: :city, scope: ->{ where('rating < 2') })
          .map(&:_object)).to match_array([nil] * 6) }
      end
    end
  end
end

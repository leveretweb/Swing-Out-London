class MoveDataToNewEventTables < ActiveRecord::Migration

  class EventSeed <  ActiveRecord::Base
    belongs_to :event
    belongs_to :venue
  end
  class EventGenerator < ActiveRecord::Base
    belongs_to :event_seed
  end
  class DanceClass < ActiveRecord::Base
    belongs_to :venue
  end

  def change
    Event.active.each do |event|
      if event.weekly? && event.has_class?
        create_dance_class(event)
      end

      if event.has_social?
        event.title = event.title.strip
        event.save

        event_seed = create_event_seed(event)

        if event.frequency == 1
          start_date = event.first_date || same_weekday_in_the_past(event.day)
          create_event_generator(1, start_date, event, event_seed)
        else
          event.dates.each do |date|
            create_event_generator(0, date, event, event_seed)
          end
        end
      end
    end

    # Destroy data we're not migrating at the moment:

    # TODO: The following basically means event=social in the new model. Not sure that's right
    non_socials = Event.where(has_class: true, has_social: false)
    non_socials.destroy_all

    Event.ended.destroy_all

    change_table :events do |t|
      t.rename :title, :name

      t.remove :day
      t.remove :event_type
      t.remove :venue_id            #-> EventSeed
      t.remove :frequency           #-> EventGenerator
      t.remove :url                 #-> EventSeed
      t.remove :date_array
      t.remove :cancellation_array
      t.remove :first_date          #-> EventGenerator
      t.remove :last_date
      t.remove :shortname
      t.remove :class_style
      t.remove :course_length
      t.remove :has_taster
      t.remove :has_class
      t.remove :has_social
      t.remove :class_organiser_id
      t.remove :social_organiser_id
      t.remove :expected_date
    end
  end

  def create_event_generator(frequency, start_date, event, event_seed)
    EventGenerator.create(
      event_seed: event_seed,
      frequency: frequency,
      start_date: start_date,
      created_at: event.created_at,
      updated_at: event.updated_at
    )
  end

  def create_event_seed(event)
    EventSeed.create(
      event: event,
      venue: event.venue,
      url: event.url,
      created_at: event.created_at,
      updated_at: event.updated_at
    )
  end

  def create_dance_class(event)
    day_number = Date::DAYNAMES.index(event.day)
    raise "Invalid day" if day_number.nil?
    DanceClass.create(
      day: day_number,
      venue: event.venue
    )
  end

  def same_weekday_in_the_past(day_string)
    day = day_string.downcase.to_sym
    Date.new(2001,1,1).next_week(day)
  end
end

# frozen_string_literal: true

require 'csv'

class EventsImporter
  class Error < StandardError; end

  class NotFoundError < Error; end

  def initialize(resource_klass = Event)
    @resource_klass = resource_klass
  end

  def import(csv)
    rows = CSV.parse(csv, col_sep: ',')
    rows.each_with_object(EventsImporter::Result.new) do |row, result|
      import_row(result, row)
    end
  end

  private

  def import_row(result, row)
    result.successes << import_dates(row[0], row[1])
  rescue NotFoundError
    result.failures << Failure.new(row[0], row[1], 'Url not found')
  end

  def import_dates(url, dates_string)
    event = find_event(url)
    dates = dates_string.split(', ')
    Success.new(event.id, event.title, dates)
  end

  def find_event(url)
    event = @resource_klass.find_by(url: url)
    raise NotFoundError unless event

    event
  end

  class Result
    attr_accessor :successes, :failures

    def initialize
      @successes = []
      @failures = []
    end
  end

  Success = Struct.new(:event_id, :name, :dates_to_import)
  Failure = Struct.new(:url, :dates, :reason)
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admins can edit events' do
  it 'with valid data' do
    stub_login(id: 12345678901234567, name: 'Al Minns')
    FactoryBot.create(:event)
    FactoryBot.create(:venue, name: 'The 100 Club')
    FactoryBot.create(:organiser, name: 'The London Swing Dance Society')

    visit '/login'
    click_on 'Log in with Facebook'

    click_on 'Edit', match: :first

    fill_in 'Title', with: 'Stompin\''
    select 'The 100 Club', from: 'Venue'
    select 'The London Swing Dance Society', from: 'Social organiser'
    select 'The London Swing Dance Society', from: 'Class organiser'
    select 'school', from: 'Event type'
    check 'Has a taster?'
    check 'Has social?'
    fill_in 'Class style', with: ''
    fill_in 'Course length', with: ''
    select 'Wednesday', from: 'Day'
    fill_in 'event_frequency', with: '0'
    fill_in 'First date', with: ''
    fill_in 'Url', with: 'http://www.lsds.co.uk/stompin'

    Timecop.freeze(Time.zone.local(2000, 1, 2, 23, 17, 16)) do
      click_on 'Update'
    end

    expect(page).to have_content('Title: Stompin\'')
      .and have_content('Venue: The 100 Club')
      .and have_content('Social Organiser: The London Swing Dance Society')
      .and have_content('Class Organiser: The London Swing Dance Society')
      .and have_content('school, with social and taster')
      .and have_content('Class style:')
      .and have_content('Day: Wednesday')
      .and have_content('Frequency: One-off or intermittent')
      .and have_content('First date:')
      .and have_content('Url: http://www.lsds.co.uk/stompin')

    expect(page).to have_content('Last updated by Al Minns (12345678901234567) on Sunday 2nd January 2000 at 23:17:16')
  end

  it 'with invalid data' do
    stub_login(id: 12345678901234567, name: 'Al Minns')
    FactoryBot.create(:event)

    visit '/login'
    click_on 'Log in with Facebook'

    click_on 'Edit', match: :first

    select '', from: 'Venue'
    select '', from: 'Event type'
    uncheck 'Has a class?'
    uncheck 'Has a taster?'
    uncheck 'Has social?'
    fill_in 'event_frequency', with: '1'
    fill_in 'Dates', with: '12/12/2012'
    fill_in 'Url', with: ''

    click_on 'Update'

    expect(page).to have_content('6 errors prohibited this record from being saved:')
      .and have_content('Venue must exist')
      .and have_content('Url is invalid')
      .and have_content("Url can't be blank")
      .and have_content("Event type can't be blank")
      .and have_content('Date array must be empty for weekly events')
      .and have_content("Events must have either a Social or a Class, otherwise they won't be listed!")
  end

  it 'adding dates' do
    FactoryBot.create(:event, dates: ['12/12/2012', '13/12/2012'])
    stub_login(id: 12345678901234567, name: 'Al Minns')

    visit '/login'
    click_on 'Log in with Facebook'

    click_on 'Edit', match: :first

    fill_in 'Dates', with: '12/12/2012, 12/01/2013'

    Timecop.freeze(Time.zone.local(2015, 1, 2, 23, 17, 16)) do
      click_on 'Update'
    end

    expect(page).to have_content('Dates: 12/12/2012, 12/01/2013')

    expect(page).to have_content('Last updated by Al Minns (12345678901234567) on Friday 2nd January 2015 at 23:17:16')
  end

  it 'adding cancellations' do
    FactoryBot.create(:event, dates: ['12/12/2012'])
    stub_login(id: 12345678901234567, name: 'Al Minns')

    visit '/login'
    click_on 'Log in with Facebook'

    click_on 'Edit', match: :first

    fill_in 'Cancelled dates', with: '12/12/2012'

    Timecop.freeze(Time.zone.local(2015, 1, 2, 23, 17, 16)) do
      click_on 'Update'
    end

    expect(page).to have_content('Cancelled: 12/12/2012')

    expect(page).to have_content('Last updated by Al Minns (12345678901234567) on Friday 2nd January 2015 at 23:17:16')
  end
end

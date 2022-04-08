# frozen_string_literal: true

require 'csv'
require 'date'
require 'time'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(phone_numbers)
  phone_numbers.gsub!(/[-.()+a-zA-Z ]/, '')
  if phone_numbers.length == 10
    puts phone_numbers
  elsif phone_numbers.length == 11 && phone_numbers[0] == '1'
    puts phone_numbers[1..10]
  else
    puts 'Bad Number!'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_manager/event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('event_manager/form_letter.erb')
erb_template = ERB.new template_letter

hours_arr = []
days_arr = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  phone_numbers = clean_phone_numbers(row[:homephone])

  time_reg = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  time_reg_hour = time_reg.hour
  hours_arr.push(time_reg_hour)
  time_reg_day = time_reg.wday
  days_arr.push(time_reg_day)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

days = days_arr.max_by { |day| days_arr.count(day) }

puts "The best hour to promove ads is #{hours_arr.max_by { |hour| hours_arr.count(hour) }}:00"
puts "The days of week the most people register is #{Date::DAYNAMES[days]}"

require 'httparty'
require 'nokogiri'
require 'json'
require 'pry'
require 'rubygems'
require 'mechanize'
require 'csv'
require 'rinku'

# SPECIFY YOUR VARIBLES HERE:
url = 'http://planning.basildon.gov.uk/online-applications/search.do?action=advanced'
url_beginning = "http://planning.basildon.gov.uk"
council = "Basildon"
startDate = "01/12/2016"
endDate = "31/12/2016"

# PART 1
# THIS IS TO FETCH ALL APPLICATIONS IN THE SPECIFIED TIME PERIOD
# ALONG WITH REFERENCE NUMBER, ALTERNATIVE REFERENCE NUMBER,
# RECEIVED DATE, VALIDATED DATE, ADDRESS, PROPOSAL, DECISION
# OUTCOME AND DECISION DATE. THEN, IT PUSHES THE DATA
# TO THE CSV FILE
# TWO FIELDS: APPLICATION TYPE AND DEVELOPMENT TYPE ARE ADDED
# IN PARTS 2 AND 3 OF THIS CODE

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to set the values of two fields of the form
search_form['date(applicationDecisionStart)'] = startDate
search_form['date(applicationDecisionEnd)'] = endDate

# this is to submit the form
page = agent.submit(search_form)

# this is to create an empty array to store the links (results)
links_array = []

# the following loop is to find all links on the page which include
# the "applicationDetails" wording and store them in the links_array
# then, to move to the "next" page and do the same,
# until there is no "next"

loop do
	page.links.each do |link|
		if link.href.include?"applicationDetails"
		links_array.push(link.href)
		end
	end

	if link = page.link_with(:text => "Next")
	page = link.click
	else break
	end
end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
	#Rinku.auto_link(item, mode=:all, link_attr=nil, skip_tags=nil)
end

# this is to define empty arrays where we will store all the details
# on individual applications
reference_array = []
altreference_array = []
received_array = []
validated_array = []
address_array = []
proposal_array = []
outcome_array = []
decided_array = []

# the following .each method is to scrap the data on the aplications'
# reference number, alternative reference number, 
# receival date, application validation date
# address of the development, proposed development, decision
# oucome (granted or refused), decision date and council. 
# Then, to store the scraped data in the relevant arrays

links_array.each do |application|

# this is to request the subpage we're going to scrape
	sub_page = HTTParty.get(application)

# this is to transform the http response into a nokogiri object
	parse_sub_page = Nokogiri::HTML(sub_page)

# this is to parse the data
	reference = parse_sub_page.css('#simpleDetailsTable').css('td')[0].text
	reference_tidied = reference.strip
	reference_array.push(reference_tidied)

	altreference = parse_sub_page.css('#simpleDetailsTable').css('td')[1].text
	altreference_tidied = altreference.strip
	altreference_array.push(altreference_tidied)

	received = parse_sub_page.css('#simpleDetailsTable').css('td')[2].text
	received_tidied = received.strip
	received_array.push(received_tidied)

	validated = parse_sub_page.css('#simpleDetailsTable').css('td')[3].text
	validated_tidied = validated.strip
	validated_array.push(validated_tidied)

	address = parse_sub_page.css('#simpleDetailsTable').css('td')[4].text
	address_tidied = address.strip
	address_array.push(address_tidied)

	proposal = parse_sub_page.css('#simpleDetailsTable').css('td')[5].text
	proposal_tidied = proposal.strip
	proposal_array.push(proposal_tidied)
	proposal_array.each do |proposal|
		proposal.gsub(",","")
	end

	outcome = parse_sub_page.css('#simpleDetailsTable').css('td')[7].text
	outcome_tidied = outcome.strip
	outcome_array.push(outcome_tidied)

	decided = parse_sub_page.css('#simpleDetailsTable').css('td')[8].text
	decided_tidied = decided.strip
	decided_array.push(decided_tidied)

end

# this is to create column headings in the csv file.
CSV.open("#{council}.csv", "w+") do |csv|
  csv << ["reference", "altreference","received", "validated", "address", "proposal", "outcome", "decided", "links", "apptype", "devtype", "council"]
end

# this is to add one more array: council name
counting = links_array.count
council_array = Array.new(counting,council)

# this is to transpose the data in the arrays in order to get
# the same layout as in the columns above 
table = [reference_array, altreference_array, received_array, validated_array, address_array, proposal_array, outcome_array, decided_array, links_array, council_array].transpose

# this is to push the data in the csv file
CSV.open('#{council}.csv', 'a+') do |csv|
	table.each do |row|
		csv << row
	end
end

# PART 2
# THE CODE BELOW FINDS THE PLANNING APPLICATION LINKS AND
# THE RELEVANT TYPES OF APPLICATION AND PUSHES THE DATA
# TO THE CSV FILE

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to check how many options there are on the form
# under the 'application type' field
types = search_form.field_with(:name => 'searchCriteria.caseType').options
counter = types.count

# this is to create empty arrays to store the links (results)
links_array = []
apptype_array = []

# this is the "i" definition for the while loop
i = 1

# this is where the while loop starts. It will run until it
# will fetch all options avaialble under the application
# type field

while i < counter

	# this is to set the values of three fields of the form
	search_form['date(applicationDecisionStart)'] = startDate
	search_form['date(applicationDecisionEnd)'] = endDate
	search_form.field_with(:name => 'searchCriteria.caseType').options[i].select

	# this is to submit the form
	page = agent.submit(search_form)

	# the following loop is to find all links on the page which include
	# the "applicationDetails" wording and store them in the links_array
	# then, to move to the "next" page and do the same,
	# until there is no "next". The code also adds application
	# type label for each link

	loop do
		page.links.each do |link|
			if link.href.include?"applicationDetails"
			links_array.push(link.href)
			counting_array = []
			counting_array.push(link.href)
			counting = counting_array.count
			appnames_array = []
			appnames_array = Array.new(counting,i)
			apptype_array.push(appnames_array)
			end
		end

		if link = page.link_with(:text => "Next")
		page = link.click
		else break
		end
	end

	i = i + 1

end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
	#Rinku.auto_link(item, mode=:all, link_attr=nil, skip_tags=nil)
end

# this is to create column headings in the csv file.
CSV.open("#{council}_apptype.csv", "w+") do |csv|
  csv << ["links", "apptype"]
end

# this is to transpose the data in the arrays in order to get
# the desired layout of the final data table
table = [links_array, apptype_array].transpose

# this is to push the data in the csv file
CSV.open('#{council}_apptype.csv', 'a+') do |csv|
	table.each do |row|
		csv << row
	end
end

# PART 3
# THE CODE BELOW FINDS THE PLANNING APPLICATION LINKS AND
# THE RELEVANT TYPES OF DEVELOPMENT AND PUSHES THE DATA
# TO THE CSV FILE

# this is to instantiate a new mechanize object
agent = Mechanize.new

# this is to fetch the webpage
page = agent.get(url)

# this is to print the page to see what html names are used for
# the form and fields
#pp page

# this is to fetch the form
search_form = page.form('searchCriteriaForm')

# this is to check how many options there are on the form
# under the 'application type' field
types = search_form.field_with(:name => 'searchCriteria.developmentType').options
counter = types.count

# this is to create empty arrays to store the links (results)
links_array = []
devtype_array = []

# this is the "i" definition for the while loop
i = 1

# this is where the while loop starts. It will run until it
# will fetch all options avaialble under the development
# type field

while i < counter

	# this is to set the values of three fields of the form
	search_form['date(applicationDecisionStart)'] = startDate
	search_form['date(applicationDecisionEnd)'] = endDate
	search_form.field_with(:name => 'searchCriteria.developmentType').options[i].select

	# this is to submit the form
	page = agent.submit(search_form)

	# the following loop is to find all links on the page which include
	# the "applicationDetails" wording and store them in the links_array
	# then, to move to the "next" page and do the same,
	# until there is no "next". The code also adds development
	# type label for each link

	loop do
		page.links.each do |link|
			if link.href.include?"applicationDetails"
			links_array.push(link.href)
			counting_array = []
			counting_array.push(link.href)
			counting = counting_array.count
			devnames_array = []
			devnames_array = Array.new(counting,i)
			devtype_array.push(devnames_array)
			end
		end

		if link = page.link_with(:text => "Next")
		page = link.click
		else break
		end
	end

	i = i + 1

end

# this is to convert the links to strings,
# then, to suplement urls with the missing text:
# "http://planning.xxxxxx.gov.uk"

links_array.map! do |item|
	item.to_s
	item = "#{url_beginning}#{item}"
	#Rinku.auto_link(item, mode=:all, link_attr=nil, skip_tags=nil)
end

# this is to create column headings in the csv file.
CSV.open("#{council}_devtype.csv", "w+") do |csv|
  csv << ["links", "devtype"]
end

# this is to transpose the data in the arrays in order to get
# the desired layout of the final data table
table = [links_array, devtype_array].transpose

# this is to push the data in the csv file
CSV.open('#{council}_devtype.csv', 'a+') do |csv|
	table.each do |row|
		csv << row
	end
end	






	


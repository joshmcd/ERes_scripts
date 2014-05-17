require 'io/console'
require 'watir'
require 'watir-webdriver' #comment this out to use ie
require 'mechanize'
require 'titleize'
#require 'irb'
#require 'irb/completion'
#require 'pry'

if STDIN.respond_to?(:noecho)
  def get_password(prompt="Password: ")
    print prompt
    STDIN.noecho(&:gets).chomp
  end
else
  def get_password(prompt="Password: ")
    `read -s -p "#{prompt}" password; echo $password`.chomp
  end
end

chap_pg_regularizer = 
	

#see below when we call fetch to check a link. from https://stackoverflow.com/questions/5629170/using-watir-to-check-for-bad-links
#kinda slow 'cause it actually makes a full request. might be better to use typhoeus, but having trouble using it on windows.
def fetch(uri_str, limit = 10)
  # Change this exception.
  raise ArgumentError, 'HTTP redirect too deep' if limit == 0

  response = Net::HTTP.get_response(URI.parse(uri_str))
  case response
  when Net::HTTPSuccess     then response
  when Net::HTTPRedirection then fetch(response['location'], limit - 1)
  else
    response.error!
  end
end


puts "What's your user name? "

$user = gets.chomp.to_s

$password = get_password("What's your password? \n")

browser = Watir::Browser.new 
browser.goto 'http://eres.sais-jhu.edu/eres/default.aspx'
	browser.link(:text => "Admin Login").click
	u = browser.text_field :id => 'ctl00_BodyContent_docutek_login_myTextBox'
	u.set $user
	p = browser.text_field :id => 'ctl00_BodyContent_docutek_pass_myPass'
	p.set $password
	browser.button(:name => 'ctl00$BodyContent$btn_login').click
timer = Time.now

sleep 1
	browser.link(:text => "SAIS ERes Home").click 
	browser.link(:text => "Main Menu").click
	browser.link(:text => "Document").click
#the next page takes a bit to load - there are 25 checkboxes arranged from zero. the following sets it so 250 show on the page
count = 1

reset_proc = Proc.new do
	puts count
	#browser.select_list(:id, "ctl00_BodyContent_listing_results_dropdown").when_present.select("250")
	browser.select_list(:id, "ctl00_BodyContent_docutek_search_dateCreated_search_type").when_present.select("is")
	browser.select_list(:id, "ctl00_BodyContent_docutek_search_dateCreated_search_date_my_month").select("January")
	browser.select_list(:id, "ctl00_BodyContent_docutek_search_dateCreated_search_date_my_day").select("15")
	browser.select_list(:id, "ctl00_BodyContent_docutek_search_dateCreated_search_date_my_year").select("2003")
	browser.button(:value, "Search").when_present.click

	count_field = count
	if
	count_field <= 9
		2.times { browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys(:backspace) }
	elsif 
		count_field.between?(10, 100)
		3.times { browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys(:backspace) }
	elsif
		count_field.between?(100, 1000)
		4.times { browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys(:backspace) }
	elsif 
		count_field.between?(1000, 10000)
		5.times { browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys(:backspace) }
	else 
		puts "too big!"
	end
	browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys("#{count}")
	browser.text_field(:id, /ctl00_BodyContent_pageSelection/).send_keys(:return)

end

reset_proc.call

number_of_pages = browser.span(:id, "ctl00_BodyContent_pageLabel").when_present.text.to_i
number_of_docs = browser.span(:id, "ctl00_BodyContent_RecordCount").when_present.text.to_i
titleizeProc = Proc.new do
	for i in (1..number_of_docs) do #(1..250)
		
		browser.checkboxes[i].when_present.set
		sleep 2
		
		#docid = browser.as[(19+i)].href.to_s.gsub(/[^\d]/, "") #the anchor tags start at 20, so offsetting the checkboxes by 19 should get the right one.
		#we'll need to double check that this is always true
		#might be more useful to actually click on the link and get the doc associations, but this is difficult because modal popups
		
		#browser.checkboxes[i].clear
		browser.link(:id, "ctl00_BodyContent_link_update").when_present.click
		#browser.link(:text, "Web Link").click

=begin		unless 
		browser.text_field(:id, "ctl00_BodyContent_docutek_url_myTextBox").when_present.value == ""
		l = browser.text_field(:id, "ctl00_BodyContent_docutek_url_myTextBox").value
		response_code = fetch("#{l}")
			if response_code.to_s.include? "OK"
				puts docid + "status is" + response_code + ", that's good."
			else 
			File.open('broken_links.txt', 'a') do |k| #better change this filename
				k.puts puts "document number " + docid + " has a broken link. The URL to fix it is http://eres.sais-jhu.edu/eres/documents.aspx?cid=admin&docid=#{docid}"
			end
				
			end
		else
		puts "document number " + docid + " has no link"
	end
=end
		@b = browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").value.titleize
		browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").set @b
		puts @b 
		#have to account for Pp., Ch., Chap., Pg. etc.
		#.gsub(/(\bCh\b|\bChap\b|\bC\b|\bChapter\b)\.?$/, "ch.") #.gsub(/^[Page|Pg\.?|Pp\.?|P\.?]^./, "pp.") 
		# or just .gsub(/\bCh.\b/, "ch.").gsub(/\bChap.\b/, "ch.").gsub(/\bChapter\b/, "ch.")
		#map works . . .
		map = { 'Ch.' => 'ch.', 'Chap.' => 'ch.', 'Chapter' => 'ch.', 'Chapters' => 'chs.', 'Pages' => 'pp.', 'Pp' => 'pp.', 'Pp.' => 'pp.', 'Pg.' => 'pp.', 'Page' => 'p.' } 
		map.each {|k,v| @b.gsub!(k,v)}
		puts @b
		sleep 1
		browser.button(:value, "Save").when_present.click
		reset_proc.call
	end 
end




#breaks if there aren't more than one 
#probably have to figure out a different method.
=begin
until count % number_of_pages == 0 do
	titleizeProc.call
	count+=1
end
=end


titleizeProc.call	

timer2 = (Time.now - timer) / 60

puts "Finished! Application completed in #{timer2} seconds."

sleep 10
	#instead use
	#browser.input(:id, "ctl00_BodyContent_pageSelection").set count
	#browser.a(:title, "Next Page").when_present.click

#
#

# IRB.start #as described here: https://stackoverflow.com/questions/123494/whats-your-favourite-irb-trick but pry is better
#binding.pry
#now we need to set up a loop to iterate through each option.
=begin
#presumably with something like
browser.checkboxes[1..250].each do |i|
	i.set
	browser.link(:id, "ctl00_BodyContent_link_update").click
	@b = browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").value.titleize
	browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").set @b
	#browser.button(:value,"Apply").click #probably unnecessary
	browser.button(:value,"Save").when_present.click 
	#works!
	#the problem is that the page refreshes and clears all the settings. so we have to redo the select_list block 
	
#might also make sense to make this a proc or a method
something like 
titleProc = Proc.new do |check| 
	check.set 
	browser.link(:id, "ctl00_BodyContent_link_update").click
	@b = browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").value.titleize
	browser.text_field(:id, "ctl00_BodyContent_docutek_title_myTextBox").set @b
	#browser.button(:value,"Apply").click #probably unnecessary
	browser.button(:value,"Save").when_present.click
end
then we can just call it like:

browser.checkboxes[1..250].each(&titleProc)
=end	
#all of the following is just here in case it's useful later. For the renaming of files, all we need is above
=begin
browser.link(:text => "Electronic Reserves Course Pages").click
page = Nokogiri::HTML.parse(browser.html)
names = []
list = page.css("option")[2..-1]
list.each { |name| names << name.text }

File.open('instructor_list.txt', 'a') do |k|
	k.puts names
	end

#names.each do |name| 


drop = browser.select_list(:name => "ctl00$BodyContent$docutek_search_instr$search_select")
drop.select names[7] #"#{name}"

browser.button(:name => "ctl00$BodyContent$btn_search").click
# the href will have a syntax something like: href="coursepass.aspx?cid=927"
#so then

#@page = Nokogiri::HTML.parse(browser.html)
#@links = @page.css('tr td a')[17..-1] #can be done natively with @links = browser.links.collect(&:text) 
#this will put them all into a text array, but we parse them with Nokogiri to make the next part easier
@links = browser.links.collect(&:text)

browser.links[17].click
browser.button(:value => "Accept").click
browser.link(:id, "ctl00_BodyContent_myTabs_link_pm").click #from here: https://stackoverflow.com/questions/8139322/how-do-i-select-a-js-tab-in-watir-webdriver
sleep 2 
browser.execute_script("javascript:__doPostBack('ctl00$BodyContent$link_associations','')") #executes the script but just puts us back at the previous page.
#script seems to be in two parts; have to figure out what it actually does.
#/html/body/form/div[4]/div/table[2]/tbody/tr/td/center/div/table/tbody/tr[2]/td/a
#css: "html body form#aspnetForm div#ctl00_BodyContent_pagePanel div#ctl00_BodyContent_updatePanel table tbody tr td.PANEL center div#ctl00_BodyContent_pmTab table#ctl00_BodyContent_table_pm tbody tr td a#ctl00_BodyContent_link_associations"
=end

=begin
the following don't work:
browser.link(:id, "ctl00_BodyContent_link_associations").when_present.click
browser.window(:index => 1).use

browser.execute_script("javascript:__doPostBack('ctl00$BodyContent$link_associations','')")

"PostBack is the term used to describe when the form is being submitted (posted) back to the same page. Simple as that.
Ordinary submit button would have been enough, but part of PostBack is the ability to identify which control triggered it, 
meaning what button or link was clicked.
To do such a thing ASP.NET is automatically adding hidden fields to the form and when clicking on element that should cause PostBack, 
JavaScript code is used to update the values of those hidden fields to the proper values indicating what was clicked - the argument you pass.
The name Microsoft chose to give to the JS function doing the above is __doPostBack - 
it's just a name of a function, ordinary JavaScript function that ASP.NET automatically writes to the browser."

The javascript looks like this:  <script type="text/javascript">parent.setModalTitle('ctl00_BodyContent_pmPopup','Documents & Copyright');</script>
</head>
<body bgcolor="#ffffff" style="margin:0 0 0 0;" >
<form name="aspnetForm" method="post" action="associations.aspx?cid=793&amp;format=modal&amp;modalid=ctl00_BodyContent_pmPopup" id="aspnetForm">
<div>
<input type="hidden" name="ctl00_ScriptManager1_HiddenField" id="ctl00_ScriptManager1_HiddenField" value="" />
<input type="hidden" name="__EVENTTARGET" id="__EVENTTARGET" value="" />
<input type="hidden" name="__EVENTARGUMENT" id="__EVENTARGUMENT" value="" />
<input type="hidden" name="__LASTFOCUS" id="__LASTFOCUS" value="" />
<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="/wEPDwUKMTA0OTA0NTkwNQ8WCh4Ec29ydAUJdGl0bGUgQVNDHgZzZWFyY2gF0AEgd2hlcmUgYy5bZGF0ZURlbGV0ZWRdIGlzIG51bGwgYW5kIGQuW2RhdGVEZWxldGVkXSBpcyBudWxsIGFuZCBjZC5bZGF0ZURlbGV0ZWRdIGlzIG51bGwgYW5kIGNkLmRvY2lkID0gZC5kb2NpZCBhbmQgY2QuY291cnNlaWQgPSBjLmNvdXJzZWlkIGFuZCBjLmNvdXJzZUlEID0gNzkzIGFuZCBkcC5kZXB0aWQgPSBjLmRlcHRpZCBhbmQgZC5pc0ZvbGRlciA9IGZhbHNlHgRkYXRhBSssW3RpdGxlXSxbcGFyZW50Zm9sZGVyXSxbdmlzc3RhcnRdLFt2aXNlbmRdHgdkYXRhU2V0MruWAgABAAAA/////wEAAAAAAAAADAIAAABOU3lzdGVtLkRhdGEsIFZlcnNpb249Mi4wLjAuMCwgQ3VsdHVyZT1uZXV0cmFsLCBQdWJsaWNLZXlUb2tlbj1iNzdhNWM1NjE5MzRlMDg5BQEAAAATU3lzdGVtLkRhdGEuRGF0YVNldAMAAAAXRGF0YVNldC5SZW1vdGluZ1ZlcnNpb24JWG1sU2NoZW1hC1htbERpZmZHcmFtAwEBDlN5c3RlbS5WZXJzaW9uAgAAAAkDAAAABgQAAADkCzw/eG1sIHZlcnNpb249IjEuMCIgZW5jb2Rpbmc9InV0Zi0xNiI/Pg0KPHhzOnNjaGVtYSBpZD0iTmV3RGF0YVNldCIgeG1sbnM9IiIgeG1sbnM6eHM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hIiB4bWxuczptc2RhdGE9InVybjpzY2hlbWFzLW1pY3Jvc29mdC1jb206eG1sLW1zZGF0YSI+DQogIDx4czplbGVtZW50IG5hbWU9Ik5ld0RhdGFTZXQiIG1zZGF0YTpJc0RhdGFTZXQ9InRydWUiIG1zZGF0YTpVc2VDdXJyZW50TG9jYWxlPSJ0cnVlIj4NCiAgICA8eHM6Y29tcGxleFR5cGU+DQogICAgICA8eHM6Y2hvaWNlIG1pbk9jY3Vycz0iMCIgbWF4T2NjdXJzPSJ1bmJvdW5kZWQiPg0KICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJteVZpZXciPg0KICAgICAgICAgIDx4czpjb21wbGV4VHlwZT4NCiAgICAgICAgICAgIDx4czpzZXF1ZW5jZT4NCiAgICAgICAgICAgICAgPHhzOmVsZW1lbnQgbmFtZT0icGFyZW50Zm9sZGVyIiB0eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJwZXJzaXN0dXJsIiB0eXBlPSJ4czpzdHJpbmciIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJhc3NvY2lhdGlvbmlkIiB0eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJjb3Vyc2VJRCIgdHlwZT0ieHM6aW50IiBtc2RhdGE6dGFyZ2V0TmFtZXNwYWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4NCiAgICAgICAgICAgICAgPHhzOmVsZW1lbnQgbmFtZT0iZG9jSUQiIHR5cGU9InhzOmludCIgbXNkYXRhOnRhcmdldE5hbWVzcGFjZT0iIiBtaW5PY2N1cnM9IjAiIC8+DQogICAgICAgICAgICAgIDx4czplbGVtZW50IG5hbWU9InRpdGxlIiB0eXBlPSJ4czpzdHJpbmciIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJwYXJlbnRmb2xkZXIxIiB0eXBlPSJ4czppbnQiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJ2aXNzdGFydCIgdHlwZT0ieHM6ZGF0ZVRpbWUiIG1zZGF0YTp0YXJnZXROYW1lc3BhY2U9IiIgbWluT2NjdXJzPSIwIiAvPg0KICAgICAgICAgICAgICA8eHM6ZWxlbWVudCBuYW1lPSJ2aXNlbmQiIHR5cGU9InhzOmRhdGVUaW1lIiBtc2RhdGE6dGFyZ2V0TmFtZXNwYWNlPSIiIG1pbk9jY3Vycz0iMCIgLz4NCiAgICAgICAgICAgIDwveHM6c2VxdWVuY2U+DQogICAgICAgICAgPC94czpjb21wbGV4VHlwZT4NCiAgICAgICAgPC94czplbGVtZW50Pg0KICAgICAgPC94czpjaG9pY2U+DQogICAgPC94czpjb21wbGV4VHlwZT4NCiAgPC94czplbGVtZW50Pg0KPC94czpzY2hlbWE+BgUAAACtiAI8ZGlmZmdyOmRpZmZncmFtIHhtbG5zOm1zZGF0YT0idXJuOnNjaGVtYXMtbWljcm9zb2Z0LWNvbTp4bWwtbXNkYXRhIiB4bWxuczpkaWZmZ3I9InVybjpzY2hlbWFzLW1pY3Jvc29mdC1jb206eG1sLWRpZmZncmFtLXYxIj48TmV3RGF0YVNldD48bXlWaWV3IGRpZmZncjppZD0ibXlWaWV3MSIgbXNkYXRhOnJvd09yZGVyPSIwIj48cGFyZW50Zm9sZGVyPjA8L3BhcmVudGZvbGRlcj48cGVyc2lzdHVybD5odHRwOi8vZXJlcy5zYWlzLWpodS5lZHUvZXJlcy9kb2N1bWVudHZpZXcuYXNweD9hc3NvY2lkPTM5NTAzPC9wZXJzaXN0dXJsPjxhc3NvY2lhdGlvbmlkPjM5NTAzPC9hc3NvY2lhdGlvbmlkPjxjb3Vyc2VJRD43OTM8L2NvdXJzZUlEPjxkb2NJRD40MDk3ODwvZG9jSUQ+PHRpdGxlPi0gQ09VUlNFIFNZTExBQlVTPC90aXRsZT48cGFyZW50Zm9sZGVyMT4wPC9wYXJlbnRmb2xkZXIxPjwvbXlWaWV3PjxteVZpZXcgZGlmZmdyOmlkPSJteVZpZXcyIiBtc2RhdGE6cm93T3JkZXI9IjEiPjxwYXJlbnRmb2xkZXI+MDwvcGFyZW50Zm9sZGVyPjxwZXJzaXN0dXJsPmh0dHA6Ly9lcmVzLnNhaXMtamh1LmVkdS9lcmVzL2RvY3VtZW50dmlldy5hc3B4P2Fzc29jaWQ9NDAxNzQ8L3BlcnNpc3R1cmw+PGFzc29jaWF0aW9uaWQ+NDAxNzQ8L2Fzc29jaWF0aW9uaWQ+PGNvdXJzZUlEPjc5MzwvY291cnNlSUQ+PGRvY0lEPjQxNDExPC9kb2NJRD48dGl0bGU+LSBMSVNUIE9GIEJPT0tTIE9OIFJFU0VSVkU8L3RpdGxlPjxwYXJlbnRmb2xkZXIxPjA8L3BhcmVudGZvbGRlcjE+PC9teVZpZXc+PG15VmlldyBkaWZmZ3I6aWQ9Im15VmlldzMiIG1zZGF0YTpyb3dPcmRlcj0iMiI+PHBhcmVudGZvbGRlcj41MjcyMzwvcGFyZW50Zm9sZGVyPjxwZXJzaXN0dXJsPmh0dHA6Ly9lcmVzLnNhaXMtamh1LmVkdS9lcmVzL2RvY3VtZW50dmlldy5hc3B4P2Fzc29jaWQ9NTkxNzc8L3BlcnNpc3R1cmw+PGFzc29jaWF0aW9uaWQ+NTkxNzc8L2Fzc29jaWF0aW9uaWQ+PGNvdXJzZUlEPjc5MzwvY291cnNlSUQ+PGRvY0lEPjU5MTQ1PC9kb2NJRD48dGl0bGU+QWNyb3NzIEJvcmRlcnMgW2NoYXAgM108L3RpdGxlPjxwYXJlbnRmb2xkZXIxPjUyNzIzPC9wYXJlbnRmb2xkZXIxPjwvbXlWaWV3PjxteVZpZXcgZGlmZmdyOmlkPSJteVZpZXc0IiBtc2RhdGE6cm93T3JkZXI9IjMiPjxwYXJlbnRmb2xkZXI+NTM3NTY8L3BhcmVudGZvbGRlcj48cGVyc2lzdHVybD5odHRwOi8vZXJlcy5zYWlzLWpodS5lZHUvZXJlcy9kb2N1bWVudHZpZXcuYXNweD9hc3NvY2lkPTU5MTc2PC9wZXJzaXN0dXJsPjxhc3NvY2lhdGlvbmlkPjU5MTc2PC9hc3NvY2lhdGlvbmlkPjxjb3Vyc2VJRD43OTM8L2NvdXJzZUlEPjxkb2NJRD41OTE0NDwvZG9jSUQ+PHRpdGxlPkFjcm9zcyBCb3JkZXJzIFtjaGFwIDRdPC90aXRsZT48cGFyZW50Zm9sZGVyMT41Mzc1NjwvcGFyZW50Zm9sZGVyMT48L215Vmlldz48bXlWaWV3IGRpZmZncjppZD0ibXlWaWV3NSIgbXNkYXRhOnJvd09yZGVyPSI0Ij48cGFyZW50Zm9sZGVyPjUyNzI3PC9wYXJlbnRmb2xkZXI+PHBlcnNpc3R1cmw+aHR0cDovL2VyZXMuc2Fpcy1qaHUuZWR1L2VyZXMvZG9jdW1lbnR2aWV3LmFzcHg/YXNzb2NpZD01NjgwMjwvcGVyc2lzdHVybD48YXNzb2NpYXRpb25pZD41NjgwMjwvYXNzb2NpYXRpb25pZD48Y291cnNlSU...MWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwyNSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwyNiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwyNyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwyOCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwyOSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzMCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzMSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzMiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzMyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzNCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzNSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzNiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzNyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzOCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGwzOSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0NyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0OCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw0OSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1NyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1OCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw1OSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2NyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2OCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw2OSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3NyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3OCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw3OSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4NyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4OCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw4OSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5MCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5MSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5MiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5MyRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5NCRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5NSRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5NiRjaGVja2JveF9tb2RkZWwFMWN0bDAwJEJvZHlDb250ZW50JG15TGlzdGluZyRjdGw5NyRjaGVja2JveF9tb2RkZWz1a9PIYJ1Idnh984WVP9M3AAAAAA==" />
</div>
<script type="text/javascript">
//<![CDATA[
var theForm = document.forms['aspnetForm'];
if (!theForm) {
theForm = document.aspnetForm;
}
function __doPostBack(eventTarget, eventArgument) {
if (!theForm.onsubmit || (theForm.onsubmit() != false)) {
theForm.__EVENTTARGET.value = eventTarget;
theForm.__EVENTARGUMENT.value = eventArgument;
theForm.submit();
}
}
//]]>
</script>" 

also this  has more on dopostback: https://stackoverflow.com/questions/3272213/what-does-javascript-dopostbackgridview-edit0-mean-full-post-back-st
=end


#"javascript:__doPostBack('ctl00$BodyContent$link_associations','')"
=begin
the checkboxes are named in order starting at id="ctl00_BodyContent_myListing_ctl05_checkbox_moddel" and continuing to 
"ctl00_BodyContent_myListing_ctl06_checkbox_moddel" etc.
so they can be set with  
browser.checkbox(:id => "ctl00_BodyContent_myListing_ctl05_checkbox_moddel" 
and so on
the next problem is how to iterate through each one.
maybe something like
doclink = []
browser.checkboxes.each do |i|
	doclink << i
	end
	
	
=end
=begin
@doclink = []
browser.checkboxes.each do |i|
	@doclink << i
	end

@courses = []
@links.each do |link|	
			@courses << link['href']
		end

# browser.links[17].click #gets us as far as the accept button
#maybe a while/until loop is the way to go. It's possible I'm overthinking this part; 
#what about 


#just for testing
File.open('courses.txt', 'a') do |l|
	l.puts @doclink
end
=end
#browser.back
#end





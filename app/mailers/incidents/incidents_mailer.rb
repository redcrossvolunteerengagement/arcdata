class Incidents::IncidentsMailer < ActionMailer::Base
  default from: "ARCBA DAT <incidents@arcbadat.org>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.incidents.incidents_mailer.weekly.subject
  #
  def weekly(chapter, recipient)
    @chapter = chapter
    @person = recipient
    @start_date = chapter.time_zone.today.at_beginning_of_week.last_week.next_week
    @end_date = @start_date.next_week.yesterday
    @incidents = Incidents::Incident.where{date.in(my{@start_date..@end_date})}.order{date}.to_a
    @weekly_stats = Incidents::Incident.where{date.in(my{@start_date..@end_date})}.incident_stats
    @yearly_stats = Incidents::Incident.where{date >= '2012-07-01'}.incident_stats

    @deployments = Incidents::Deployment.includes{person.counties}.where{date_last_seen >= my{@start_date}}.uniq.to_a
                                        .sort_by{|a| a.person.counties.first.try(:name) || '' }
                                        .reduce({}) { |hash, d| hash[d.dr_name] ||= []; hash[d.dr_name] << d; hash}

    @subtitle = "Week of #{@start_date.to_s :mdy}"

    @title = "ARCBA Disaster Operations Report - #{@subtitle}"

    mail to: format_address(recipient), subject: @title
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.incidents.incidents_mailer.no_incident_report.subject
  #
  def no_incident_report(incident, recipient)
    @incident = incident

    mail to: format_address(recipient), subject: "Missing Incident Report For #{incident.county_name}"
  end

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.incidents.incidents_mailer.orphan_cas.subject
  #
  def orphan_cas
    @greeting = "Hi"

    mail to: "to@example.org"
  end

  def new_incident(incident, recipient)
    @incident = incident
    mail to: format_address(recipient), subject: "New Incident For #{incident.county_name}"
  end

  def incident_dispatched(incident, recipient)
    @incident = incident
    mail to: format_address(recipient), subject: "Incident For #{incident.county_name} Dispatched", template_name: 'new_incident'
  end

  def incident_report_filed(incident, recipient)
    @incident = incident
    mail to: format_address(recipient), subject: "Incident Report Filed For #{incident.county_name}"
  end

  private

  def format_address(person)
    addr = Mail::Address.new person.email
    addr.display_name = person.full_name
    addr.format
  end

  helper_method :static_maps_url
  def static_maps_url(retina=false)
    size = "200x400"
    "http://maps.googleapis.com/maps/api/staticmap?visual_refresh=true&sensor=false&size=#{size}&markers=#{URI::encode incidents_marker_param}&scale=#{retina ? '2' : '1'}&key=AIzaSyBabBKA3eRH_Pj1UdHEvzISS0crsOScsf4"
  end

  def image_content
    uri = URI(static_maps_url)
    resp = Net::HTTP.get_response uri
    { content_type: resp['Content-Type'], content: resp.body }
  end

  def incidents_marker_param
    "|" + @incidents.map{|i| [i.lat.to_s, i.lng.to_s].join(",")}.join("|")
  end
end

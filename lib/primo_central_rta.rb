# * ****************************************************************************
# *
# * PrimoCentral Real Time Availability Workaround for Primo v3.0
# *
# *
# * Version: 0.1
# *
# * K.U.Leuven/Libis (c) 2010 -- BSD license
# * Mehmet Celik -- mehmet.celik at libis.be
# * 
# *
require 'nokogiri'
require 'net/http'
require 'uri'

class PrimoCentralRta
  RSI_URL = 'http://sfx.libis.be/sfxlcl3/cgi/core/rsi/rsi.cgi'
  DEFAULT_SFX_INSTITUTION = 'KULeuven'
  def self.fetch(params)    
    records = {}
    records_data = params[:record] || {}
    institution_name = params[:institution] || DEFAULT_SFX_INSTITUTION


    records_data.each do |k,v|
      record_data = v.split('|')
      issn = record_data[0]
      year = record_data[1]

      if records.include?(issn)
        record_data = records[issn]
      else
        record_data = []
      end

      record_data << {:id => k, :year => year}
      records[issn] = record_data
    end
    self.rta(institution_name, records)
  end

private

  def self.rta(institution_name, records)
    rta_response = {}
    xml_builder = Nokogiri::XML::Builder.new do |xml|
      xml.ISSN_REQUEST(:VERSION => "1.0") {
        records.each do |k,v|
          v.each do |d|
            xml.ISSN_REQUEST_ITEM {
              xml.ISSN(k)
              xml.YEAR(d[:year])
              xml.INSTITUTE_NAME(institution_name)
            }
          end
        end
      }
    end

    xml_request = xml_builder.to_xml
    xml_request.gsub!("\n")
    url = URI.parse(RSI_URL)
    http = Net::HTTP.new(url.host, url.port)

    request_url = "#{url.request_uri}?request_xml=#{CGI::escape(xml_request)}"
    request = Net::HTTP::Get.new(request_url)

    xml_response = http.request(request)

    case xml_response
    when Net::HTTPSuccess
      xml = Nokogiri::XML(xml_response.body)
      xml.xpath('//ISSN_RESPONSE_ITEM').each do |item|
        available_services = ''
        peer_reviewed = ''
        issn = item.css('ISSN').text.gsub('-','')
        year = item.css('YEAR').text
        details = item.css('ISSN_RESPONSE_DETAILS')

        if details.attr('RESULT').value.eql?('Found')
          available_services = details.attr('AVAILABLE_SERVICES').value unless details.attr('AVAILABLE_SERVICES').nil?
          peer_reviewed      = details.attr('PEER_REVIEWED').value.eql?('YES') ? true : false unless details.attr('PEER_REVIEWED').nil?
        end

        record = records[issn]
        record.each do |r|
          rta_response[r[:id]] = {:issn => issn, :year => year, :peer_reviewed => peer_reviewed, :services => available_services}
        end
      end
      return rta_response
    else
      response.error!
    end

    return nil
  rescue Exception => e
    puts ("#{e.message}\n#{e.backtrace}")
  end

end
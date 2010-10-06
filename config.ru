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
$LOAD_PATH << './lib'
require 'json'
require 'rack'

require 'primo_central_rta'

app = Rack::Builder.new do
  use Rack::ShowExceptions
      
  map "/" do 
    run Proc.new { |env|
      params = Rack::Request.new(env)
      unless (params[:callback]).nil?
        rta_response = {}
        rta_response = PrimoCentralRta.fetch(params)
        rta_response_json = ''
    
        unless rta_response.nil? || rta_response.empty? 
          rta_response_json = rta_response.to_json
        end

        [200, {'Content-Type' => 'javascript/json'}, ["#{params[:callback]}(#{rta_response_json})"]]
      else
        [200, {'Content-Type' => 'text/html'}, [rta_response_json]]
      end
    }
  end
end


run app
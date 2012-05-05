require 'net/http'
require 'json'
require 'timeout'

module Frankly
  
  class Application
    
    WAIT_TIMEOUT = ENV['WAIT_TIMEOUT'].to_i || 240
    
    attr_accessor :host, :port, :selector_engine
    
    def initialize(host = "localhost",port = 37265)
      self.host = host
      self.port = port
      self.selector_engine = 'uiquery'
      wait_for_frank_to_come_up
    end
    
    def touch( selector )
       views_touched = map( selector, 'touch' )
       raise "could not find anything matching [#{selector}] to touch" if views_touched.empty?
    end

    def type_into(selector,text,simulate_keyboard=false)
      unless element_exists?(selector)
        raise "Could not find [#{selector}], it does not exist."
      end
      if simulate_keyboard
        touch( selector )
        map( selector, 'becomeFirstResponder' )
        map( selector, 'setText:', text )
        map( selector, 'endEditing:', true )
      else
        map( selector, 'setText:', text )
      end
    end

    def element_eventually_exists?(query)
      Timeout::timeout(WAIT_TIMEOUT) do
        until element_exists?( query )
          sleep 0.1
        end
      end
    end

    def view_with_mark_eventually_exists?(query)
      Timeout::timeout(WAIT_TIMEOUT) do
        until view_with_mark_exists?( query )
          sleep 0.1
        end
      end
    end

    def element_exists?( query )
       matches = map( query, 'accessibilityLabel' )
       !matches.empty?
    end

     def view_with_mark_exists?(expected_mark)
       element_exists?( "view marked:'#{expected_mark}'" )
     end

     # a better name would be element_exists_and_is_not_hidden
     def element_is_not_hidden?(query)
        matches = map( query, 'isHidden' )
        matches.delete(true)
        !matches.empty?
     end

     def exec(method_name, *method_args)
       operation_map = {
         :method_name => method_name,
         :arguments => method_args
       }

       res = post_to_uispec_server( 'app_exec', :operation => operation_map )

       res = JSON.parse( res )
       if res['outcome'] != 'SUCCESS'
         raise "app_exec #{method_name} failed because: #{res['reason']}\n#{res['details']}"
       end

       res['results']
     end

     def map( query, method_name, *method_args )
       frankly_engine_map( self.selector_engine, query, method_name, *method_args )
     end

     def dump
       res = get_to_uispec_server( 'dump' )
       puts JSON.pretty_generate(JSON.parse(res)) rescue puts res #dumping a super-deep DOM causes errors
     end

     def screenshot(filename, subframe=nil, allwindows=true)
       path = 'screenshot'
       path += '/allwindows' if allwindows
       path += "/frame/" + URI.escape(subframe) if (subframe != nil)

       data = get_to_uispec_server( path )

       open(filename, "wb") do |file|
         file.write(data)
       end
     end

     def portrait?
       'portrait' == current_orientation
     end

     def landscape?
       'landscape' == current_orientation
     end

     def current_orientation
       res = get_to_uispec_server( 'orientation' )
       orientation = JSON.parse( res )['orientation']
       puts "orientation reported as '#{orientation}'" if $DEBUG
       orientation
     end


     def is_accessibility_enabled?
       res = get_to_uispec_server( 'accessibility_check' )
       JSON.parse( res )['accessibility_enabled'] == 'true'
     end

     def wait_for_frank_to_come_up
       num_consec_successes = 0
       num_consec_failures = 0
       Timeout.timeout(20) do
         while num_consec_successes <= 6
           if ping
             num_consec_failures = 0
             num_consec_successes += 1
           else
             num_consec_successes = 0
             num_consec_failures += 1
             if num_consec_failures >= 5 # don't show small timing errors
               print (num_consec_failures == 5 ) ? "\n" : "\r"
               print "PING FAILED" + "!"*num_consec_failures
             end
           end
           STDOUT.flush
           sleep 0.2
         end

         if num_consec_successes < 6
           print (num_consec_successes == 1 ) ? "\n" : "\r"
           print "FRANK!".slice(0,num_consec_successes)
           STDOUT.flush
           puts ''
         end

         if num_consec_failures >= 5
           puts ''
         end
       end

       unless is_accessibility_enabled?
         raise "ACCESSIBILITY DOES NOT APPEAR TO BE ENABLED ON YOUR SIMULATOR. Hit the home button, go to settings, select Accessibility, and turn the inspector on."
       end
     end

     def ping
       get_to_uispec_server('')
       return true
     rescue Errno::ECONNREFUSED
       return false
     rescue EOFError
       return false
     end

    def frankly_engine_map( selector_engine, query, method_name, *method_args )
        operation_map = {
          :method_name => method_name,
          :arguments => method_args,
        }
        res = post_to_uispec_server( 'map', :query => query, :operation => operation_map, :selector_engine => selector_engine )
        res = JSON.parse( res )
        if res['outcome'] != 'SUCCESS'
          raise "frankly_map #{query} #{method_name} failed because: #{res['reason']}\n#{res['details']}"
        end

        res['results']
    end
    
     #taken from Ian Dee's Encumber 
     def post_to_uispec_server( verb, command_hash )
       url = frank_url_for( verb )
       req = Net::HTTP::Post.new url.path
       req.body = command_hash.to_json

       make_http_request( url, req )
     end

     def get_to_uispec_server( verb )
       url = frank_url_for( verb )
       req = Net::HTTP::Get.new url.path
       make_http_request( url, req )
     end

     def frank_url_for( verb , port=nil )
       url = URI.parse "http://#{self.host}:#{self.port}/"
       url.path = '/'+verb
       url
     end

     def make_http_request( url, req )
       http = Net::HTTP.new(url.host, url.port)

       res = http.start do |sess|
         sess.request req
       end

       res.body
     end
    
  end
  
end
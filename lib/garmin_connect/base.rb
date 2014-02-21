require 'net/http'
require 'json'
module GarminConnect
  # def setup(p = {})
  #   Base.format = p[:format] || :json
  #   Base.auth(p)
  # end
  # def auth(p = {})
  #   Base.auth(p)
  # end
  # module_function :auth
  # module_function :setup
  class User
    def initialize(username, password = nil)
      # user auth isnt working right now anyways
      @username = username
    end
    def activity_list(limit = 100, start = 1)
      return @activity_list if @activity_list
      uri = URI "http://connect.garmin.com/proxy/activitylist-service/activities/#{@username}?start=#{start}&limit=#{limit}"
      @activity_list = JSON.parse(Net::HTTP.get(uri))['activityList']
    end
    def activity_ids(limit = 100, start = 1)
      self.activity_list(limit, start).map{ |hash| hash['activityId'] }
    end

    def activities(limit = 100, start = 1)
      return @activities if @activities
      @activities = activity_list(limit, start).map { |a| Activity.new(a['activityId']) }
    end
    def activity(arg)
      Activity.new(arg)
    end
    def most_recent(count = 1)
      count == 1 ? self.activities(1).first : self.activities(count)
    end
  end

  module Base
    extend GarminConnect
    class << self
      def generate(obj) # this is the only remaining place that the case doesnt work for Hash, Array
        # puts obj.class.inspect
        # puts Hash === obj
        case obj
        when Base::Hash, Base::Array
          obj
        when Hash
          Base::Hash[obj]
        when Array
          Base::Array[obj]
        else
          obj.class.to_s == 'Hash' ? Base::Hash[obj] : Base::Array[obj]
        end
      end
      # def auth(p = {})
      #   full = "https://connect.garmin.com/signin?login=login&login:signInButton=Sign%20In&javax.faces.ViewState=j_id1&login:loginUsernameField=#{p[:user]}&login:password=#{p[:pass]}&login:rememberMe=on"
      #   url = 'https://connect.garmin.com/signin'
      #   self.cookies = (RestClient.get url).cookies
      #   if p[:user] && p[:pass]
      #     rr = RestClient::Resource.new full
      #     r = rr.post("", cookies: self.cookies) do |response, request, result, &block|
      #       if [301, 302, 307].include? response.code
      #         response.follow_redirection(request, result, &block)
      #         self.cookies = response.cookies
      #       else
      #         response.return!(request, result, &block)
      #       end
      #     end
      #   end
      # end
      def request(base, format = nil, path)
        url = base + (format or self.format).to_s + path
        response = Net::HTTP.get(URI url)
        # response = RestClient.get(url, :cookies => self.cookies) do |response, request, result, &block|
        #   if [403].include? response.code
        #     puts request.inspect
        #   else
        #     response.return!(request, result, &block)
        #   end
        # end
        JSON.parse(response)
      end
      def cookies
        @@cookies ||= ''
      end
      def cookies=(cookies)
        @@cookies = cookies
      end
      def format
        @@format ||= :json
      end
      def format=(format)
        format = :json unless [:json, :gpx, :tcx].include? format
        @@format = format
      end
    end
  end
  class Base::Hash < Hash
    # garmin data uses 'display' and 'key' as keys. this is why we can't use Hashie as well
    def key
      self.fetch('key') { super }
    end
    def display
      self.fetch('display') { super }
    end
    def method_missing(method, *args)
      if args.size == 1 && method.to_s =~ /(.*)=$/ # ripped from hashie
        return self[$1.to_s] = args.first
      end
      obj = self[method.to_s]
      case obj
      when Base::Hash, Base::Array
        obj
      when Hash, Array
        self[method.to_s] = Base.generate(obj)
      when nil
        super(method, *args)
      else
        obj
      end
    end
  end
  class Base::Array < Array
    def self.[](obj)
      super(*obj.map{ |a| Base.generate(a) })
    end
  end
end

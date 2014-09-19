require 'active_support/time'
module GarminConnect
  class User
    class << self
      def base
        'http://connect.garmin.com/proxy/user-service-1.0/'
      end
      def get(format = nil)
        Base.request(self.base, format, '/user')
      end
    end
  end
  class Metric
  attr_accessor :multipled_temp, :multipled_hum, :custom_data, :seconds, :data
    %w{directLongitude directHeartRate directHeartRateZone directHeartRatePercentMax directLatitude directTimestamp directSpeed directPace directElevation sumDistance sumElapsedDuration sumDuration sumMovingDuration}.each do |item|
      define_method(item.to_sym) { @data[@data_types.index(item.to_s)] }
    end

    alias :longitude          :directLongitude
    alias :hr                 :directHeartRate
    alias :hr_zone            :directHeartRateZone
    alias :hr_percent         :directHeartRatePercentMax
    alias :latitude           :directLatitude
    alias :timestamp          :directTimestamp
    alias :speed              :directSpeed
    alias :pace               :directPace
    alias :elevation          :directElevation
    alias :distance           :sumDistance
    alias :elapsed_duration   :sumElapsedDuration
    alias :sum_duration       :sumDuration
    alias :moving_duration    :sumMovingDuration
    def initialize(arr, data_types)
      @data_types = data_types
      @custom_data = {}
      @data = arr
    end
    def time
      Time.at(directTimestamp / 1000)
    end
    def method_missing(method, *args)
      @data[@data_types.index(method.to_s)]
    end
    def latlong
      [latitude, longitude]
    end
    def to_s
      inspect
    end

    # def seconds
      # trying to find a way to define it here
    # end
    # alias :lon :longitude
    class << self
      # @@order = %w{ longitude hr hr_zone hr_percent latitude timestamp speed pace elevation distance elapsed_duration sum_duration moving_duration }
      # def position(what = nil)
      #   @@order.index(what)
      # end
      def init_multiple(metrics, data_types)
        metrics.map{ |hash| new(hash['metrics'], data_types) }
      end
    end
  end
  class Activity
    attr_reader :attributes

    def initialize(data)
      case data
      when Hash
        # nil
      when Integer, String
        data = self.class.get(data)
      end
      @metrics = nil
      @attributes = data
    end
    def [](something)
      @attributes[something]
    end
    def id
      self.activityId
    end
    def time(what = :begin)
      h = what == :begin ? self.activitySummary.BeginTimestamp : self.activitySummary.EndTimestamp
      ActiveSupport::TimeWithZone.new(Time.parse(h.value), ActiveSupport::TimeZone.new(h.uom))
    end
    def hr_data?
      # puts @attributes.keys
      activitySummary.has_key? 'WeightedMeanHeartRate'
    end
    def avg_hr
      hr_data? and self.activitySummary.WeightedMeanHeartRate.bpm.value.to_i
    end
    def distance
      activitySummary.SumDistance.value.to_f.round(2)
    end
    def pace_secs
      (activitySummary.WeightedMeanMovingPace.value.to_f * 60).round
    end
    def pace
      Time.at(self.pace_secs).strftime("%M:%S")
    end
    def dur_secs
      activitySummary.SumElapsedDuration.value.to_f.round
    end
    def duration
      Time.at(self.dur_secs).strftime("%M:%S")
    end
    def details
      @details ||= self.class.details(self.activityId)
    end
    def metrics
      return @metrics if @metrics
      metric_data = details.measurements.sort_by{ |hash| hash['metricsIndex'] }.map{ |hash| hash['key'] }
      # puts metric_data.inspect
      @metrics ||= Metric.init_multiple(details.metrics, metric_data)
    end
    def latlong(what = :begin)
      case what
      when :begin
        [self.activitySummary.BeginLatitude.value, self.activitySummary.BeginLongitude.value]
      when :end
        [self.activitySummary.EndLatitude.value, self.activitySummary.EndLongitude.value]
      end
    end
    def method_missing(method, *args)
      if args.size == 1 && method.to_s =~ /(.*)=$/ # ripped from hashie
        return @attributes[$1.to_s] = args.first
      end
      obj = @attributes[method.to_s]
      case obj
      when Base::Hash, Base::Array
        obj
      when Hash, Array
        @attributes[method.to_s] = Base.generate(obj)
      when nil
        super(method, *args)
      else
        obj
      end
    end
    def url
      "http://connect.garmin.com/activity/#{self.activityId}"
    end
    class << self
      def base
        'http://connect.garmin.com/proxy/activity-service-1.3/'
      end
      def get(id, format = nil)
        Base.request(self.base, format, "/activity/#{validate_id(id)}")['activity']
      end
      def details(id, format = nil)
        h = Base.request(self.base, format, "/activityDetails/#{validate_id(id)}")['com.garmin.activity.details.json.ActivityDetails']
        Base::Hash[h]
      end
      # def course(id, format = nil)
      #   h = Base.request(self.base, format, "/course/#{validate_id(id)}")['com.garmin.activity.details.json.ActivityDetails']
      #   Base::Hash[h]
      # end
      def validate_id(id)
        id = Integer === id ? id : id.split('/').last
      end

      def activities(format = nil)
        Base.request(self.base, format, "/activities")
      end
    end
  end
end

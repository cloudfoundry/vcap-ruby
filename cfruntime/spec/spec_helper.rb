# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift File.join(File.dirname(__FILE__), '..')
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

home = File.join(File.dirname(__FILE__), '/..')
ENV['BUNDLE_GEMFILE'] = "#{home}/Gemfile"

require 'bundler'
require 'bundler/setup'
require 'rubygems'
require 'rspec'


module CFRuntime
  module Test

    SOME_SERVER = '172.30.48.73'
    SOME_PORT = 56789

    def self.host
      SOME_SERVER
    end

    def self.port
      "#{SOME_PORT}"
    end

    def with_vcap_application
      vcap_app = '{"instance_id":"#{secure_uuid}",
        "instance_index": 0,
        "name":"tr_env",
        "uris":["tr_env.cloudfoundry.com"],
        "users":["trisberg@vmware.com"],
        "version":"#{secure_uuid}",
        "start":"2011-11-05 13:29:32 +0000",
        "runtime":"ruby19",
        "state_timestamp":1320499772,
        "port":SOME_PORT,
        "limits":{"fds":256,"mem":134217728,"disk":2147483648},
        "host":"#{SOME_SERVER}"}'
      ENV['VCAP_APPLICATION'] = vcap_app
      ENV['VCAP_APP_HOST'] = SOME_SERVER
      ENV['VCAP_APP_PORT'] = "#{SOME_PORT}"
      yield
    end

    def with_vcap_services(services)
      vcap_svcs = '{'
      services.each {|type, svcs|
        vcap_svcs = vcap_svcs + '"' + type + '":['
          svcs.each do |svc|
            vcap_svcs = vcap_svcs + svc + ','
          end
          vcap_svcs.chomp!(',')
        vcap_svcs = vcap_svcs + '],'
      }
      vcap_svcs.chomp!(',')
      vcap_svcs = vcap_svcs + '}'
      ENV['VCAP_SERVICES'] = vcap_svcs
      yield
    end

    # this is in commons.rb - could require this maybe?
    def secure_uuid
      result = File.open('/dev/urandom') { |x| x.read(16).unpack('H*')[0] }
    end

    def mongo_version
      "1.8"
    end

    def redis_version
      "2.2"
    end

    def rabbit_version
      "2.4"
    end

    def create_mongo_service(name)
      create_service(name, "mongodb", mongo_version,"db")
    end

    def create_redis_service(name)
      create_service(name, "redis", redis_version)
    end

    def create_rabbit_service(name, vhost=nil)
      "{\"name\":\"#{name}\",\"label\":\"rabbitmq-#{rabbit_version}\"," +
      "\"plan\":\"free\",\"tags\":[\"rabbitmq\",\"rabbitmq-#{rabbit_version}\"]," +
      "\"credentials\":{\"hostname\":\"#{SOME_SERVER}\",\"port\":25046,\"user\":\"#{secure_uuid}\"," +
      "\"pass\":\"#{secure_uuid}\",\"vhost\":\"#{vhost}\"}}"
    end

    def create_rabbit_srs_service(name, vhost=nil)
      if vhost
        url = "amqp://#{secure_uuid}:#{secure_uuid}@#{SOME_SERVER}:25046/#{vhost}"
      else
        url = "amqp://#{secure_uuid}:#{secure_uuid}@#{SOME_SERVER}:25046"
      end
      "{\"name\":\"#{name}\",\"label\":\"rabbitmq-#{rabbit_version}\"," +
      "\"plan\":\"free\",\"tags\":[\"rabbitmq\",\"rabbitmq-#{rabbit_version}\"]," +
      "\"credentials\":{\"url\":\"#{url}\"}}"
    end

    def create_service(name, type, version, db=nil)
      svc = "{\"name\":\"#{name}\",\"label\":\"#{type}-#{version}\",\"plan\":\"free\"," +
        "\"tags\":[\"#{type}\",\"#{type}-#{version}\"],\"credentials\":{\"hostname\":\"#{SOME_SERVER}\"," +
        "\"host\":\"#{SOME_SERVER}\",\"port\":25046,\"username\":\"#{secure_uuid}\",\"password\":\"#{secure_uuid}\"," +
        "\"name\":\"#{secure_uuid}\""
        if db
          svc = svc + ", \"db\":\"#{db}\""
        end
        svc = svc + '}}'
    end
  end
end

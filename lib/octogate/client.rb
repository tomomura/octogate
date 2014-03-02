require "faraday"
require "uri"
require "octogate/transfer_request"

class Octogate::Client
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def request_to_targets
    Octogate.config.targets.each do |target_name, t|
      if match_target?(t)
        request(t)
      end
    end
  end

  def request(t)
    uri = URI(t.url)

    options = {url: t.url}
    options.merge!(ssl_options) if uri.scheme == "https"

    conn = build_connection(options, t.username, t.password)

    params = t.params.respond_to?(:call) ? t.params.call(event) : t.params

    case t.http_method
    when :get
      Octogate::TransferRequest::GET.new(conn)
        .do_request(url: uri.path, params: params)
    when :post
      Octogate::TransferRequest::POST.new(conn)
        .do_request(url: uri.path, params: params, parameter_type: t.parameter_type)
    end
  end

  private

  def match_target?(target)
    condition = event.default_condition
    case target.match
    when Proc
      condition && instance_exec(event, &target.match)
    when nil
      condition
    else
      condition && !!target.match
    end
  end

  def build_connection(options, username = nil, password = nil)
    conn = Faraday.new(options) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger if ENV["RACK_ENV"] == "development" || ENV["RACK_ENV"] == "production"
      faraday.adapter  Faraday.default_adapter
    end
    conn.basic_auth(username, password) if username && password
    conn
  end

  def ssl_options
    if Octogate.config.ssl_verify
      Octogate.config.ca_file ? {ssl: {ca_file: Octogate.config.ca_file}} : {}
    else
      {ssl: {verify: false}}
    end
  end
end


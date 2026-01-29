class Rack::Attack
  # Throttle all requests by IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  # Throttle auth endpoints more strictly
  throttle("auth/ip", limit: 5, period: 60.seconds) do |req|
    if req.path.include?("/sign_in") || req.path.include?("/password")
      req.ip
    end
  end

  # Throttle GraphQL mutations
  throttle("graphql/ip", limit: 60, period: 1.minute) do |req|
    if req.path == "/graphql" && req.post?
      req.ip
    end
  end

  # Block bad actors
  blocklist("block bad IPs") do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 1.minute, bantime: 1.hour) do
      req.path.include?("/sign_in") && req.post?
    end
  end

  # Custom response
  self.blocklisted_responder = lambda do |_env|
    [429, { "Content-Type" => "application/json" }, [{ error: "Too many requests" }.to_json]]
  end

  self.throttled_responder = lambda do |env|
    retry_after = (env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ error: "Too many requests. Retry later." }.to_json]
    ]
  end
end

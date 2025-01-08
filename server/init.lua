local http = require "resty.http"
local cjson = require "cjson"
local httpc = http.new()

-- Helper function to log messages
local function log(message)
    ngx.log(ngx.ERR, message)
end

-- Main handler function
local function handle_request()
	-- Log the received method for debugging
    local method = ngx.req.get_method()
    log("HTTP method received: " .. method)

    -- Handle preflight (OPTIONS) requests
    if method == "OPTIONS" then
        ngx.header["Access-Control-Allow-Origin"] = "*"
        ngx.header["Access-Control-Allow-Methods"] = "POST, OPTIONS"
        ngx.header["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        ngx.header["Access-Control-Max-Age"] = "86400"
        ngx.status = 204
        ngx.say("") -- Empty response body
        return
    end

    -- Enable CORS for POST and other requests
    ngx.header["Access-Control-Allow-Origin"] = "*"

    -- Read and parse the POST request body
    ngx.req.read_body()
    local body_data = ngx.req.get_body_data()
    if not body_data then
        log("No request body received")
        ngx.status = 400
        ngx.say("No request body received")
        return
    end

    log("Request body received: " .. body_data)

    -- Extract parameters from the request body
    local params, err = cjson.decode(body_data)
    if not params then
    	log("Error decoding JSON: " .. tostring(err))
    	ngx.status = 400
    	ngx.say("Invalid JSON format")
    	return
	end

    -- Log the extracted parameters
    log("Extracted credentials:")
    log("School Code: " .. tostring(params.schoolCode))
    log("Date: " .. tostring(params.date))
    log("User Type: " .. tostring(params.userType))
    log("Password: " .. tostring(params.password))

    -- Validate input parameters
    if not (params.schoolCode and params.date and params.userType and params.password) then
        log("Missing required parameters")
        ngx.status = 400
        ngx.say("Missing required parameters")
        return
    end

    -- Parse JSON body
    local params, err = cjson.decode(body_data)
    if not params then
        log("Error decoding JSON: " .. tostring(err))
        ngx.status = 400
        ngx.say("Invalid JSON format")
        return
    end

    -- Validate input parameters
    if not (params.schoolCode and params.date and params.userType and params.password) then
        log("Missing required parameters")
        ngx.status = 400
        ngx.say("Missing required parameters")
        return
    end

    -- Prepare the URL
    local url = string.format("https://www.stundenplan24.de/%s/mobil/mobdaten/PlanKl%s.xml", params.schoolCode, params.date)
    log("Connecting to URL: " .. url)

    -- Create HTTP client
    local httpc = http.new()
    httpc:set_timeout(5000) -- Set timeout to 5 seconds

    -- Perform the HTTP request
    local res, err = httpc:request_uri(url, {
        method = "GET",
        headers = {
            ["Authorization"] = "Basic " .. ngx.encode_base64(params.userType .. ":" .. params.password)
        },
        ssl_verify = false, -- Verify SSL certificates
    	ssl_ca_cert = "/etc/ssl/certs/ca-certificates.crt"
    })

    -- Check for errors in the HTTP request
    if not res then
        log("HTTP request failed: " .. tostring(err))
        ngx.status = 500
        ngx.say("Failed to fetch XML: " .. tostring(err))
        return
    end

    -- Log the response details
    log("Response Status: " .. res.status)
    log("Response Body: " .. res.body)

    -- Return the response body
    ngx.header.content_type = "application/xml"
    ngx.status = res.status
    ngx.say(res.body)
end

-- Handle the incoming request
handle_request()



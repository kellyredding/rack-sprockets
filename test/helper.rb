# this file is automatically required in when you require 'assert' in your tests
# put test helpers here

# add root dir to the load path
$LOAD_PATH.unshift(File.expand_path("../..", __FILE__))

class Assert::Context

  def file_path(*segments)
    segs = segments.unshift([File.dirname(__FILE__), '..']).flatten
    File.expand_path(segs.join(File::SEPARATOR))
  end

  def sprockets_request(config, method, path_info, query="")
    Rack::Sprockets::Request.new(config, {
      'REQUEST_METHOD' => method,
      'PATH_INFO' => path_info,
      'QUERY_STRING' => query
    })
  end

  def sprockets_response(config, request)
    Rack::Sprockets::Response.new(config, request ? request.env : {}, request)
  end

end

# network_mocker.gd
# Ephemeral loopback HTTP/TCP server with route matching, JSON mocking, latency simulation, and spy request history tracking.
class_name NetworkMocker
extends Node

const DEFAULT_STATUS_TEXTS: Dictionary = {
	200: "OK",
	201: "Created",
	202: "Accepted",
	204: "No Content",
	301: "Moved Permanently",
	302: "Found",
	400: "Bad Request",
	401: "Unauthorized",
	403: "Forbidden",
	404: "Not Found",
	405: "Method Not Allowed",
	409: "Conflict",
	500: "Internal Server Error",
	502: "Bad Gateway",
	503: "Service Unavailable"
}

var _tcp_server: TCPServer = TCPServer.new()
var _port: int = 0
var _is_running: bool = false
var _routes: Array[Dictionary] = []
var _history: Array[Dictionary] = []
var _active_peers: Array[Dictionary] = []
var _pending_responses: Array[Dictionary] = []
var _closing_peers: Array[Dictionary] = []

func _ready() -> void:
	if not _is_running:
		start()

func _exit_tree() -> void:
	stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		stop()

## Starts the ephemeral loopback HTTP server on the specified port (or auto-assigned port).
func start(preferred_port: int = 0) -> int:
	if _is_running and _port > 0:
		return _port
		
	var err = FAILED
	_tcp_server.stop()
	
	if preferred_port > 0:
		err = _tcp_server.listen(preferred_port, "127.0.0.1")
		if err == OK:
			_port = preferred_port
			_is_running = true
			return _port
			
	# Scan for an available port in the 18080-18999 range
	for fallback_port in range(18080, 18999):
		_tcp_server.stop()
		err = _tcp_server.listen(fallback_port, "127.0.0.1")
		if err == OK:
			_port = fallback_port
			_is_running = true
			return _port
				
	push_error("NetworkMocker: Failed to start TCP server. Error code: %d" % err)
	_port = 0
	_is_running = false
	return _port

## Stops the server and closes all active and pending connections.
func stop() -> void:
	if not _is_running:
		return
	for conn in _active_peers:
		var peer: StreamPeerTCP = conn.get("peer")
		if peer and peer.get_status() != StreamPeerTCP.STATUS_NONE:
			peer.disconnect_from_host()
	_active_peers.clear()
	for pending in _pending_responses:
		var peer: StreamPeerTCP = pending.get("peer")
		if peer and peer.get_status() != StreamPeerTCP.STATUS_NONE:
			peer.disconnect_from_host()
	_pending_responses.clear()
	for closing in _closing_peers:
		var peer: StreamPeerTCP = closing.get("peer")
		if peer and peer.get_status() != StreamPeerTCP.STATUS_NONE:
			peer.disconnect_from_host()
	_closing_peers.clear()
	
	_tcp_server.stop()
	_is_running = false

## Returns the port number the server is bound to.
func get_port() -> int:
	return _port

## Returns the base URL of the mock HTTP server (e.g. 'http://127.0.0.1:18080').
func get_base_url() -> String:
	return "http://127.0.0.1:%d" % _port

## Returns a full URL for the specified path on this mock server.
func get_url(path: String = "") -> String:
	var clean_path = path if path.begins_with("/") else ("/" + path)
	var effective_port = _port if _port > 0 else 18080
	return "http://127.0.0.1:%d%s" % [effective_port, clean_path]

## Intercepts HTTP requests matching method and path, responding with the given response body and status code.
func intercept_route(
	method: String,
	path_pattern: String,
	response_body: Variant,
	status_code: int = 200,
	headers: Dictionary = {},
	latency_ms: float = 0.0
) -> Dictionary:
	var route = {
		"method": method.to_upper(),
		"path": path_pattern,
		"response_body": response_body,
		"status_code": status_code,
		"headers": headers.duplicate(),
		"latency_ms": latency_ms
	}
	_routes.append(route)
	return route

## Registers a JSON mock response route for the specified URL path.
func mock_json(
	path_pattern: String,
	json_data: Variant,
	status_code: int = 200,
	method: String = "GET",
	latency_ms: float = 0.0
) -> Dictionary:
	var body_str = JSON.stringify(json_data)
	var headers = {"Content-Type": "application/json"}
	return intercept_route(method, path_pattern, body_str, status_code, headers, latency_ms)

## Returns all captured HTTP request records, optionally filtered by path and method.
func get_history(path_filter: String = "", method_filter: String = "") -> Array[Dictionary]:
	if path_filter == "" and method_filter == "":
		return _history.duplicate()
	var filtered: Array[Dictionary] = []
	for req in _history:
		var match_p = (path_filter == "" or req["path"] == path_filter or req["path"].begins_with(path_filter))
		var match_m = (method_filter == "" or req["method"] == method_filter.to_upper())
		if match_p and match_m:
			filtered.append(req)
	return filtered

## Returns the most recent captured HTTP request matching the optional path filter.
func get_last_request(path_filter: String = "") -> Dictionary:
	var items = get_history(path_filter)
	if items.is_empty():
		return {}
	return items[-1]

## Asserts that the specified method and path was requested an expected number of times (or >= 1 if count == -1).
func assert_requested(method: String, path_filter: String, expected_count: int = -1) -> bool:
	var matched = get_history(path_filter, method)
	if expected_count < 0:
		return matched.size() > 0
	return matched.size() == expected_count

## Clears all recorded request history.
func clear_history() -> void:
	_history.clear()

## Clears all registered mock routes and request history.
func reset_routes() -> void:
	_routes.clear()
	_history.clear()

func _path_matches(pattern: String, path: String) -> bool:
	if pattern == path or pattern == "*":
		return true
	if pattern.ends_with("*") and path.begins_with(pattern.trim_suffix("*")):
		return true
	return false

## Looks up a registered route matching method and path.
func find_route(method: String, path: String) -> Dictionary:
	for r in _routes:
		if r["method"] == method.to_upper() or r["method"] == "*":
			if _path_matches(r["path"], path):
				return r
	return {}

func _process(_delta: float) -> void:
	if not _is_running:
		return
		
	# Accept new incoming TCP connections
	while _tcp_server.is_connection_available():
		var peer: StreamPeerTCP = _tcp_server.take_connection()
		if peer:
			_active_peers.append({
				"peer": peer,
				"buffer": PackedByteArray(),
				"created_at": Time.get_ticks_msec()
			})
			
	# Process active incoming connections
	var now = Time.get_ticks_msec()
	for i in range(_active_peers.size() - 1, -1, -1):
		var conn = _active_peers[i]
		var peer: StreamPeerTCP = conn["peer"]
		peer.poll()
		var status = peer.get_status()
		if status == StreamPeerTCP.STATUS_ERROR:
			_active_peers.remove_at(i)
			continue
			
		var avail = peer.get_available_bytes()
		if avail > 0:
			var read_res = peer.get_partial_data(avail)
			if read_res[0] == OK:
				var bytes: PackedByteArray = read_res[1]
				var buf: PackedByteArray = conn["buffer"]
				buf.append_array(bytes)
				conn["buffer"] = buf
				
				var text = buf.get_string_from_utf8()
				var header_end = text.find("\r\n\r\n")
				var sep_len = 4
				if header_end == -1:
					header_end = text.find("\n\n")
					sep_len = 2
					
				if header_end != -1:
					var headers_part = text.substr(0, header_end)
					var content_length = 0
					for h_line in headers_part.split("\n"):
						if h_line.to_lower().begins_with("content-length:"):
							var val_part = h_line.split(":", true, 1)[1].strip_edges()
							content_length = int(val_part)
							
					var body_len = buf.size() - (header_end + sep_len)
					if body_len >= content_length:
						_active_peers.remove_at(i)
						_handle_complete_request(peer, text)
						continue
						
		# Timeout after 5 seconds
		if now - conn["created_at"] > 5000:
			peer.disconnect_from_host()
			_active_peers.remove_at(i)

	# Process pending delayed responses
	for i in range(_pending_responses.size() - 1, -1, -1):
		var pending = _pending_responses[i]
		if now >= pending["ready_at_ms"]:
			var peer: StreamPeerTCP = pending["peer"]
			peer.poll()
			if peer and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
				peer.put_data(pending["response_bytes"])
				_closing_peers.append({
					"peer": peer,
					"sent_at": now
				})
			_pending_responses.remove_at(i)

	# Process closing peers (hold reference briefly for data flushing)
	for i in range(_closing_peers.size() - 1, -1, -1):
		var closing = _closing_peers[i]
		var peer: StreamPeerTCP = closing["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or now - closing["sent_at"] > 1000:
			peer.disconnect_from_host()
			_closing_peers.remove_at(i)

func _handle_complete_request(peer: StreamPeerTCP, raw_text: String) -> void:
	if raw_text.is_empty():
		return
		
	var req = _parse_http_request(raw_text)
	_history.append(req)
	
	# Find matching route
	var matched_route: Dictionary = _find_matching_route(req["method"], req["path"])
	var status_code = 200
	var response_body = ""
	var headers: Dictionary = {}
	var latency_ms = 0.0
	
	if not matched_route.is_empty():
		status_code = matched_route.get("status_code", 200)
		response_body = matched_route.get("response_body", "")
		headers = matched_route.get("headers", {}).duplicate()
		latency_ms = matched_route.get("latency_ms", 0.0)
	else:
		status_code = 404
		response_body = JSON.stringify({"error": "Route not found", "path": req["path"], "method": req["method"]})
		headers = {"Content-Type": "application/json"}
		
	var response_bytes = _build_http_response(status_code, response_body, headers)
	
	if latency_ms > 0.0:
		_pending_responses.append({
			"peer": peer,
			"response_bytes": response_bytes,
			"ready_at_ms": Time.get_ticks_msec() + int(latency_ms)
		})
	else:
		peer.put_data(response_bytes)
		_closing_peers.append({
			"peer": peer,
			"sent_at": Time.get_ticks_msec()
		})

func _parse_http_request(raw_text: String) -> Dictionary:
	var lines = raw_text.split("\r\n")
	if lines.size() == 1:
		lines = raw_text.split("\n")
		
	var request_line = lines[0] if lines.size() > 0 else ""
	var parts = request_line.split(" ")
	var method = parts[0] if parts.size() > 0 else "GET"
	var full_path = parts[1] if parts.size() > 1 else "/"
	
	var path = full_path
	var query_params: Dictionary = {}
	if full_path.contains("?"):
		var p_parts = full_path.split("?", true, 1)
		path = p_parts[0]
		var q_str = p_parts[1]
		for pair in q_str.split("&"):
			if pair.contains("="):
				var kv = pair.split("=", true, 1)
				query_params[kv[0]] = kv[1]
			elif pair != "":
				query_params[pair] = true
				
	var headers: Dictionary = {}
	var body_start_idx = -1
	for i in range(1, lines.size()):
		var line = lines[i]
		if line.strip_edges() == "":
			body_start_idx = i + 1
			break
		if line.contains(":"):
			var h_parts = line.split(":", true, 1)
			headers[h_parts[0].strip_edges().to_lower()] = h_parts[1].strip_edges()
			
	var body = ""
	if body_start_idx >= 0 and body_start_idx < lines.size():
		var body_lines = lines.slice(body_start_idx)
		body = "\n".join(body_lines)
		
	var body_json: Variant = null
	if body != "":
		body_json = JSON.parse_string(body)
		
	return {
		"method": method.to_upper(),
		"path": path,
		"raw_url": full_path,
		"query": query_params,
		"headers": headers,
		"body": body,
		"body_json": body_json,
		"timestamp_ms": Time.get_ticks_msec()
	}

func _find_matching_route(method: String, path: String) -> Dictionary:
	for i in range(_routes.size() - 1, -1, -1):
		var r = _routes[i]
		var r_method: String = r.get("method", "*")
		var r_path: String = r.get("path", "")
		
		var method_matches = (r_method == "*" or r_method == method)
		var path_matches = false
		if r_path == path:
			path_matches = true
		elif r_path.ends_with("*") and path.begins_with(r_path.trim_suffix("*")):
			path_matches = true
			
		if method_matches and path_matches:
			return r
	return {}

func _build_http_response(status_code: int, body_content: Variant, headers: Dictionary) -> PackedByteArray:
	var body_bytes: PackedByteArray = PackedByteArray()
	if body_content is PackedByteArray:
		body_bytes = body_content
	elif body_content is Dictionary or body_content is Array:
		var json_str = JSON.stringify(body_content)
		body_bytes = json_str.to_utf8_buffer()
		if not headers.has("Content-Type") and not headers.has("content-type"):
			headers["Content-Type"] = "application/json"
	else:
		var s = str(body_content)
		body_bytes = s.to_utf8_buffer()
		if not headers.has("Content-Type") and not headers.has("content-type"):
			headers["Content-Type"] = "text/plain; charset=utf-8"
			
	if not headers.has("Server") and not headers.has("server"):
		headers["Server"] = "GDTest-NetworkMocker/3.0"
	if not headers.has("Connection") and not headers.has("connection"):
		headers["Connection"] = "close"
	headers["Content-Length"] = str(body_bytes.size())
	
	var status_text = DEFAULT_STATUS_TEXTS.get(status_code, "OK")
	var header_text = "HTTP/1.1 %d %s\r\n" % [status_code, status_text]
	for k in headers.keys():
		header_text += "%s: %s\r\n" % [str(k), str(headers[k])]
	header_text += "\r\n"
	
	var res_bytes = header_text.to_utf8_buffer()
	res_bytes.append_array(body_bytes)
	return res_bytes

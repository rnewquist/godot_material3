# benchmark_engine.gd
# High-resolution micro-benchmarking engine for GDTest 3.0.
# Computes warmup-isolated statistical metrics (min, max, mean, median, p90, p95, p99, stddev, ops/sec, memory tracking)
# and outputs beautifully formatted ASCII and Markdown performance tables.
class_name BenchmarkEngine
extends RefCounted

## Runs a synchronous benchmark on a callable with warmup, statistical metrics, and memory tracking.
## For ultra-fast micro-operations (< 1μs), use batch_size > 1 to amortize call overhead.
static func benchmark(
	name: String,
	callable: Callable,
	iterations: int = 1000,
	warmup_iterations: int = 50,
	batch_size: int = 1
) -> Dictionary:
	if iterations <= 0:
		iterations = 1
	if batch_size <= 0:
		batch_size = 1
		
	# 1. Warmup Phase (prime CPU instruction cache, branch predictors, and JIT/engine caches)
	for w in range(warmup_iterations):
		for b in range(batch_size):
			callable.call()
			
	# 2. Measurement Phase
	var samples_usec: Array[float] = []
	samples_usec.resize(iterations)
	
	var mem_before = OS.get_static_memory_usage()
	var total_start_time = Time.get_ticks_usec()
	
	for i in range(iterations):
		var t0 = Time.get_ticks_usec()
		for b in range(batch_size):
			callable.call()
		var t1 = Time.get_ticks_usec()
		var sample_dur = float(t1 - t0) / float(batch_size)
		samples_usec[i] = sample_dur
		
	var total_end_time = Time.get_ticks_usec()
	var mem_after = OS.get_static_memory_usage()
	var total_time_usec = total_end_time - total_start_time
	var mem_delta = mem_after - mem_before
	
	# 3. Statistical Analysis
	var stats = _compute_statistics(samples_usec, total_time_usec, iterations * batch_size)
	stats["name"] = name
	stats["iterations"] = iterations
	stats["warmup_iterations"] = warmup_iterations
	stats["batch_size"] = batch_size
	stats["total_time_usec"] = total_time_usec
	stats["memory_bytes_before"] = mem_before
	stats["memory_bytes_after"] = mem_after
	stats["memory_bytes_delta"] = mem_delta
	
	return stats

## Runs an asynchronous benchmark on a coroutine callable.
static func benchmark_async(
	name: String,
	callable: Callable,
	iterations: int = 50,
	warmup_iterations: int = 5
) -> Dictionary:
	if iterations <= 0:
		iterations = 1
		
	# 1. Warmup Phase
	for w in range(warmup_iterations):
		await callable.call()
		
	# 2. Measurement Phase
	var samples_usec: Array[float] = []
	samples_usec.resize(iterations)
	
	var mem_before = OS.get_static_memory_usage()
	var total_start_time = Time.get_ticks_usec()
	
	for i in range(iterations):
		var t0 = Time.get_ticks_usec()
		await callable.call()
		var t1 = Time.get_ticks_usec()
		samples_usec[i] = float(t1 - t0)
		
	var total_end_time = Time.get_ticks_usec()
	var mem_after = OS.get_static_memory_usage()
	var total_time_usec = total_end_time - total_start_time
	var mem_delta = mem_after - mem_before
	
	# 3. Statistical Analysis
	var stats = _compute_statistics(samples_usec, total_time_usec, iterations)
	stats["name"] = name
	stats["iterations"] = iterations
	stats["warmup_iterations"] = warmup_iterations
	stats["batch_size"] = 1
	stats["total_time_usec"] = total_time_usec
	stats["memory_bytes_before"] = mem_before
	stats["memory_bytes_after"] = mem_after
	stats["memory_bytes_delta"] = mem_delta
	
	return stats

## Computes rigorous statistical percentiles, mean, variance, stddev, and throughput.
static func _compute_statistics(samples: Array[float], total_time_usec: int, total_ops: int) -> Dictionary:
	var count = samples.size()
	if count == 0:
		return {
			"min_usec": 0.0, "max_usec": 0.0, "mean_usec": 0.0, "median_usec": 0.0,
			"p90_usec": 0.0, "p95_usec": 0.0, "p99_usec": 0.0, "stddev_usec": 0.0,
			"variance_usec": 0.0, "ops_per_sec": 0.0
		}
		
	var sorted_samples = samples.duplicate()
	sorted_samples.sort()
	
	var min_val = sorted_samples[0]
	var max_val = sorted_samples[-1]
	
	# Arithmetic Mean
	var sum_val = 0.0
	for s in sorted_samples:
		sum_val += s
	var mean_val = sum_val / float(count)
	
	# Median (50th Percentile)
	var median_val: float
	if count % 2 == 1:
		median_val = sorted_samples[count / 2]
	else:
		median_val = (sorted_samples[count / 2 - 1] + sorted_samples[count / 2]) / 2.0
		
	# Percentiles
	var p90_val = sorted_samples[mini(int(ceil(float(count) * 0.90)) - 1, count - 1)]
	var p95_val = sorted_samples[mini(int(ceil(float(count) * 0.95)) - 1, count - 1)]
	var p99_val = sorted_samples[mini(int(ceil(float(count) * 0.99)) - 1, count - 1)]
	
	# Variance & Standard Deviation
	var variance_sum = 0.0
	for s in sorted_samples:
		var diff = s - mean_val
		variance_sum += diff * diff
	var variance_val = variance_sum / float(count)
	var stddev_val = sqrt(variance_val)
	
	# Throughput (Ops / Sec)
	var ops_per_sec = 0.0
	if mean_val > 0.0:
		ops_per_sec = 1_000_000.0 / mean_val
	elif total_time_usec > 0:
		ops_per_sec = (float(total_ops) * 1_000_000.0) / float(total_time_usec)
		
	return {
		"min_usec": min_val,
		"max_usec": max_val,
		"mean_usec": mean_val,
		"median_usec": median_val,
		"p90_usec": p90_val,
		"p95_usec": p95_val,
		"p99_usec": p99_val,
		"stddev_usec": stddev_val,
		"variance_usec": variance_val,
		"ops_per_sec": ops_per_sec
	}

# --- Table Formatting ---

## Formats single or multiple benchmark results into an aligned ASCII performance table.
static func format_table(results_or_single: Variant) -> String:
	var list: Array[Dictionary] = []
	if results_or_single is Dictionary:
		list.append(results_or_single)
	elif results_or_single is Array:
		for item in results_or_single:
			if item is Dictionary:
				list.append(item)
				
	if list.is_empty():
		return "No benchmark data."

	var col_widths = {
		"name": 20, "iter": 10, "mean": 12, "median": 12, "min": 10,
		"max": 12, "p95": 12, "p99": 12, "stddev": 12, "ops": 14, "mem": 10
	}
	
	for res in list:
		col_widths["name"] = maxi(col_widths["name"], str(res.get("name", "")).length())
		
	var sep_line = "+" + "-".repeat(col_widths["name"] + 2) + \
		"+" + "-".repeat(col_widths["iter"] + 2) + \
		"+" + "-".repeat(col_widths["mean"] + 2) + \
		"+" + "-".repeat(col_widths["median"] + 2) + \
		"+" + "-".repeat(col_widths["min"] + 2) + \
		"+" + "-".repeat(col_widths["max"] + 2) + \
		"+" + "-".repeat(col_widths["p95"] + 2) + \
		"+" + "-".repeat(col_widths["p99"] + 2) + \
		"+" + "-".repeat(col_widths["stddev"] + 2) + \
		"+" + "-".repeat(col_widths["ops"] + 2) + \
		"+" + "-".repeat(col_widths["mem"] + 2) + "+"
		
	var header_line = "| %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s | %-*s |" % [
		col_widths["name"], "Benchmark",
		col_widths["iter"], "Iters",
		col_widths["mean"], "Mean",
		col_widths["median"], "Median",
		col_widths["min"], "Min",
		col_widths["max"], "Max",
		col_widths["p95"], "P95",
		col_widths["p99"], "P99",
		col_widths["stddev"], "StdDev",
		col_widths["ops"], "Ops / Sec",
		col_widths["mem"], "Mem Δ"
	]
	
	var lines: Array[String] = []
	lines.append(sep_line)
	lines.append(header_line)
	lines.append(sep_line)
	
	for res in list:
		var name_str = str(res.get("name", "Benchmark"))
		var iter_str = _format_int(res.get("iterations", 0))
		var mean_str = format_time(res.get("mean_usec", 0.0))
		var median_str = format_time(res.get("median_usec", 0.0))
		var min_str = format_time(res.get("min_usec", 0.0))
		var max_str = format_time(res.get("max_usec", 0.0))
		var p95_str = format_time(res.get("p95_usec", 0.0))
		var p99_str = format_time(res.get("p99_usec", 0.0))
		var stddev_str = format_time(res.get("stddev_usec", 0.0))
		var ops_str = format_ops(res.get("ops_per_sec", 0.0))
		var mem_str = format_memory(res.get("memory_bytes_delta", 0))
		
		var row = "| %-*s | %*s | %*s | %*s | %*s | %*s | %*s | %*s | %*s | %*s | %*s |" % [
			col_widths["name"], name_str,
			col_widths["iter"], iter_str,
			col_widths["mean"], mean_str,
			col_widths["median"], median_str,
			col_widths["min"], min_str,
			col_widths["max"], max_str,
			col_widths["p95"], p95_str,
			col_widths["p99"], p99_str,
			col_widths["stddev"], stddev_str,
			col_widths["ops"], ops_str,
			col_widths["mem"], mem_str
		]
		lines.append(row)
		
	lines.append(sep_line)
	return "\n".join(lines)

## Formats benchmark results into a GitHub Flavored Markdown table.
static func format_markdown_table(results_or_single: Variant) -> String:
	var list: Array[Dictionary] = []
	if results_or_single is Dictionary:
		list.append(results_or_single)
	elif results_or_single is Array:
		for item in results_or_single:
			if item is Dictionary:
				list.append(item)
				
	if list.is_empty():
		return "*No benchmark data.*"
		
	var lines: Array[String] = []
	lines.append("| Benchmark | Iters | Mean | Median | Min | Max | P95 | P99 | StdDev | Ops / Sec | Mem Δ |")
	lines.append("| :--- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
	
	for res in list:
		lines.append("| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |" % [
			res.get("name", "Benchmark"),
			_format_int(res.get("iterations", 0)),
			format_time(res.get("mean_usec", 0.0)),
			format_time(res.get("median_usec", 0.0)),
			format_time(res.get("min_usec", 0.0)),
			format_time(res.get("max_usec", 0.0)),
			format_time(res.get("p95_usec", 0.0)),
			format_time(res.get("p99_usec", 0.0)),
			format_time(res.get("stddev_usec", 0.0)),
			format_ops(res.get("ops_per_sec", 0.0)),
			format_memory(res.get("memory_bytes_delta", 0))
		])
		
	return "\n".join(lines)

# --- Unit Formats ---

static func format_time(usec: float) -> String:
	if usec < 0.001:
		return "%.2f ps" % (usec * 1_000_000.0)
	elif usec < 1.0:
		return "%.2f ns" % (usec * 1000.0)
	elif usec < 1000.0:
		return "%.2f μs" % usec
	elif usec < 1_000_000.0:
		return "%.2f ms" % (usec / 1000.0)
	else:
		return "%.2f s" % (usec / 1_000_000.0)

static func format_ops(ops: float) -> String:
	if ops < 1000.0:
		return "%.1f ops/s" % ops
	elif ops < 1_000_000.0:
		return "%.2fK ops/s" % (ops / 1000.0)
	elif ops < 1_000_000_000.0:
		return "%.2fM ops/s" % (ops / 1_000_000.0)
	else:
		return "%.2fG ops/s" % (ops / 1_000_000_000.0)

static func format_memory(bytes_val: int) -> String:
	if abs(bytes_val) < 1024:
		return "%+d B" % bytes_val
	elif abs(bytes_val) < 1024 * 1024:
		return "%+.1f KB" % (float(bytes_val) / 1024.0)
	else:
		return "%+.2f MB" % (float(bytes_val) / (1024.0 * 1024.0))

static func _format_int(val: int) -> String:
	var s = str(val)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return res

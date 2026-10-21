extends Node3D
## Anexar numa cena real de benchmark; coletar amostras em gameplay e preencher relatório depois.
## Sem medições simuladas e sem alegar FPS da Godot headless como FPS no PC-alvo.
var frame_ms: Array[float] = []
var peak_nodes: int = 0
const SAMPLES: int = 600
func _process(delta: float) -> void:
	frame_ms.append(delta * 1000.0)
	peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	if frame_ms.size() == SAMPLES:
		frame_ms.sort()
		var p95: float = frame_ms[int(SAMPLES * .95) - 1]
		var p99: float = frame_ms[int(SAMPLES * .99) - 1]
		var total_ms: float = 0.0
		for ms in frame_ms: total_ms += ms
		print("EXO_MONUMENTAL_BENCH: ", JSON.stringify({"p95_ms":p95,"p99_ms":p99,"max_nodes":peak_nodes,"average_fps_observed":float(SAMPLES)*1000.0 / total_ms}))
		set_process(false)

extends Node
## Lightweight procedural SFX (no external audio dependency).
## Autoloaded as Sfx.

var _players: Array[AudioStreamPlayer] = []
var _idx: int = 0


func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = &"Master"
		p.volume_db = -8.0
		add_child(p)
		_players.append(p)


func _play_tone(freq: float, duration: float, vol: float = -10.0, wave: String = "sin") -> void:
	if _players.is_empty():
		return
	var sample_rate := 22050
	var frames := maxi(1, int(float(sample_rate) * duration))
	# Little-endian signed 16-bit mono PCM (AudioStreamWAV.FORMAT_16_BITS)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(sample_rate)
		var env := pow(1.0 - float(i) / float(frames), 1.6)
		var s := 0.0
		match wave:
			"square":
				s = 0.4 if fmod(freq * t, 1.0) < 0.5 else -0.4
			"noise":
				s = randf_range(-0.5, 0.5)
			_:
				s = sin(TAU * freq * t) * 0.5
		var sample := int(clampf(s * env, -1.0, 1.0) * 32767.0)
		# Two's complement little-endian for negative samples
		if sample < 0:
			sample += 65536
		bytes[i * 2] = sample & 0xFF
		bytes[i * 2 + 1] = (sample >> 8) & 0xFF

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes

	var p: AudioStreamPlayer = _players[_idx]
	_idx = (_idx + 1) % _players.size()
	p.stream = wav
	p.volume_db = vol
	p.play()


func gather() -> void:
	_play_tone(660.0, 0.08, -14.0)


func build() -> void:
	_play_tone(220.0, 0.12, -12.0, "square")
	_play_tone(330.0, 0.1, -16.0)


func attack() -> void:
	_play_tone(180.0, 0.06, -12.0, "noise")


func hit() -> void:
	_play_tone(140.0, 0.07, -10.0, "square")


func crystal_hurt() -> void:
	_play_tone(90.0, 0.2, -8.0, "square")
	_play_tone(60.0, 0.25, -10.0)


func wave_start() -> void:
	_play_tone(392.0, 0.15, -12.0)
	_play_tone(523.0, 0.18, -14.0)


func win() -> void:
	_play_tone(523.0, 0.12, -10.0)
	_play_tone(659.0, 0.14, -10.0)
	_play_tone(784.0, 0.22, -10.0)


func lose() -> void:
	_play_tone(200.0, 0.2, -8.0, "square")
	_play_tone(120.0, 0.35, -8.0)

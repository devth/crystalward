extends Node
## Background music manager — loops ethereal ambient tracks when present,
## else a soft procedural Dark Crystal–style bed (drones + shimmer).
## Autoloaded as Music.

enum Track { TITLE, MAP_SELECT, BATTLE, VICTORY, SILENCE }

var _player: AudioStreamPlayer
var _current: Track = Track.SILENCE
var _use_proc: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	_player.volume_db = -14.0
	add_child(_player)


func play(track: Track) -> void:
	if track == _current and (_player.playing or _use_proc):
		return
	_current = track
	_use_proc = false
	_player.stop()
	var path := _path_for(track)
	if path != "" and (FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))):
		var stream: AudioStream = load(path) as AudioStream
		if stream:
			if stream is AudioStreamOggVorbis:
				(stream as AudioStreamOggVorbis).loop = true
			elif stream is AudioStreamMP3:
				(stream as AudioStreamMP3).loop = true
			elif stream is AudioStreamWAV:
				(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
			_player.stream = stream
			_player.volume_db = -13.0
			_player.play()
			return
	# Procedural ethereal ambient bed
	_use_proc = true
	_start_proc_bed(track)


func stop() -> void:
	_current = Track.SILENCE
	_use_proc = false
	_player.stop()


func _path_for(track: Track) -> String:
	match track:
		Track.TITLE:
			return "res://assets/third_party/music/title.ogg"
		Track.MAP_SELECT:
			return "res://assets/third_party/music/map_select.ogg"
		Track.BATTLE:
			return "res://assets/third_party/music/battle.ogg"
		Track.VICTORY:
			return "res://assets/third_party/music/victory.ogg"
		_:
			return ""


func _start_proc_bed(track: Track) -> void:
	# Mysterious / magical intervals (not bright major triads).
	# Ratios lean phrygian / minor with open fifths and crystalline overtones.
	var root := 55.0
	var intervals: Array = [1.0, 1.5, 2.0, 2.4, 3.0]
	var vol := -20.0
	var duration := 6.0
	match track:
		Track.TITLE:
			root = 55.0  # A1
			intervals = [1.0, 1.5, 2.0, 2.4, 3.0, 4.0]
			vol = -19.0
			duration = 8.0
		Track.MAP_SELECT:
			root = 65.4  # C2
			intervals = [1.0, 1.333, 1.5, 2.0, 2.667, 3.0]
			vol = -20.0
			duration = 7.0
		Track.BATTLE:
			root = 49.0  # G1 — lower, ominous
			intervals = [1.0, 1.2, 1.5, 1.8, 2.0, 2.5, 3.0]
			vol = -18.0
			duration = 7.5
		Track.VICTORY:
			root = 73.4  # D2
			intervals = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0, 4.0]
			vol = -19.0
			duration = 6.5
		_:
			return
	_play_proc_pad(root, intervals, duration, vol, track == Track.BATTLE)


func _play_proc_pad(root: float, intervals: Array, duration: float, vol: float, tense: bool) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var n_int := intervals.size()
	for i in frames:
		var t := float(i) / float(sample_rate)
		# Long soft attack / release for seamless-ish loop feel
		var edge := float(i) / float(maxi(1, frames - 1))
		var env := 1.0
		if edge < 0.12:
			env = edge / 0.12
		elif edge > 0.85:
			env = (1.0 - edge) / 0.15
		env = clampf(env, 0.0, 1.0)
		# Slow breath LFO
		var breath := 0.82 + 0.18 * sin(TAU * 0.07 * t)
		var s := 0.0
		for k in n_int:
			var mult: float = float(intervals[k])
			var amp := 0.10 * pow(0.82, float(k))
			# slight detune + slow phase drift for chorus thickness
			var det := sin(TAU * (0.04 + 0.01 * float(k)) * t + float(k)) * 0.35
			var f := root * mult + det
			s += sin(TAU * f * t) * amp
			# soft 3rd harmonic for hollow / pipe quality
			if k < 3:
				s += sin(TAU * f * 3.0 * t) * amp * 0.08
		# sub drone
		var sub := sin(TAU * root * 0.5 * t) * 0.07
		if tense:
			var beat := 0.5 + 0.5 * sin(TAU * (root / 32.0) * t)
			sub *= 1.0 + 0.35 * beat
			s += sin(TAU * root * 1.5 * t) * 0.025 * beat
		s += sub
		# airy noise shimmer (magical mist)
		s += randf_range(-1.0, 1.0) * 0.012 * (0.5 + 0.5 * sin(TAU * 0.11 * t))
		# occasional crystalline ping (pseudo-bell via envelope window)
		var ping_phase := fmod(t * 0.23, 1.0)
		if ping_phase < 0.08:
			var pe := exp(-ping_phase * 40.0) * (1.0 - exp(-ping_phase * 80.0))
			s += sin(TAU * root * 6.0 * t) * 0.04 * pe
			s += sin(TAU * root * 8.0 * t) * 0.015 * pe
		s *= env * breath
		var v := int(clampf(s, -1.0, 1.0) * 28000.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = frames
	wav.data = bytes
	_player.stream = wav
	_player.volume_db = vol
	_player.play()


func _process(_delta: float) -> void:
	if _use_proc and not _player.playing and _current != Track.SILENCE:
		_start_proc_bed(_current)

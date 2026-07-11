extends Node
## Background music manager — loops CC0 tracks when present, else soft procedural bed.
## Autoloaded as Music.

enum Track { TITLE, MAP_SELECT, BATTLE, VICTORY, SILENCE }

var _player: AudioStreamPlayer
var _current: Track = Track.SILENCE
var _proc_timer: float = 0.0
var _use_proc: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	_player.volume_db = -12.0
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
			_player.volume_db = -11.0
			_player.play()
			return
	# Procedural ambient bed
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
	# Layered soft tones as fallback ambience
	var base_freq := 110.0
	match track:
		Track.TITLE:
			base_freq = 98.0
		Track.MAP_SELECT:
			base_freq = 130.0
		Track.BATTLE:
			base_freq = 146.0
		Track.VICTORY:
			base_freq = 196.0
		_:
			return
	_play_proc_chord(base_freq, 4.0, -18.0)


func _play_proc_chord(root: float, duration: float, vol: float) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var thirds := [1.0, 5.0 / 4.0, 3.0 / 2.0, 2.0]
	for i in frames:
		var t := float(i) / float(sample_rate)
		var env := sin(PI * float(i) / float(maxi(1, frames - 1)))
		env = clampf(env, 0.0, 1.0)
		var s := 0.0
		for m in thirds:
			s += sin(TAU * root * m * t) * 0.12
		# Soft noise shimmer
		s += randf_range(-0.02, 0.02) * env
		s *= env
		var v := int(clampf(s, -1.0, 1.0) * 30000.0)
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

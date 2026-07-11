extends Node
## Background music — dark fantasy synthwave loops (pads, bass pump, arps).
## Autoloaded as Music. Falls back to a procedural synthwave bed if Ogg missing.

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
	# Dark fantasy synthwave fallback — phrygian/dorian, bass pump, arps
	var root := 55.0
	var intervals: Array = [1.0, 1.5, 2.0, 2.4, 3.0]
	var vol := -20.0
	var duration := 7.0
	var tense := false
	var arp_bright := false
	var bpm := 90.0
	match track:
		Track.TITLE:
			root = 55.0
			intervals = [1.0, 1.189, 1.5, 2.0, 2.378, 3.0, 4.0]
			vol = -19.0
			duration = 8.5
			bpm = 86.0
		Track.MAP_SELECT:
			root = 65.4
			intervals = [1.0, 1.333, 1.5, 1.8, 2.0, 2.667, 3.0]
			vol = -20.0
			duration = 7.5
			arp_bright = true
			bpm = 92.0
		Track.BATTLE:
			root = 49.0
			intervals = [1.0, 1.189, 1.5, 1.782, 2.0, 2.5, 3.0]
			vol = -17.0
			duration = 8.0
			tense = true
			bpm = 98.0
		Track.VICTORY:
			root = 73.4
			intervals = [1.0, 1.25, 1.5, 1.778, 2.0, 2.5, 3.0, 4.0]
			vol = -19.0
			duration = 7.0
			arp_bright = true
			bpm = 100.0
		_:
			return
	_play_proc_pad(root, intervals, duration, vol, tense, arp_bright, bpm)


func _play_proc_pad(root: float, intervals: Array, duration: float, vol: float, tense: bool, arp_bright: bool, bpm: float = 90.0) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var n_int := intervals.size()
	var beat := 60.0 / maxf(60.0, bpm)
	var arp_steps: Array = [0, 2, 4, 2, 0, 4, 5, 4]
	var arp_hz_step := beat / 4.0 if tense else beat / 2.5
	var bass_steps: Array = [0, 0, 2, 0, 1, 0, 4, 0]
	var bass_step := beat * 0.5
	for i in frames:
		var t := float(i) / float(sample_rate)
		var edge := float(i) / float(maxi(1, frames - 1))
		var env := 1.0
		if edge < 0.08:
			env = edge / 0.08
		elif edge > 0.88:
			env = (1.0 - edge) / 0.12
		env = clampf(env, 0.0, 1.0)
		# Soft sidechain pump (gentle)
		var beat_ph := fmod(t / beat, 1.0)
		var pump := 0.78 + 0.22 * (1.0 - exp(-beat_ph * 6.0)) * exp(-beat_ph * 2.2)
		var bright := 0.34 + 0.16 * (0.5 + 0.5 * sin(TAU * 0.018 * t))
		if tense:
			bright = 0.40 + 0.14 * (0.5 + 0.5 * sin(TAU * 0.025 * t))
		var s := 0.0
		# Clean pad — mild detune only, no pitch flutter
		for k in n_int:
			var mult: float = float(intervals[k])
			var amp := 0.07 * pow(0.88, float(k))
			var f0 := root * mult
			var det := 0.12 + 0.04 * float(k)  # cents-scale, not warbly
			var harm := 2 + int(3.5 * bright)
			var tone := 0.0
			for h in harm:
				var hk := h + 1
				var ha := (1.0 / float(hk)) * pow(bright, float(hk) * 0.45)
				tone += sin(TAU * f0 * float(hk) * t) * ha
				tone += sin(TAU * (f0 + det) * float(hk) * t) * ha * 0.8
			s += tone * amp * 0.34
		# Soft bass
		var bi := int(t / bass_step) % bass_steps.size()
		var bidx: int = mini(int(bass_steps[bi]), n_int - 1)
		var bf := root * float(intervals[bidx])
		var blocal := t - float(int(t / bass_step)) * bass_step
		var benv := 1.0
		if blocal < 0.015:
			benv = blocal / 0.015
		elif blocal > bass_step * 0.8:
			benv = maxf(0.0, 1.0 - (blocal - bass_step * 0.8) / (bass_step * 0.2))
		var bass := sin(TAU * bf * t) * 0.13 + sin(TAU * bf * 0.5 * t) * 0.09
		s += bass * benv * pump
		# Soft arpeggio (triangle-ish pluck)
		var step_i := int(t / arp_hz_step)
		var step_t := t - float(step_i) * arp_hz_step
		if step_t < arp_hz_step * 0.9:
			var idx: int = int(arp_steps[step_i % arp_steps.size()])
			idx = mini(idx, n_int - 1)
			var amult: float = float(intervals[idx])
			var af := root * amult * (2.0 if arp_bright else 1.0)
			var ae := exp(-step_t * 4.5) * (1.0 - exp(-step_t * 40.0))
			var pluck := sin(TAU * af * t) * 0.55 + sin(TAU * af * 3.0 * t) * 0.08
			s += pluck * ae * 0.11
		# Soft lead (no vibrato)
		var motif_phase := fmod(t * 0.14, 1.0)
		if motif_phase < 0.26:
			var me := sin(PI * motif_phase / 0.26) * exp(-motif_phase * 1.2)
			var mf := root * 2.0
			s += (sin(TAU * mf * t) * 0.6 + sin(TAU * mf * 3.0 * t) * 0.06) * me * 0.09
		# Pure sine sparkle (no FM)
		var ping := fmod(t * 0.16, 1.0)
		if ping < 0.1:
			var pe := exp(-ping * 8.0) * (1.0 - exp(-ping * 30.0))
			s += sin(TAU * root * 4.0 * t) * pe * 0.035
		s *= env * (0.7 + 0.3 * pump)
		var v := int(clampf(s, -1.0, 1.0) * 27000.0)
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

extends Node
## Background music — ethereal Dark Crystal + mid-80s synth ambient loops.
## Autoloaded as Music. Falls back to a soft procedural pad if Ogg missing.

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
	# 80s-fantasy scales: phrygian / dorian / mixolydian-ish interval sets
	var root := 55.0
	var intervals: Array = [1.0, 1.5, 2.0, 2.4, 3.0]
	var vol := -20.0
	var duration := 7.0
	var tense := false
	var arp_bright := false
	match track:
		Track.TITLE:
			root = 55.0
			intervals = [1.0, 1.189, 1.5, 2.0, 2.378, 3.0, 4.0]  # phrygian color
			vol = -19.0
			duration = 8.5
		Track.MAP_SELECT:
			root = 65.4
			intervals = [1.0, 1.333, 1.5, 1.8, 2.0, 2.667, 3.0]  # dorian-ish
			vol = -20.0
			duration = 7.5
			arp_bright = true
		Track.BATTLE:
			root = 49.0
			intervals = [1.0, 1.189, 1.5, 1.782, 2.0, 2.5, 3.0]
			vol = -18.0
			duration = 8.0
			tense = true
		Track.VICTORY:
			root = 73.4
			intervals = [1.0, 1.25, 1.5, 1.778, 2.0, 2.5, 3.0, 4.0]
			vol = -19.0
			duration = 7.0
			arp_bright = true
		_:
			return
	_play_proc_pad(root, intervals, duration, vol, tense, arp_bright)


func _play_proc_pad(root: float, intervals: Array, duration: float, vol: float, tense: bool, arp_bright: bool) -> void:
	var sample_rate := 22050
	var frames := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var n_int := intervals.size()
	# Classic slow 80s arp pattern (scale steps as interval indices)
	var arp_steps: Array = [0, 2, 4, 2, 0, 4, 5, 4]
	var arp_hz_step := 0.62
	for i in frames:
		var t := float(i) / float(sample_rate)
		var edge := float(i) / float(maxi(1, frames - 1))
		var env := 1.0
		if edge < 0.12:
			env = edge / 0.12
		elif edge > 0.85:
			env = (1.0 - edge) / 0.15
		env = clampf(env, 0.0, 1.0)
		# Tape-ish wow + breath
		var flutter := 1.0 + 0.002 * sin(TAU * 0.32 * t)
		var breath := 0.80 + 0.20 * sin(TAU * 0.065 * t)
		var bright := 0.35 + 0.30 * (0.5 + 0.5 * sin(TAU * 0.02 * t))
		if tense:
			bright = 0.42 + 0.28 * (0.5 + 0.5 * sin(TAU * 0.035 * t))
		var s := 0.0
		# Detuned pad (Juno-ish): each partial doubled with slight offset
		for k in n_int:
			var mult: float = float(intervals[k])
			var amp := 0.085 * pow(0.84, float(k))
			var f0 := root * mult * flutter
			var det := 0.35 + 0.08 * float(k)
			# soft saw partials (rolled off by bright)
			var harm := 2 + int(4.0 * bright)
			var tone := 0.0
			for h in harm:
				var hk := h + 1
				var ha := (1.0 / float(hk)) * pow(bright, float(hk) * 0.4)
				tone += sin(TAU * f0 * float(hk) * t) * ha
				tone += sin(TAU * (f0 + det) * float(hk) * t) * ha * 0.85
			s += tone * amp * 0.38
		# Sub
		var sub := sin(TAU * root * 0.5 * flutter * t) * 0.07
		if tense:
			var beat := 0.5 + 0.5 * sin(TAU * (root / 28.0) * t)
			var gate := 0.7 + 0.3 * pow(maxf(0.0, sin(TAU * 1.7 * t)), 4.0)
			sub *= (1.0 + 0.4 * beat) * (0.85 + 0.15 * gate)
		s += sub
		# String-machine fifth
		s += sin(TAU * root * 2.0 * flutter * t) * 0.04
		s += sin(TAU * root * 3.0 * flutter * t) * 0.025
		# Soft 80s arpeggio plucks
		var step_i := int(t / arp_hz_step)
		var step_t := t - float(step_i) * arp_hz_step
		if step_t < 0.55:
			var idx: int = int(arp_steps[step_i % arp_steps.size()])
			idx = mini(idx, n_int - 1)
			var amult: float = float(intervals[idx])
			var af := root * amult * (2.0 if arp_bright else 1.0) * flutter
			var ae := exp(-step_t * 3.5) * (1.0 - exp(-step_t * 40.0))
			# hollow pulse-ish
			var pluck := sin(TAU * af * t) * 0.55 + sin(TAU * af * 2.0 * t) * 0.18
			s += pluck * ae * 0.11
		# Haunting lead motif blip every ~5s
		var motif_phase := fmod(t * 0.19, 1.0)
		if motif_phase < 0.22:
			var me := sin(PI * motif_phase / 0.22) * exp(-motif_phase * 2.0)
			var mf := root * 2.0 * flutter * (1.0 + 0.004 * sin(TAU * 5.0 * t))
			s += (sin(TAU * mf * t) * 0.6 + sin(TAU * mf * 3.0 * t) * 0.08) * me * 0.12
		# FM crystal ping
		var ping := fmod(t * 0.17, 1.0)
		if ping < 0.09:
			var pe := exp(-ping * 35.0) * (1.0 - exp(-ping * 70.0))
			var pf := root * 6.0
			var fm := 2.0 * exp(-ping * 3.0) * sin(TAU * pf * 3.0 * t)
			s += sin(TAU * pf * t + fm) * pe * 0.06
		# Mist / tape hiss
		s += randf_range(-1.0, 1.0) * 0.011 * (0.5 + 0.5 * sin(TAU * 0.1 * t))
		s *= env * breath
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

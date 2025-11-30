extends Node
class_name SoundGenerator
## SoundGenerator - Génère des sons simples synthétisés

static func create_boing_sound() -> AudioStreamWAV:
	## Crée un son "boing" pour le saut
	var sample_rate = 22050
	var duration = 0.15
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		# Fréquence qui monte (effet boing)
		var freq = 200 + (t * 800)
		var amplitude = 1.0 - (t / duration)  # Fade out
		var sample = sin(t * freq * TAU) * amplitude
		# Convertir en 8-bit unsigned (0-255)
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

static func create_shoot_sound() -> AudioStreamWAV:
	## Crée un son "piouuxx" pour le tir
	var sample_rate = 22050
	var duration = 0.2
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		# Fréquence qui descend (effet laser/pew)
		var freq = 1200 - (t * 4000)
		freq = max(freq, 100)
		var amplitude = 1.0 - (t / duration)  # Fade out
		# Mix de sine et noise pour texture
		var sample = sin(t * freq * TAU) * amplitude * 0.7
		sample += (randf() - 0.5) * amplitude * 0.3  # Bruit
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

static func create_hit_sound() -> AudioStreamWAV:
	## Crée un son d'impact
	var sample_rate = 22050
	var duration = 0.1
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var amplitude = 1.0 - (t / duration)
		# Bruit avec envelope rapide
		var sample = (randf() - 0.5) * amplitude
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

static func create_coin_sound() -> AudioStreamWAV:
	## Crée un son de pièce/récompense
	var sample_rate = 22050
	var duration = 0.15
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var amplitude = 1.0 - (t / duration)
		# Deux notes rapides (ding ding)
		var freq1 = 880.0  # La
		var freq2 = 1320.0  # Mi (quinte)
		var mix = 0.5 if t < 0.07 else 1.0
		var sample = sin(t * freq1 * TAU) * (1.0 - mix) + sin(t * freq2 * TAU) * mix
		sample *= amplitude
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

static func create_hurt_sound() -> AudioStreamWAV:
	## Crée un son de dégât reçu
	var sample_rate = 22050
	var duration = 0.25
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var amplitude = 1.0 - (t / duration)
		# Fréquence basse qui descend
		var freq = 150 - (t * 100)
		var sample = sin(t * freq * TAU) * amplitude
		sample += (randf() - 0.5) * amplitude * 0.4
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

static func create_death_sound() -> AudioStreamWAV:
	## Crée un son de mort
	var sample_rate = 22050
	var duration = 0.5
	var samples = int(sample_rate * duration)

	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data = PackedByteArray()
	data.resize(samples)

	for i in range(samples):
		var t = float(i) / sample_rate
		var amplitude = 1.0 - (t / duration)
		# Descente chromatique triste
		var freq = 400 - (t * 300)
		var sample = sin(t * freq * TAU) * amplitude * 0.6
		sample += sin(t * freq * 0.5 * TAU) * amplitude * 0.4
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	return audio

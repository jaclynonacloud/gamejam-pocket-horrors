extends Control

func _ready():
	var s = self
	if s is Label:
		s.text = Globals.translate(s.text)
	elif s is RichTextLabel:
		if s.bbcode_enabled:
			s.bbcode_text = Globals.translate(s.text)
		else:
			s.text = Globals.translate(s.text)

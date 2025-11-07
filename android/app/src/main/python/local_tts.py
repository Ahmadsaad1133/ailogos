from gtts import gTTS


def generate_tts(text, path):
    """
    Generate an MP3 file at `path` from the given `text`.
    Runs on Android via Chaquopy.
    """
    if not text:
        text = " "  # avoid errors on empty text

    # Default language: English. Change 'en' if you want another language.
    tts = gTTS(text=text, lang="en")

    # gTTS always writes MP3 data, so make sure `path` ends with .mp3
    tts.save(path)

    # Just return the path back to Kotlin/Flutter
    return path

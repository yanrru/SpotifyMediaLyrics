TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := SpotifyMediaLyrics
SpotifyMediaLyrics_FILES := Tweak.xm
SpotifyMediaLyrics_CFLAGS := -fobjc-arc
SpotifyMediaLyrics_FRAMEWORKS := Foundation MediaPlayer
SpotifyMediaLyrics_PRIVATE_FRAMEWORKS := MediaPlayer

include $(THEOS_MAKE_PATH)/tweak.mk

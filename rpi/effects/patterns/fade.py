from typing import List
from ..interface import DynamicLightConfig
from ..opcutil import ColorHex, ColorData, get_color, shift


class Fade(DynamicLightConfig):
    """
    Fade between specified colors.
    """
    speed: int = 5
    color_list: List[ColorData]  # colors to fade between
    pixels: List[ColorData]  # current list of pixels

    _current_color: ColorData
    _color_index = 0  # index of color being faded towards in self.colors
    _fade_index = 0  # how far we are between two colors [0-9]

    def __init__(self, color_list: List[ColorHex], **kwargs):
        """
        Initialize a new Fade configuration.
        :param color_list: the colors to use ("#RRGGBB" format)
        """
        super().__init__(**kwargs)
        self.validate_color_list(color_list)

        self.color_list = [get_color(c) for c in color_list]
        self._current_color = self.color_list[0]
        self.pixels = [self._current_color] * self.num_leds

    def __next__(self) -> List[ColorData]:
        if self._fade_index == 9:
            # go to next color
            self._color_index = (self._color_index + 1) % len(self.color_list)

        # increment _fade_index, or wrap back to 0
        self._fade_index = (self._fade_index + 1) % 10

        # shift pixels 10% towards the next color
        self._current_color = shift(self._current_color,
                                    self.color_list[self._color_index], 0.1)
        self.pixels = [self._current_color] * self.num_leds

        return self.pixels

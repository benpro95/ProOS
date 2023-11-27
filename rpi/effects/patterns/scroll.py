from typing import List
from ..interface import DynamicLightConfig
from ..opcutil import ColorData, get_color, spread, even_spread, rotate_right


class Scroll(DynamicLightConfig):
    """
    Scroll through a multi-colored line.
    """
    speed: int = 8
    color_list: List[ColorData]  # colors to scroll
    width: int  # (optional) number of pixels per color
    pixels: List[ColorData]  # current list of pixels

    def __init__(self, color_list: List[str], width: int = None, **kwargs):
        """
        Initialize a new Scroll configuration.

        :param color_list: the colors to use ("#RRGGBB" format)
        :param width:
        """
        super().__init__(**kwargs)
        self.validate_color_list(color_list)

        self.color_list = [get_color(c) for c in color_list]
        self.width = width

        if width:
            self.pixels = spread(self.color_list, width, self.num_leds)
        else:
            self.pixels = even_spread(self.color_list, self.num_leds)

    def __next__(self) -> List[ColorData]:
        self.pixels = rotate_right(self.pixels, 1)
        return self.pixels

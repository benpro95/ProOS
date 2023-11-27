from typing import List
from ..opcutil import ColorHex, ColorData, get_color, spread, even_spread
from ..interface import StaticLightConfig


class Stripes(StaticLightConfig):
    """
    Display multiple static colors.
    """
    color_list: List[ColorData]  # colors to display
    width: int  # (optional) number of pixels per color

    def __init__(self, color_list: List[ColorHex], width: int = None, **kwargs):
        """
        Initialize a new Stripes configuration.
        :param color_list: the colors to use ("#RRGGBB" format)
        :param width: the width of each color strip
        """
        super().__init__(**kwargs)
        self.validate_color_list(color_list)

        self.color_list = [get_color(c) for c in color_list]
        self.width = width

    def pattern(self) -> List[ColorData]:
        if self.width:
            return spread(self.color_list, self.width, self.num_leds)
        else:
            return even_spread(self.color_list, self.num_leds)
